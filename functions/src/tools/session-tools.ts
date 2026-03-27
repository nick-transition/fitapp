import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { Tool } from '@modelcontextprotocol/sdk/types.js';

function textResult(data: unknown, isError = false) {
  return {
    content: [{ type: 'text' as const, text: JSON.stringify(data) }],
    ...(isError && { isError: true }),
  };
}

export const sessionToolDefinitions: Tool[] = [
  {
    name: 'log_session',
    description: 'Logs a completed workout session with multiple exercises',
    inputSchema: {
      type: 'object',
      properties: {
        planId: { type: 'string', description: 'ID of the plan this session is based on' },
        planName: { type: 'string', description: 'Name of the plan for quick reference' },
        notes: { type: 'string', description: 'Notes about the session' },
        journalEntry: { type: 'string', description: 'Longer-form journal entry reflecting on the workout (mood, energy, how it felt, etc.)' },
        scheduledAt: { type: 'string', description: 'ISO 8601 date/time if this session was scheduled in advance' },
        entries: {
          type: 'array',
          description: 'Exercises performed with sets',
          items: {
            type: 'object',
            properties: {
              exerciseName: { type: 'string' },
              sets: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    reps: { type: 'number' },
                    weight: { type: 'number' },
                  },
                  required: ['reps'],
                },
              },
              notes: { type: 'string' },
            },
            required: ['exerciseName', 'sets'],
          },
        },
      },
      required: ['entries'],
    },
  },
  {
    name: 'log_quick_exercise',
    description: 'Quickly logs a single exercise as a workout session',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseName: { type: 'string', description: 'Name of the exercise' },
        sets: {
          type: 'array',
          description: 'Sets performed',
          items: {
            type: 'object',
            properties: {
              reps: { type: 'number' },
              weight: { type: 'number' },
            },
            required: ['reps'],
          },
        },
        notes: { type: 'string', description: 'Notes about the exercise' },
        journalEntry: { type: 'string', description: 'Longer-form journal entry reflecting on the workout' },
      },
      required: ['exerciseName', 'sets'],
    },
  },
  {
    name: 'schedule_session',
    description: 'Schedules a future workout session on the calendar, optionally linked to a plan',
    inputSchema: {
      type: 'object',
      properties: {
        scheduledAt: { type: 'string', description: 'ISO 8601 date/time for the scheduled workout (e.g. "2026-03-20T09:00:00")' },
        planId: { type: 'string', description: 'ID of the plan this session is based on' },
        planName: { type: 'string', description: 'Name of the plan for quick reference' },
        notes: { type: 'string', description: 'Notes about the scheduled session' },
      },
      required: ['scheduledAt'],
    },
  },
  {
    name: 'delete_workout_session',
    description: 'Deletes a workout session',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: { type: 'string', description: 'ID of the session to delete' },
      },
      required: ['sessionId'],
    },
  },
  {
    name: 'log_workout_session',
    description: 'Logs a completed workout session from a scheduled plan day (e.g. "Log my lower body workout: Back Squat 5x5 at 195, RDLs 4x7 at 135")',
    inputSchema: {
      type: 'object',
      properties: {
        planId: { type: 'string', description: 'ID of the plan this session is based on' },
        planName: { type: 'string', description: 'Name of the plan' },
        programId: { type: 'string', description: 'ID of the parent program' },
        dayName: { type: 'string', description: 'Name of the day within the plan (e.g. "Day 1: Lower Body")' },
        notes: { type: 'string', description: 'General notes about the session' },
        journalEntry: { type: 'string', description: 'Longer-form journal entry about the workout' },
        entries: {
          type: 'array',
          description: 'Exercises performed',
          items: {
            type: 'object',
            properties: {
              exerciseName: { type: 'string' },
              sets: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    reps: { type: 'number' },
                    weight: { type: 'number' },
                  },
                  required: ['reps'],
                },
              },
              notes: { type: 'string' },
            },
            required: ['exerciseName', 'sets'],
          },
        },
      },
      required: ['entries'],
    },
  },
  {
    name: 'update_session',
    description: 'Updates an existing workout session — fix weights, add exercises, or update notes. Use after list_sessions to get session IDs.',
    inputSchema: {
      type: 'object',
      properties: {
        sessionId: { type: 'string', description: 'ID of the session to update' },
        notes: { type: 'string', description: 'Updated session notes' },
        journalEntry: { type: 'string', description: 'Updated journal entry' },
        completedAt: { type: 'string', description: 'Updated completion time (ISO 8601)' },
        entriesToAdd: {
          type: 'array',
          description: 'New exercises to add to the session',
          items: {
            type: 'object',
            properties: {
              exerciseName: { type: 'string' },
              sets: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: { reps: { type: 'number' }, weight: { type: 'number' } },
                  required: ['reps'],
                },
              },
              notes: { type: 'string' },
            },
            required: ['exerciseName', 'sets'],
          },
        },
        entryUpdates: {
          type: 'array',
          description: 'Updates to existing exercises, matched by exerciseName',
          items: {
            type: 'object',
            properties: {
              exerciseName: { type: 'string', description: 'Name of the exercise to update (used to find the entry)' },
              sets: {
                type: 'array',
                description: 'Replacement sets for this exercise',
                items: {
                  type: 'object',
                  properties: { reps: { type: 'number' }, weight: { type: 'number' } },
                  required: ['reps'],
                },
              },
              notes: { type: 'string' },
            },
            required: ['exerciseName'],
          },
        },
      },
      required: ['sessionId'],
    },
  },
  {
    name: 'list_sessions',
    description: 'Lists recent workout sessions with exercise summaries. Use this to find session IDs before calling update_session.',
    inputSchema: {
      type: 'object',
      properties: {
        limit: { type: 'number', description: 'Number of sessions to return (default 10, max 50)' },
      },
    },
  },
  {
    name: 'query_exercise_history',
    description: 'Queries workout history for a specific exercise. Answers questions like "what did I squat last lower body day?" or "show me my bench press progress".',
    inputSchema: {
      type: 'object',
      properties: {
        exerciseName: { type: 'string', description: 'Exercise name to search for (partial/fuzzy match)' },
        dayName: { type: 'string', description: 'Filter by day name (e.g. "Lower Body")' },
        planName: { type: 'string', description: 'Filter by plan name' },
        startDate: { type: 'string', description: 'Filter sessions on or after this date (ISO 8601)' },
        endDate: { type: 'string', description: 'Filter sessions on or before this date (ISO 8601)' },
        limit: { type: 'number', description: 'Max sessions to return (default 10)' },
      },
      required: ['exerciseName'],
    },
  },
];

