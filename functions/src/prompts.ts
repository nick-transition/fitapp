import { Prompt } from '@modelcontextprotocol/sdk/types.js';

export const promptDefinitions: Prompt[] = [
  {
    name: 'builder-program',
    description: 'Guide the user through creating a complete workout program with multiple plans and a schedule.',
    arguments: [
      {
        name: 'goal',
        description: 'The user\'s fitness goal (e.g., muscle gain, weight loss, mobility)',
        required: false,
      },
    ],
  },
];

export function getPrompt(name: string, args: Record<string, string>): { messages: any[] } {
  if (name === 'builder-program') {
    const goal = args.goal || 'general fitness';
    return {
      messages: [
        {
          role: 'user',
          content: {
            type: 'text',
            text: `I want to build a new workout program for ${goal}. Please guide me through this using your FitApp tools.

Follow these steps exactly:
1. First, suggest a high-level Program name and description based on my goal.
2. Once I approve the program name, use the 'create_workout_program' tool to create it.
3. Next, propose a workout split (e.g., a 3-day or 4-day plan) that fits this program.
4. For each day in the plan, suggest specific exercises with:
   - sets (number), reps (number, optional), weight (string like "135 lbs" or "bodyweight", optional)
   - notes: important coaching cues, rep ranges, rest times, RIR targets, form tips (put these in the notes field, not the name)
   - videoUrl: YouTube reference links for complex movements (optional)
5. Ask me which days of the week I want to do each workout (e.g., "Monday", "Wednesday", "Friday").
6. Once I approve the plan details, use the 'create_workout_plan' tool to save it with:
   - programId from step 2
   - schedule set to the day of the week (e.g., "Monday") so it shows up on the right day in the app
   - type set to the workout type (e.g., "strength", "cardio", "conditioning")
7. Finally, use the 'schedule_session' tool to put these planned workouts onto my FitApp calendar.

Data structure reference for create_workout_plan:
- days: array of { name, exercises: [{ name, sets, reps?, weight?, notes?, videoUrl? }] }
- schedule: day of week string — IMPORTANT: set this so plans appear on the correct day in the app
- type: workout category string

Logging workouts:
- Use 'log_workout_session' to record a completed session tied to a plan day (e.g. "Log my lower body day: squats 5x5 at 195, RDLs 4x7 at 135")
- Use 'update_session' to fix mistakes after logging (e.g. "Actually I did 200 on my last set of squats")
- Use 'list_sessions' to see recent sessions and get session IDs before updating
- Use 'query_exercise_history' to answer questions like "what did I squat last lower body day?" or "show me my bench press over the last month"

Let's start with step 1: Suggest a program name and description.`,
          },
        },
      ],
    };
  }
  throw new Error(`Prompt not found: ${name}`);
}
