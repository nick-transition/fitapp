import { test, describe, it, beforeEach } from 'node:test';
import assert from 'node:assert';
import { slugify, exerciseLibraryToolDefinitions, handleExerciseLibraryTool } from './lib/tools/exercise-library-tools.js';
import { toolDefinitions, handleToolCall } from './lib/tools/index.js';
import { planToolDefinitions } from './lib/tools/plan-tools.js';

describe('Exercise Library Tools', () => {
  describe('Tool Definitions and Schemas', () => {
    it('registers all four exercise library tools in toolDefinitions', () => {
      const names = toolDefinitions.map((t) => t.name);
      assert.ok(names.includes('search_exercise_library'), 'missing search_exercise_library');
      assert.ok(names.includes('get_library_exercise'), 'missing get_library_exercise');
      assert.ok(names.includes('add_library_exercise'), 'missing add_library_exercise');
      assert.ok(names.includes('update_library_exercise'), 'missing update_library_exercise');
    });

    it('verifies search_exercise_library schema', () => {
      const def = exerciseLibraryToolDefinitions.find((t) => t.name === 'search_exercise_library');
      assert.ok(def);
      assert.strictEqual(def.inputSchema.properties.query.type, 'string');
      assert.strictEqual(def.inputSchema.properties.tags.type, 'array');
      assert.strictEqual(def.inputSchema.properties.limit.type, 'number');
    });

    it('verifies get_library_exercise schema requires exerciseId', () => {
      const def = exerciseLibraryToolDefinitions.find((t) => t.name === 'get_library_exercise');
      assert.ok(def);
      assert.deepStrictEqual(def.inputSchema.required, ['exerciseId']);
    });

    it('verifies add_library_exercise schema requires name', () => {
      const def = exerciseLibraryToolDefinitions.find((t) => t.name === 'add_library_exercise');
      assert.ok(def);
      assert.deepStrictEqual(def.inputSchema.required, ['name']);
    });

    it('verifies update_library_exercise schema requires exerciseId', () => {
      const def = exerciseLibraryToolDefinitions.find((t) => t.name === 'update_library_exercise');
      assert.ok(def);
      assert.deepStrictEqual(def.inputSchema.required, ['exerciseId']);
    });

    it('verifies create_workout_plan includes libraryExerciseId in exercise properties', () => {
      const planDef = planToolDefinitions.find((t) => t.name === 'create_workout_plan');
      assert.ok(planDef);
      const exerciseProps = planDef.inputSchema.properties.days.items.properties.exercises.items.properties;
      assert.ok(exerciseProps.libraryExerciseId, 'missing libraryExerciseId on plan exercise schema');
      assert.strictEqual(exerciseProps.libraryExerciseId.type, 'string');
    });
  });

  describe('slugify helper', () => {
    it('converts display names to clean URL slugs', () => {
      assert.strictEqual(slugify('Barbell Back Squat'), 'barbell-back-squat');
      assert.strictEqual(slugify('Dumbbell Biceps Curl'), 'dumbbell-biceps-curl');
      assert.strictEqual(slugify('3/4 Squat & Press!'), '3-4-squat-press');
      assert.strictEqual(slugify('  Leading and Trailing Spaces  '), 'leading-and-trailing-spaces');
    });
  });

  describe('Scope and Dispatcher Authorization', () => {
    it('rejects search_exercise_library if missing workout:read scope', async () => {
      const res = await handleToolCall(
        'search_exercise_library',
        {},
        { userId: 'user-1', scopes: [], isAdmin: false }
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.ok(parsed.error.includes('Missing required scope: workout:read'));
    });

    it('rejects add_library_exercise if missing workout:write scope', async () => {
      const res = await handleToolCall(
        'add_library_exercise',
        { name: 'Push-Up' },
        { userId: 'admin-1', scopes: ['workout:read'], isAdmin: true }
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.ok(parsed.error.includes('Missing required scope: workout:write'));
    });

    it('rejects add_library_exercise for non-admin user even with workout:write scope', async () => {
      const res = await handleToolCall(
        'add_library_exercise',
        { name: 'Push-Up' },
        { userId: 'user-1', scopes: ['workout:read', 'workout:write'], isAdmin: false }
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Admin permission required');
    });

    it('rejects update_library_exercise for non-admin user even with workout:write scope', async () => {
      const res = await handleToolCall(
        'update_library_exercise',
        { exerciseId: 'push-up', description: 'Updated' },
        { userId: 'user-1', scopes: ['workout:read', 'workout:write'], isAdmin: false }
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Admin permission required');
    });
  });

  describe('Validation and Operations (Mocked Firestore)', () => {
    let mockStore;
    let fakeDb;

    beforeEach(() => {
      mockStore = new Map();

      // Seed initial exercise
      mockStore.set('barbell-back-squat', {
        name: 'Barbell Back Squat',
        description: 'Squat down until thighs are parallel.',
        videoUrl: 'https://youtube.com/watch?v=example1',
        tags: ['legs', 'quads', 'barbell', 'compound'],
        aliases: ['back squat', 'squat'],
        createdBy: 'seed-script',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      });

      mockStore.set('barbell-bench-press', {
        name: 'Barbell Bench Press',
        description: 'Lower bar to chest and press.',
        videoUrl: null,
        tags: ['chest', 'triceps', 'barbell', 'compound'],
        aliases: ['bench press', 'flat bench'],
        createdBy: 'seed-script',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      });

      fakeDb = {
        collection: (collName) => {
          if (collName !== 'exerciseLibrary') throw new Error(`Unexpected collection: ${collName}`);
          return {
            get: async () => ({
              docs: Array.from(mockStore.entries()).map(([id, data]) => ({
                id,
                data: () => ({ ...data }),
              })),
            }),
            doc: (docId) => ({
              id: docId,
              get: async () => {
                const item = mockStore.get(docId);
                return {
                  exists: !!item,
                  id: docId,
                  data: () => (item ? { ...item } : undefined),
                };
              },
              set: async (newData) => {
                mockStore.set(docId, { ...newData });
              },
              update: async (updateData) => {
                const item = mockStore.get(docId);
                if (!item) throw new Error('Not found');
                mockStore.set(docId, { ...item, ...updateData });
              },
            }),
          };
        },
      };
    });

    it('rejects unknown fields on add_library_exercise', async () => {
      const res = await handleExerciseLibraryTool(
        'add_library_exercise',
        { name: 'Pull-Up', unknownProperty: 123 },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Unknown field: unknownProperty');
    });

    it('rejects invalid/empty name on add_library_exercise', async () => {
      const res = await handleExerciseLibraryTool(
        'add_library_exercise',
        { name: '   ' },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.ok(parsed.error.includes('name is required'));
    });

    it('rejects duplicate create when exercise already exists', async () => {
      const res = await handleExerciseLibraryTool(
        'add_library_exercise',
        { name: 'Barbell Back Squat' },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Exercise already exists');
      assert.strictEqual(parsed.exerciseId, 'barbell-back-squat');
    });

    it('successfully adds new library exercise with admin auth', async () => {
      const res = await handleExerciseLibraryTool(
        'add_library_exercise',
        {
          name: 'Overhead Press',
          description: 'Press bar overhead.',
          tags: ['shoulders', 'barbell'],
          aliases: ['ohp', 'military press'],
        },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, undefined);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.success, true);
      assert.strictEqual(parsed.exerciseId, 'overhead-press');
      assert.ok(mockStore.has('overhead-press'));
      assert.strictEqual(mockStore.get('overhead-press').createdBy, 'admin-1');
    });

    it('rejects unknown fields on update_library_exercise', async () => {
      const res = await handleExerciseLibraryTool(
        'update_library_exercise',
        { exerciseId: 'barbell-back-squat', bogusKey: true },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Unknown field: bogusKey');
    });

    it('fails update on missing document without silent creation', async () => {
      const res = await handleExerciseLibraryTool(
        'update_library_exercise',
        { exerciseId: 'nonexistent-exercise', description: 'desc' },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, true);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.error, 'Exercise not found');
      assert.strictEqual(mockStore.has('nonexistent-exercise'), false);
    });

    it('updates exercise preserving omitted fields and stable document ID', async () => {
      const res = await handleExerciseLibraryTool(
        'update_library_exercise',
        {
          exerciseId: 'barbell-back-squat',
          name: 'Renamed Back Squat',
          description: 'Brand new form cues',
        },
        { userId: 'admin-1', scopes: ['workout:write'], isAdmin: true },
        fakeDb
      );
      assert.strictEqual(res.isError, undefined);
      const updated = mockStore.get('barbell-back-squat');
      assert.ok(updated, 'document ID must remain stable at barbell-back-squat');
      assert.strictEqual(updated.name, 'Renamed Back Squat');
      assert.strictEqual(updated.description, 'Brand new form cues');
      // Preserved omitted fields:
      assert.strictEqual(updated.videoUrl, 'https://youtube.com/watch?v=example1');
      assert.deepStrictEqual(updated.tags, ['legs', 'quads', 'barbell', 'compound']);
      assert.deepStrictEqual(updated.aliases, ['back squat', 'squat']);
      assert.strictEqual(updated.createdBy, 'seed-script');
      assert.strictEqual(updated.createdAt, '2026-01-01T00:00:00Z');
    });

    it('gets exercise by ID or returns error if not found', async () => {
      const foundRes = await handleExerciseLibraryTool(
        'get_library_exercise',
        { exerciseId: 'barbell-bench-press' },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      assert.strictEqual(foundRes.isError, undefined);
      const found = JSON.parse(foundRes.content[0].text);
      assert.strictEqual(found.name, 'Barbell Bench Press');

      const notFoundRes = await handleExerciseLibraryTool(
        'get_library_exercise',
        { exerciseId: 'unknown-id' },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      assert.strictEqual(notFoundRes.isError, true);
      const notFound = JSON.parse(notFoundRes.content[0].text);
      assert.strictEqual(notFound.error, 'Exercise not found');
    });

    it('searches exercise library by name substring', async () => {
      const res = await handleExerciseLibraryTool(
        'search_exercise_library',
        { query: 'squat' },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      assert.strictEqual(res.isError, undefined);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.count, 1);
      assert.strictEqual(parsed.exercises[0].id, 'barbell-back-squat');
    });

    it('searches exercise library by alias substring', async () => {
      const res = await handleExerciseLibraryTool(
        'search_exercise_library',
        { query: 'flat bench' },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      assert.strictEqual(res.isError, undefined);
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.count, 1);
      assert.strictEqual(parsed.exercises[0].id, 'barbell-bench-press');
    });

    it('filters search results by tags', async () => {
      const res = await handleExerciseLibraryTool(
        'search_exercise_library',
        { tags: ['legs'] },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.count, 1);
      assert.strictEqual(parsed.exercises[0].id, 'barbell-back-squat');

      const noMatchRes = await handleExerciseLibraryTool(
        'search_exercise_library',
        { tags: ['legs', 'chest'] },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      const noMatch = JSON.parse(noMatchRes.content[0].text);
      assert.strictEqual(noMatch.count, 0);
    });

    it('orders results deterministically and applies bounded limits', async () => {
      const res = await handleExerciseLibraryTool(
        'search_exercise_library',
        { limit: 1 },
        { userId: 'user-1', scopes: ['workout:read'], isAdmin: false },
        fakeDb
      );
      const parsed = JSON.parse(res.content[0].text);
      assert.strictEqual(parsed.count, 1);
      assert.strictEqual(parsed.total, 2);
      assert.strictEqual(parsed.exercises[0].name, 'Barbell Back Squat'); // 'Back Squat' precedes 'Bench Press'
    });
  });
});