export async function handleSessionTool(
  name: string,
  args: Record<string, unknown>,
  userId: string
): Promise<{ content: Array<{ type: 'text'; text: string }>; isError?: boolean }> {
  const db = admin.firestore();
  const sessionsRef = db.collection(`users/${userId}/sessions`);

  try {
    switch (name) {
      case 'log_session': {
        const { planId, planName, notes, journalEntry, scheduledAt, entries } = args as {
          planId?: string; planName?: string; notes?: string; journalEntry?: string;
          scheduledAt?: string;
          entries: Array<{ exerciseName: string; sets: Array<{ reps: number; weight?: number }>; notes?: string }>;
        };
        const now = FieldValue.serverTimestamp();
        const sessionData: Record<string, unknown> = { startedAt: now, completedAt: now };
        if (planId) sessionData.planId = planId;
        if (planName) sessionData.planName = planName;
        if (notes) sessionData.notes = notes;
        if (journalEntry) sessionData.journalEntry = journalEntry;
        if (scheduledAt) sessionData.scheduledAt = Timestamp.fromDate(new Date(scheduledAt));

        const sessionRef = await sessionsRef.add(sessionData);
        const batch = db.batch();
        entries.forEach((entry, i) => {
          const ref = sessionRef.collection('entries').doc();
          const data: Record<string, unknown> = {
            exerciseName: entry.exerciseName,
            sets: entry.sets,
            order: i,
          };
          if (entry.notes) data.notes = entry.notes;
          batch.set(ref, data);
        });
        await batch.commit();
        return textResult({ success: true, sessionId: sessionRef.id, entryCount: entries.length });
      }

      case 'log_quick_exercise': {
        const { exerciseName, sets, notes, journalEntry } = args as {
          exerciseName: string; sets: Array<{ reps: number; weight?: number }>;
          notes?: string; journalEntry?: string;
        };
        const now = FieldValue.serverTimestamp();
        const sessionData: Record<string, unknown> = { startedAt: now, completedAt: now };
        if (notes) sessionData.notes = notes;
        if (journalEntry) sessionData.journalEntry = journalEntry;

        const sessionRef = await sessionsRef.add(sessionData);
        await sessionRef.collection('entries').add({
          exerciseName,
          sets,
          order: 0,
        });
        return textResult({ success: true, sessionId: sessionRef.id, exerciseName, setCount: sets.length });
      }

      case 'schedule_session': {
        const { scheduledAt, planId, planName, notes } = args as {
          scheduledAt: string; planId?: string; planName?: string; notes?: string;
        };
        const sessionData: Record<string, unknown> = {
          scheduledAt: Timestamp.fromDate(new Date(scheduledAt)),
        };
        if (planId) sessionData.planId = planId;
        if (planName) sessionData.planName = planName;
        if (notes) sessionData.notes = notes;

        const sessionRef = await sessionsRef.add(sessionData);
        return textResult({ success: true, sessionId: sessionRef.id, scheduledAt });
      }

      case 'delete_workout_session': {
        const { sessionId } = args as { sessionId: string };
        await sessionsRef.doc(sessionId).delete();
        return textResult({ success: true, sessionId });
      }

      case 'log_workout_session': {
        const { planId, planName, programId, dayName, notes, journalEntry, entries } = args as {
          planId?: string; planName?: string; programId?: string; dayName?: string;
          notes?: string; journalEntry?: string;
          entries: Array<{ exerciseName: string; sets: Array<{ reps: number; weight?: number }>; notes?: string }>;
        };
        const now = FieldValue.serverTimestamp();
        const sessionData: Record<string, unknown> = { startedAt: now, completedAt: now };
        if (planId) sessionData.planId = planId;
        if (planName) sessionData.planName = planName;
        if (programId) sessionData.programId = programId;
        if (dayName) sessionData.dayName = dayName;
        if (notes) sessionData.notes = notes;
        if (journalEntry) sessionData.journalEntry = journalEntry;

        const sessionRef = await sessionsRef.add(sessionData);
        const batch = db.batch();
        entries.forEach((entry, i) => {
          const ref = sessionRef.collection('entries').doc();
          const data: Record<string, unknown> = {
            exerciseName: entry.exerciseName,
            sets: entry.sets,
            order: i,
            userId,
          };
          if (entry.notes) data.notes = entry.notes;
          batch.set(ref, data);
        });
        await batch.commit();
        return textResult({ success: true, sessionId: sessionRef.id, dayName, entryCount: entries.length });
      }

      case 'update_session': {
        const { sessionId, notes, journalEntry, completedAt, entriesToAdd, entryUpdates } = args as {
          sessionId: string;
          notes?: string;
          journalEntry?: string;
          completedAt?: string;
          entriesToAdd?: Array<{ exerciseName: string; sets: Array<{ reps: number; weight?: number }>; notes?: string }>;
          entryUpdates?: Array<{ exerciseName: string; sets?: Array<{ reps: number; weight?: number }>; notes?: string }>;
        };

        const sessionDocRef = sessionsRef.doc(sessionId);
        const sessionSnap = await sessionDocRef.get();
        if (!sessionSnap.exists) return textResult({ error: 'Session not found' }, true);

        const updates: Record<string, unknown> = {};
        if (notes !== undefined) updates.notes = notes;
        if (journalEntry !== undefined) updates.journalEntry = journalEntry;
        if (completedAt !== undefined) updates.completedAt = Timestamp.fromDate(new Date(completedAt));

        const batch = db.batch();
        if (Object.keys(updates).length > 0) {
          batch.update(sessionDocRef, updates);
        }

        if (entriesToAdd && entriesToAdd.length > 0) {
          const existingEntries = await sessionDocRef.collection('entries').orderBy('order').get();
          let nextOrder = existingEntries.size;
          for (const entry of entriesToAdd) {
            const ref = sessionDocRef.collection('entries').doc();
            const data: Record<string, unknown> = {
              exerciseName: entry.exerciseName,
              sets: entry.sets,
              order: nextOrder++,
              userId,
            };
            if (entry.notes) data.notes = entry.notes;
            batch.set(ref, data);
          }
        }

        if (entryUpdates && entryUpdates.length > 0) {
          const existingEntries = await sessionDocRef.collection('entries').get();
          for (const update of entryUpdates) {
            const nameLower = update.exerciseName.toLowerCase();
            const match = existingEntries.docs.find(
              d => (d.data().exerciseName as string).toLowerCase().includes(nameLower)
            );
            if (match) {
              const entryUpdate: Record<string, unknown> = {};
              if (update.sets !== undefined) entryUpdate.sets = update.sets;
              if (update.notes !== undefined) entryUpdate.notes = update.notes;
              batch.update(match.ref, entryUpdate);
            }
          }
        }

        await batch.commit();
        return textResult({ success: true, sessionId });
      }

      case 'list_sessions': {
        const limit = Math.min(Number(args.limit ?? 10), 50);
        const snapshot = await sessionsRef.orderBy('startedAt', 'desc').limit(limit).get();

        const sessions = await Promise.all(
          snapshot.docs.map(async (doc) => {
            const data = doc.data();
            const entriesSnap = await doc.ref.collection('entries').orderBy('order').get();
            const entries = entriesSnap.docs.map(e => {
              const ed = e.data();
              const sets = ed.sets as Array<{ reps: number; weight?: number }>;
              const summary = sets.map(s => s.weight ? `${s.reps}x${s.weight}` : `${s.reps} reps`).join(', ');
              return { entryId: e.id, exerciseName: ed.exerciseName, summary };
            });
            const date = data.completedAt?.toDate?.()?.toISOString() ?? data.startedAt?.toDate?.()?.toISOString() ?? null;
            return {
              sessionId: doc.id,
              date,
              planName: data.planName ?? null,
              dayName: data.dayName ?? null,
              entries,
            };
          })
        );
        return textResult(sessions);
      }

      case 'query_exercise_history': {
        const { exerciseName, dayName: filterDay, planName: filterPlan, startDate, endDate } = args as {
          exerciseName: string;
          dayName?: string;
          planName?: string;
          startDate?: string;
          endDate?: string;
          limit?: number;
        };
        const sessionLimit = Math.min(Number(args.limit ?? 10), 50);
        const nameLower = exerciseName.toLowerCase();

        // Build session query
        let query: FirebaseFirestore.Query = sessionsRef.orderBy('startedAt', 'desc');
        if (startDate) query = query.where('startedAt', '>=', Timestamp.fromDate(new Date(startDate)));
        if (endDate) query = query.where('startedAt', '<=', Timestamp.fromDate(new Date(endDate)));
        // Fetch more sessions than needed to allow filtering by day/plan
        const sessionSnap = await query.limit(100).get();

        const results: Array<{
          sessionId: string;
          date: string | null;
          planName: string | null;
          dayName: string | null;
          sets: Array<{ reps: number; weight?: number }>;
          notes?: string;
        }> = [];

        for (const sessionDoc of sessionSnap.docs) {
          if (results.length >= sessionLimit) break;
          const sd = sessionDoc.data();

          if (filterDay && !(sd.dayName as string | undefined)?.toLowerCase().includes(filterDay.toLowerCase())) continue;
          if (filterPlan && !(sd.planName as string | undefined)?.toLowerCase().includes(filterPlan.toLowerCase())) continue;

          const entriesSnap = await sessionDoc.ref.collection('entries').get();
          const matchingEntry = entriesSnap.docs.find(
            e => (e.data().exerciseName as string).toLowerCase().includes(nameLower)
          );

          if (matchingEntry) {
            const ed = matchingEntry.data();
            const date = sd.completedAt?.toDate?.()?.toISOString() ?? sd.startedAt?.toDate?.()?.toISOString() ?? null;
            results.push({
              sessionId: sessionDoc.id,
              date,
              planName: sd.planName ?? null,
              dayName: sd.dayName ?? null,
              sets: ed.sets,
              ...(ed.notes ? { notes: ed.notes as string } : {}),
            });
          }
        }

        return textResult({
          exerciseName,
          matchCount: results.length,
          history: results,
        });
      }

      default:
        return textResult({ error: `Unknown session tool: ${name}` }, true);
    }
  } catch (error) {
    return textResult({ error: (error as Error).message }, true);
  }
}
