import { Tool } from '@modelcontextprotocol/sdk/types.js';
import { planToolDefinitions, handlePlanTool } from './plan-tools.js';
import { sessionToolDefinitions, handleSessionTool } from './session-tools.js';
import { AuthContext } from '../auth.js';

export const toolDefinitions: Tool[] = [
  ...planToolDefinitions,
  ...sessionToolDefinitions,
];

const planToolNames = new Set(planToolDefinitions.map((t) => t.name));
const sessionToolNames = new Set(sessionToolDefinitions.map((t) => t.name));

/**
 * Maps each tool to its required OAuth scope.
 */
const toolScopeMap: Record<string, string> = {
  // Program tools
  'create_workout_program': 'workout:write',
  'list_workout_programs': 'workout:read',
  'delete_workout_program': 'workout:write',
  // Plan tools
  'list_workout_plans': 'workout:read',
  'get_workout_plan': 'workout:read',
  'create_workout_plan': 'workout:write',
  'delete_workout_plan': 'workout:write',
  // Session tools
  'log_session': 'workout:write',
  'log_quick_exercise': 'workout:write',
  'schedule_session': 'workout:write',
  'delete_workout_session': 'workout:write',
  'log_workout_session': 'workout:write',
  'update_session': 'workout:write',
  'list_sessions': 'workout:read',
  'query_exercise_history': 'workout:read',
};

export async function handleToolCall(
  name: string,
  args: Record<string, unknown>,
  auth: AuthContext
): Promise<{ content: Array<{ type: 'text'; text: string }>; isError?: boolean }> {
  const requiredScope = toolScopeMap[name];
  
  if (requiredScope && !auth.scopes.includes(requiredScope)) {
    return {
      content: [{ 
        type: 'text', 
        text: JSON.stringify({ 
          error: `Missing required scope: ${requiredScope}`,
          requested_tool: name 
        }) 
      }],
      isError: true,
    };
  }

  if (planToolNames.has(name)) {
    return handlePlanTool(name, args, auth.userId);
  }
  if (sessionToolNames.has(name)) {
    return handleSessionTool(name, args, auth.userId);
  }
  return {
    content: [{ type: 'text', text: JSON.stringify({ error: `Unknown tool: ${name}` }) }],
    isError: true,
  };
}
