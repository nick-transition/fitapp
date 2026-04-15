import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { Tool } from '@modelcontextprotocol/sdk/types.js';

function textResult(data: unknown, isError = false) {
  return {
    content: [{ type: 'text' as const, text: JSON.stringify(data) }],
    ...(isError && { isError: true }),
  };
}

export const planToolDefinitions: Tool[] = [
  {
    name: 'create_workout_program',
    description: 'Creates a new high-level workout program (container for plans)',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: 'Name of the program' },
        description: { type: 'string', description: 'Description of the program' },
      },
      required: ['name'],
    },
  },
  {
    name: 'list_workout_programs',
    description: 'Lists all workout programs for the user',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'create_workout_plan',
    description: 'Creates a new workout plan with multiple days and exercises',
    inputSchema: {
      type: 'object',
      properties: {
        programId: { type: 'string', description: 'Optional ID of the parent program' },
        name: { type: 'string', description: 'Name of the plan' },
        description: { type: 'string', description: 'Description of the plan' },
        type: { type: 'string', description: 'Type: "strength", "cardio", "conditioning", etc.' },
        schedule: { type: 'string', description: 'Day of the week this plan is scheduled for, e.g. "Monday", "Tuesday", etc. Leave unset for unscheduled plans.' },
        days: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              exercises: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    name: { type: 'string' },
                    sets: { type: 'number' },
                    reps: { type: 'number' },
                    weight: { type: 'string', description: 'Weight as a descriptive string (e.g., "bodyweight", "135 lbs", "medium-light working weight", "RPE 7"). Do not use a number.' },
                    videoUrl: { type: 'string' },
                    notes: { type: 'string', description: 'Coaching cues: RIR targets, rest periods, form tips, warm-up instructions. Put all coaching guidance here, NOT in the exercise name.' },
                  },
                  required: ['name', 'sets'],
                },
              },
            },
            required: ['name', 'exercises'],
          },
        },
      },
      required: ['name', 'type', 'days'],
    },
  },
  {
    name: 'list_workout_plans',
    description: 'Lists all workout plans for the user',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'delete_workout_plan',
    description: 'Deletes a workout plan',
    inputSchema: {
      type: 'object',
      properties: {
        planId: { type: 'string', description: 'ID of the plan to delete' },
      },
      required: ['planId'],
    },
  },
  {
    name: 'delete_workout_program',
    description: 'Deletes a workout program',
    inputSchema: {
      type: 'object',
      properties: {
        programId: { type: 'string', description: 'ID of the program to delete' },
      },
      required: ['programId'],
    },
  },
];

export async function handlePlanTool(
  name: string,
  args: Record<string, unknown>,
  userId: string
): Promise<{ content: Array<{ type: 'text'; text: string }>; isError?: boolean }> {
  const db = admin.firestore();

  try {
    switch (name) {
      case 'create_workout_program': {
        const { name: programName, description } = args as { name: string; description?: string };
        const now = FieldValue.serverTimestamp();
        const ref = await db.collection(`users/${userId}/programs`).add({
          name: programName,
          description,
          createdAt: now,
          updatedAt: now,
        });
        return textResult({ success: true, programId: ref.id });
      }

      case 'list_workout_programs': {
        const snapshot = await db.collection(`users/${userId}/programs`).get();
        return textResult(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      }

      case 'delete_workout_program': {
        const { programId } = args as { programId: string };
        // Cascade-delete all plans belonging to this program
        const plansSnapshot = await db
          .collection(`users/${userId}/plans`)
          .where('programId', '==', programId)
          .get();
        const batch = db.batch();
        for (const doc of plansSnapshot.docs) {
          batch.delete(doc.ref);
        }
        batch.delete(db.collection(`users/${userId}/programs`).doc(programId));
        await batch.commit();
        return textResult({ success: true, programId, deletedPlans: plansSnapshot.size });
      }

      case 'create_workout_plan': {
        const { programId, name: planName, description, type, schedule, days } = args as any;
        const now = FieldValue.serverTimestamp();
        const planData = {
          programId,
          name: planName,
          description,
          type,
          schedule: schedule ?? null,
          days,
          createdAt: now,
          updatedAt: now,
        };
        const ref = await db.collection(`users/${userId}/plans`).add(planData);
        return textResult({ success: true, planId: ref.id });
      }

      case 'list_workout_plans': {
        const snapshot = await db.collection(`users/${userId}/plans`).get();
        return textResult(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      }

      case 'get_workout_plan': {
        const { planId } = args as { planId: string };
        const doc = await db.collection(`users/${userId}/plans`).doc(planId).get();
        if (!doc.exists) return textResult({ error: 'Plan not found' }, true);
        return textResult({ id: doc.id, ...doc.data() });
      }

      case 'delete_workout_plan': {
        const { planId } = args as { planId: string };
        await db.collection(`users/${userId}/plans`).doc(planId).delete();
        return textResult({ success: true, planId });
      }

      default:
        return textResult({ error: `Unknown tool: ${name}` }, true);
    }
  } catch (error) {
    return textResult({ error: (error as Error).message }, true);
  }
}
