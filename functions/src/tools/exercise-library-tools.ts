import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { AuthContext } from '../auth.js';

function textResult(data: unknown, isError = false) {
  return {
    content: [{ type: 'text' as const, text: JSON.stringify(data) }],
    ...(isError && { isError: true }),
  };
}

export function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

export const exerciseLibraryToolDefinitions: Tool[] = [
  {
    name: 'search_exercise_library',
    description: 'Searches the global exercise library by name/alias substring and tags',
    inputSchema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Search string matched case-insensitively against exercise name and aliases',
        },
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'Filter by tags (e.g. "legs", "barbell", "compound"). An exercise must match all specified tags.',
        },
        limit: {
          type: 'number',
          description: 'Maximum number of results to return (default 20, max 100)',
        },
      },
    },
  },
  {
    name: 'get_library_exercise',
    description: 'Retrieves a single exercise definition from the global exercise library by ID',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseId: {
          type: 'string',
          description: 'Document ID / slug of the exercise (e.g. "barbell-back-squat")',
        },
      },
      required: ['exerciseId'],
    },
  },
  {
    name: 'add_library_exercise',
    description: 'Adds a new canonical exercise to the global exercise library (admin only)',
    inputSchema: {
      type: 'object',
      properties: {
        id: {
          type: 'string',
          description: 'Optional custom document ID / slug. Defaults to slugified name.',
        },
        name: {
          type: 'string',
          description: 'Display name of the exercise',
        },
        description: {
          type: 'string',
          description: 'Form cues and instructions on how to perform the exercise',
        },
        videoUrl: {
          type: 'string',
          description: 'YouTube or reference video URL',
        },
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'Muscle groups, equipment, movement patterns (e.g. ["legs", "barbell"])',
        },
        aliases: {
          type: 'array',
          items: { type: 'string' },
          description: 'Alternative names for search (e.g. ["squat", "back squat"])',
        },
      },
      required: ['name'],
    },
  },
  {
    name: 'update_library_exercise',
    description: 'Updates an existing canonical exercise in the global exercise library (admin only)',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseId: {
          type: 'string',
          description: 'Document ID of the exercise to update',
        },
        name: {
          type: 'string',
          description: 'New display name (preserves the original document ID)',
        },
        description: {
          type: 'string',
          description: 'Updated form cues and instructions',
        },
        videoUrl: {
          type: 'string',
          description: 'Updated reference video URL',
        },
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'Updated tags list',
        },
        aliases: {
          type: 'array',
          items: { type: 'string' },
          description: 'Updated alternative names list',
        },
      },
      required: ['exerciseId'],
    },
  },
];

const ALLOWED_ADD_FIELDS = new Set(['id', 'name', 'description', 'videoUrl', 'tags', 'aliases']);
const ALLOWED_UPDATE_FIELDS = new Set(['exerciseId', 'name', 'description', 'videoUrl', 'tags', 'aliases']);

