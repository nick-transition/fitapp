import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { Tool } from '@modelcontextprotocol/sdk/types.js';
import type { AuthContext } from '../auth.js';

function textResult(data: unknown, isError = false) {
  return {
    content: [{ type: 'text' as const, text: JSON.stringify(data) }],
    ...(isError && { isError: true }),
  };
}

// The library is a curated global catalog (hundreds of entries at most), so
// search streams the collection and filters in memory. Ordering is by
// case-insensitive name then document ID, which keeps results deterministic.
const DEFAULT_SEARCH_LIMIT = 25;
const MAX_SEARCH_LIMIT = 100;

// Only these fields exist on a library entry. `createdBy`/`createdAt` are set
// once at creation and never accepted from callers; `updatedAt` is managed.
const MUTABLE_FIELDS = ['name', 'description', 'videoUrl', 'tags', 'aliases'] as const;

function isPlainString(v: unknown): v is string {
  return typeof v === 'string';
}

function isStringArray(v: unknown): v is string[] {
  return Array.isArray(v) && v.every((item) => typeof item === 'string');
}

function normalizeTag(tag: string): string {
  return tag.trim().toLowerCase();
}

function slugifyName(name: string): string {
  return name
    .normalize('NFKD')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function validateEntryFields(
  fields: Record<string, unknown>,
  { partial }: { partial: boolean }
): { ok: true; value: Record<string, unknown> } | { ok: false; error: string } {
  const value: Record<string, unknown> = {};

  for (const key of Object.keys(fields)) {
    if (!MUTABLE_FIELDS.includes(key as (typeof MUTABLE_FIELDS)[number])) {
      return { ok: false, error: `Unknown field: ${key}. Allowed fields: ${MUTABLE_FIELDS.join(', ')}` };
    }
  }

  if (fields.name !== undefined || !partial) {
    if (!isPlainString(fields.name) || !fields.name.trim()) {
      return { ok: false, error: 'name is required and must be a non-empty string' };
    }
    value.name = fields.name.trim();
  }
  if (fields.description !== undefined) {
    if (!isPlainString(fields.description)) return { ok: false, error: 'description must be a string' };
    value.description = fields.description;
  }
  if (fields.videoUrl !== undefined) {
    if (!isPlainString(fields.videoUrl)) return { ok: false, error: 'videoUrl must be a string' };
    value.videoUrl = fields.videoUrl;
  }
  if (fields.tags !== undefined) {
    if (!isStringArray(fields.tags) || fields.tags.some((t) => !t.trim())) {
      return { ok: false, error: 'tags must be an array of non-empty strings' };
    }
    value.tags = fields.tags.map((t) => t.trim());
  }
  if (fields.aliases !== undefined) {
    if (!isStringArray(fields.aliases) || fields.aliases.some((a) => !a.trim())) {
      return { ok: false, error: 'aliases must be an array of non-empty strings' };
    }
    value.aliases = fields.aliases.map((a) => a.trim());
  }

  return { ok: true, value };
}

export const exerciseLibraryToolDefinitions: Tool[] = [
  {
    name: 'search_exercise_library',
    description:
      'Search the shared global exercise library. Case-insensitive substring match on name and aliases, plus optional tag filters (every requested tag must be present on the entry). Results are deterministic (sorted by name) and capped. Always search here before inventing a custom exercise name or video link.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Case-insensitive substring matched against entry names and aliases. Optional.' },
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'Tag filters (muscle group, equipment, movement pattern). Case-insensitive exact tag equality; entries must carry ALL requested tags. Optional.',
        },
        limit: { type: 'number', description: `Maximum results to return (default ${DEFAULT_SEARCH_LIMIT}, max ${MAX_SEARCH_LIMIT}).` },
      },
    },
  },
  {
    name: 'get_library_exercise',
    description: 'Fetch one exercise library entry by its document ID.',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseId: { type: 'string', description: 'Document ID of the library entry (as returned by search).' },
      },
      required: ['exerciseId'],
    },
  },
  {
    name: 'update_library_exercise',
    description:
      'Update an existing exercise library entry (admin only). Partial update: omitted fields are preserved, unknown fields are rejected, and a missing document fails instead of being created. The document ID never changes, so plan references stay stable even when the display name changes.',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseId: { type: 'string', description: 'Document ID of the library entry to update.' },
        name: { type: 'string', description: 'New display name (document ID is NOT renamed).' },
        description: { type: 'string' },
        videoUrl: { type: 'string' },
        tags: { type: 'array', items: { type: 'string' } },
        aliases: { type: 'array', items: { type: 'string' } },
      },
      required: ['exerciseId'],
    },
  },
  {
    name: 'add_library_exercise',
    description:
      'Add a new entry to the exercise library (admin only). The document ID is the given ID or a slug of the name; creating over an existing ID is rejected, never overwritten.',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Display name of the exercise (required).' },
        exerciseId: { type: 'string', description: 'Optional document ID (defaults to a slug of the name, e.g. "barbell-back-squat").' },
        description: { type: 'string', description: 'Form cues / how to perform.' },
        videoUrl: { type: 'string', description: 'YouTube or reference link.' },
        tags: { type: 'array', items: { type: 'string' }, description: 'Muscle group, equipment, movement pattern.' },
        aliases: { type: 'array', items: { type: 'string' }, description: 'Alternative names for search.' },
      },
      required: ['name'],
    },
  },
];

