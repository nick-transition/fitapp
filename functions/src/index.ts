import * as admin from 'firebase-admin';
import { onRequest } from 'firebase-functions/v2/https';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { resolveUser } from './auth.js';
import { handleToolCall, toolDefinitions } from './tools/index.js';
import { handleOAuthRequest, FIREBASE_API_KEY } from './oauth.js';
import { promptDefinitions, getPrompt } from './prompts.js';

admin.initializeApp();

export const mcp = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
    secrets: [FIREBASE_API_KEY],
  },
  async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const path = req.path.replace(/\/$/, '') || '/';

    // Route OAuth requests
    if (path.includes('/authorize') || path.includes('/token') || path.includes('/login') || path.includes('/callback')) {
      return handleOAuthRequest(req, res);
    }

    // Otherwise, handle as MCP request
    try {
      const auth = await resolveUser(req);

      const server = new Server(
        { name: 'fitapp', version: '1.0.0' },
        { capabilities: { tools: {}, prompts: {} } }
      );

      server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: toolDefinitions,
      }));

      server.setRequestHandler(CallToolRequestSchema, async (request) => {
        return handleToolCall(request.params.name, request.params.arguments ?? {}, auth);
      });

      server.setRequestHandler(ListPromptsRequestSchema, async () => ({
        prompts: promptDefinitions,
      }));

      server.setRequestHandler(GetPromptRequestSchema, async (request) => {
        return getPrompt(request.params.name, request.params.arguments ?? {});
      });

      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: undefined,
      });

      await server.connect(transport);
      await transport.handleRequest(req, res);
    } catch (error) {
      const message = (error as Error).message;
      if (
        message === 'Missing Authorization header' ||
        message === 'Missing token' ||
        message === 'Invalid credentials'
      ) {
        res.status(401).json({ error: message });
      } else {
        console.error('MCP server error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
);