export async function handleExerciseLibraryTool(
  name: string,
  args: Record<string, unknown>,
  auth: AuthContext,
  dbInstance?: any
): Promise<{ content: Array<{ type: 'text'; text: string }>; isError?: boolean }> {
  const getDb = () => dbInstance || admin.firestore();

  try {
    switch (name) {
      case 'search_exercise_library': {
        const db = getDb();
        const query = typeof args.query === 'string' ? args.query.trim().toLowerCase() : '';
        const requestedTags = Array.isArray(args.tags)
          ? args.tags.map((t) => String(t).trim().toLowerCase()).filter(Boolean)
          : [];
        const rawLimit = typeof args.limit === 'number' ? args.limit : 20;
        const boundedLimit = Math.max(1, Math.min(rawLimit, 100));

        const snapshot = await db.collection('exerciseLibrary').get();

        const results: Array<Record<string, unknown>> = [];
        for (const doc of snapshot.docs) {
          const data = doc.data();
          const exerciseName = (data.name as string) || '';
          const nameLower = exerciseName.toLowerCase();
          const aliases = Array.isArray(data.aliases)
            ? (data.aliases as string[]).map((a) => String(a).toLowerCase())
            : [];
          const tags = Array.isArray(data.tags)
            ? (data.tags as string[]).map((t) => String(t).toLowerCase())
            : [];

          // Match query against name or aliases
          if (query) {
            const matchesName = nameLower.includes(query);
            const matchesAlias = aliases.some((a) => a.includes(query));
            if (!matchesName && !matchesAlias) {
              continue;
            }
          }

          // Match tags (exercise must contain all requested tags)
          if (requestedTags.length > 0) {
            const hasAllTags = requestedTags.every((t) => tags.includes(t));
            if (!hasAllTags) {
              continue;
            }
          }

          results.push({
            id: doc.id,
            name: exerciseName,
            description: data.description ?? null,
            videoUrl: data.videoUrl ?? null,
            tags: data.tags ?? [],
            aliases: data.aliases ?? [],
          });
        }

        // Deterministic sorting by name
        results.sort((a, b) =>
          String(a.name).localeCompare(String(b.name), undefined, { sensitivity: 'base' })
        );

        const sliced = results.slice(0, boundedLimit);
        return textResult({ count: sliced.length, total: results.length, exercises: sliced });
      }

      case 'get_library_exercise': {
        const exerciseId = args.exerciseId;
        if (!exerciseId || typeof exerciseId !== 'string') {
          return textResult({ error: 'exerciseId is required and must be a string' }, true);
        }

        const db = getDb();
        const doc = await db.collection('exerciseLibrary').doc(exerciseId).get();
        if (!doc.exists) {
          return textResult({ error: 'Exercise not found', exerciseId }, true);
        }

        return textResult({ id: doc.id, ...doc.data() });
      }

      case 'add_library_exercise': {
        if (!auth.isAdmin) {
          return textResult({ error: 'Admin permission required' }, true);
        }

        // Reject unknown fields
        for (const key of Object.keys(args)) {
          if (!ALLOWED_ADD_FIELDS.has(key)) {
            return textResult({ error: `Unknown field: ${key}` }, true);
          }
        }

        const nameValue = args.name;
        if (!nameValue || typeof nameValue !== 'string' || !nameValue.trim()) {
          return textResult({ error: 'name is required and must be a non-empty string' }, true);
        }

        const idCandidate = typeof args.id === 'string' && args.id.trim() ? args.id.trim() : slugify(nameValue);
        if (!idCandidate) {
          return textResult({ error: 'Unable to derive a valid document ID from name' }, true);
        }

        const db = getDb();
        const docRef = db.collection('exerciseLibrary').doc(idCandidate);
        const existingDoc = await docRef.get();
        if (existingDoc.exists) {
          return textResult({ error: 'Exercise already exists', exerciseId: idCandidate }, true);
        }

        const now = FieldValue.serverTimestamp();
        const newExercise = {
          name: nameValue.trim(),
          description: typeof args.description === 'string' ? args.description.trim() : null,
          videoUrl: typeof args.videoUrl === 'string' ? args.videoUrl.trim() : null,
          tags: Array.isArray(args.tags) ? args.tags.map((t) => String(t).trim()).filter(Boolean) : [],
          aliases: Array.isArray(args.aliases) ? args.aliases.map((a) => String(a).trim()).filter(Boolean) : [],
          createdBy: auth.userId,
          createdAt: now,
          updatedAt: now,
        };

        await docRef.set(newExercise);
        return textResult({ success: true, exerciseId: idCandidate, exercise: newExercise });
      }

      case 'update_library_exercise': {
        if (!auth.isAdmin) {
          return textResult({ error: 'Admin permission required' }, true);
        }

        // Reject unknown fields
        for (const key of Object.keys(args)) {
          if (!ALLOWED_UPDATE_FIELDS.has(key)) {
            return textResult({ error: `Unknown field: ${key}` }, true);
          }
        }

        const exerciseId = args.exerciseId;
        if (!exerciseId || typeof exerciseId !== 'string') {
          return textResult({ error: 'exerciseId is required and must be a string' }, true);
        }

        const db = getDb();
        const docRef = db.collection('exerciseLibrary').doc(exerciseId);
        const doc = await docRef.get();
        if (!doc.exists) {
          return textResult({ error: 'Exercise not found', exerciseId }, true);
        }

        const updateData: Record<string, unknown> = {
          updatedAt: FieldValue.serverTimestamp(),
        };

        if ('name' in args) {
          if (typeof args.name !== 'string' || !args.name.trim()) {
            return textResult({ error: 'name must be a non-empty string' }, true);
          }
          updateData.name = args.name.trim();
        }

        if ('description' in args) {
          updateData.description = typeof args.description === 'string' ? args.description.trim() : null;
        }

        if ('videoUrl' in args) {
          updateData.videoUrl = typeof args.videoUrl === 'string' ? args.videoUrl.trim() : null;
        }

        if ('tags' in args) {
          updateData.tags = Array.isArray(args.tags)
            ? args.tags.map((t) => String(t).trim()).filter(Boolean)
            : [];
        }

        if ('aliases' in args) {
          updateData.aliases = Array.isArray(args.aliases)
            ? args.aliases.map((a) => String(a).trim()).filter(Boolean)
            : [];
        }

        await docRef.update(updateData);
        return textResult({ success: true, exerciseId, updated: updateData });
      }

      default:
        return textResult({ error: `Unknown tool: ${name}` }, true);
    }
  } catch (error) {
    return textResult({ error: (error as Error).message }, true);
  }
}