export async function handleExerciseLibraryTool(
  name: string,
  args: Record<string, unknown>,
  auth: AuthContext
): Promise<{ content: Array<{ type: 'text'; text: string }>; isError?: boolean }> {
  const db = admin.firestore();

  try {
    switch (name) {
      case 'search_exercise_library': {
        const query = isPlainString(args.query) ? args.query.trim().toLowerCase() : '';
        const filterTags = isStringArray(args.tags) ? args.tags.map(normalizeTag).filter(Boolean) : [];
        const rawLimit = args.limit;
        const limit =
          typeof rawLimit === 'number' && Number.isInteger(rawLimit) && rawLimit > 0
            ? Math.min(rawLimit, MAX_SEARCH_LIMIT)
            : DEFAULT_SEARCH_LIMIT;

        const snapshot = await db.collection('exerciseLibrary').get();
        const entries: Array<Record<string, unknown> & { id: string }> = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...(doc.data() as Record<string, unknown>),
        }));
        const results = entries
          .filter((entry) => {
            const nameLc = isPlainString(entry.name) ? entry.name.toLowerCase() : '';
            const aliasesLc = isStringArray(entry.aliases) ? entry.aliases.map((a) => a.toLowerCase()) : [];
            const matchesQuery =
              !query || nameLc.includes(query) || aliasesLc.some((a) => a.includes(query));
            if (!matchesQuery) return false;
            const entryTags = isStringArray(entry.tags) ? entry.tags.map(normalizeTag) : [];
            return filterTags.every((tag) => entryTags.includes(tag));
          })
          .sort((a, b) => {
            const an = isPlainString(a.name) ? a.name.toLowerCase() : '';
            const bn = isPlainString(b.name) ? b.name.toLowerCase() : '';
            return an !== bn ? an.localeCompare(bn) : String(a.id).localeCompare(String(b.id));
          })
          .slice(0, limit);

        return textResult({ results, total: results.length });
      }

      case 'get_library_exercise': {
        const exerciseId = args.exerciseId;
        if (!isPlainString(exerciseId) || !exerciseId.trim()) {
          return textResult({ error: 'exerciseId is required' }, true);
        }
        const doc = await db.collection('exerciseLibrary').doc(exerciseId.trim()).get();
        if (!doc.exists) {
          return textResult({ error: `Library exercise not found: ${exerciseId}` }, true);
        }
        return textResult({ id: doc.id, ...doc.data() });
      }

      case 'update_library_exercise': {
        // Admin gate before every write — non-admins must not learn whether
        // the target document exists. isAdmin is resolved at auth time.
        if (auth.isAdmin !== true) {
          return textResult({ error: 'Only admins can update exercise library entries' }, true);
        }
        const exerciseId = args.exerciseId;
        if (!isPlainString(exerciseId) || !exerciseId.trim()) {
          return textResult({ error: 'exerciseId is required' }, true);
        }
        const { exerciseId: _id, ...fields } = args;
        const validation = validateEntryFields(fields, { partial: true });
        if (!validation.ok) return textResult({ error: validation.error }, true);
        if (Object.keys(validation.value).length === 0) {
          return textResult({ error: 'Nothing to update: provide at least one field to change' }, true);
        }

        const ref = db.collection('exerciseLibrary').doc(exerciseId.trim());
        const result = await db.runTransaction(async (tx) => {
          const doc = await tx.get(ref);
          if (!doc.exists) {
            return { error: `Library exercise not found: ${exerciseId}` };
          }
          tx.update(ref, { ...validation.value, updatedAt: FieldValue.serverTimestamp() });
          return { id: doc.id };
        });
        if ('error' in result) return textResult(result, true);
        return textResult({ success: true, exerciseId: result.id, updatedFields: Object.keys(validation.value) });
      }

      case 'add_library_exercise': {
        if (auth.isAdmin !== true) {
          return textResult({ error: 'Only admins can add exercise library entries' }, true);
        }
        const { exerciseId: _requested, ...fields } = args;
        const validation = validateEntryFields(fields, { partial: false });
        if (!validation.ok) return textResult({ error: validation.error }, true);

        const requestedId = isPlainString(args.exerciseId) ? args.exerciseId.trim() : '';
        const docId = requestedId || slugifyName(validation.value.name as string);
        if (!docId) {
          return textResult({ error: 'Could not derive a document ID from the name; pass exerciseId explicitly' }, true);
        }

        const ref = db.collection('exerciseLibrary').doc(docId);
        const result = await db.runTransaction(async (tx) => {
          const doc = await tx.get(ref);
          if (doc.exists) {
            return { error: `Library exercise already exists with ID "${docId}" — update it instead of recreating` };
          }
          tx.set(ref, {
            ...validation.value,
            createdBy: auth.userId,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
          return { id: docId };
        });
        if ('error' in result) return textResult(result, true);
        return textResult({ success: true, exerciseId: result.id });
      }

      default:
        return textResult({ error: `Unknown tool: ${name}` }, true);
    }
  } catch (error) {
    return textResult({ error: (error as Error).message }, true);
  }
}
