import { test, expect, type Page, type Route } from '@playwright/test';

// The web build is compiled with this SUPABASE_URL (see README.md). Nothing
// runs there: the test answers the app's requests itself.
const supabaseUrl = 'http://127.0.0.1:54321';
const userId = '00000000-0000-4000-8000-000000000001';

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': '*',
  'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
};

type Task = { id: string; title: string; description: null; status: string; due_date: null };
type Dependency = { task_id: string; depends_on_task_id: string };

/**
 * Stands in for the tasks and dependency tables, keeping rows in memory and
 * recording every write. It doesn't enforce the gating rules: the database
 * tests cover those, and this test checks that the app never asks.
 */
async function fakeBackend(page: Page) {
  const tasks: Task[] = [];
  const dependencies: Dependency[] = [];
  const writes: { method: string; table: string; body: unknown }[] = [];
  const unexpected: string[] = [];

  await page.route(`${supabaseUrl}/**`, async (route: Route) => {
    const request = route.request();
    const method = request.method();
    if (method === 'OPTIONS') {
      return route.fulfill({ status: 204, headers: cors });
    }
    const url = new URL(request.url());
    const table = url.pathname.replace('/rest/v1/', '');
    const reply = (status: number, json?: unknown) =>
      route.fulfill({ status, headers: cors, json });

    if (method !== 'GET') {
      writes.push({ method, table, body: request.postDataJSON() });
    }
    if (method === 'GET' && table === 'profiles') return reply(200, []);
    if (method === 'GET' && table === 'tasks') return reply(200, tasks);
    if (method === 'GET' && table === 'task_dependencies') return reply(200, dependencies);
    if (method === 'POST' && table === 'tasks') {
      const row = request.postDataJSON();
      tasks.push({
        id: `00000000-0000-4000-8000-1000000000${tasks.length + 10}`,
        title: row.title,
        description: null,
        status: 'todo',
        due_date: null,
      });
      return reply(201);
    }
    if (method === 'POST' && table === 'task_dependencies') {
      dependencies.push(...request.postDataJSON());
      return reply(201);
    }
    unexpected.push(`${method} ${url.pathname}${url.search}`);
    return reply(404, { message: 'Not handled by the test' });
  });

  return { tasks, writes, unexpected };
}

/** A token the app accepts without checking: only the server verifies it. */
function unsignedJwt(payload: object) {
  const encode = (part: object) => Buffer.from(JSON.stringify(part)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode(payload)}.`;
}

test('a task blocked by an unfinished task cannot be started', async ({ page }) => {
  const backend = await fakeBackend(page);

  // Start signed in: supabase_flutter restores the session it saved under
  // sb-<first part of the SUPABASE_URL host>-auth-token.
  const exp = Math.floor(Date.now() / 1000) + 3600;
  const session = {
    access_token: unsignedJwt({ sub: userId, role: 'authenticated', exp }),
    token_type: 'bearer',
    expires_in: 3600,
    expires_at: exp,
    refresh_token: 'browser-test-refresh-token',
    user: { id: userId, aud: 'authenticated', email: 'alice@example.com', created_at: '2026-01-01T00:00:00Z' },
  };
  await page.addInitScript((value) => {
    localStorage.setItem('sb-127-auth-token', value);
  }, JSON.stringify(session));

  await page.goto('/');
  // Flutter draws to a canvas. Turn on its accessibility tree so the page can
  // be found by role and label, as a screen reader would.
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  // Look in the page itself, not in the copy announced to screen readers.
  const app = page.locator('flt-semantics-host');

  await page.getByRole('button', { name: 'My Tasks' }).click();
  await expect(app.getByText(/^No tasks yet/)).toBeVisible();

  // Each task is a group named after its title, holding its actions menu.
  const taskTile = (title: string) => app.getByRole('group', { name: new RegExp(`^${title}`) });
  const taskActions = (title: string) =>
    taskTile(title).getByRole('button', { name: 'Task actions' });

  for (const title of ['Write tests', 'Ship release']) {
    await page.getByRole('button', { name: 'New task' }).click();
    await page.getByRole('textbox', { name: 'Title' }).click();
    await page.keyboard.type(title);
    await page.getByRole('button', { name: 'Add', exact: true }).click();
    await expect(taskTile(title)).toBeVisible();
  }
  await expect(app.getByText('Ready to start (2)')).toBeVisible();
  const [writeTests, shipRelease] = backend.tasks;

  await taskActions('Ship release').click();
  await page.getByRole('menuitem', { name: 'Edit dependencies…' }).click();
  await expect(app.getByText('"Ship release" is blocked by')).toBeVisible();
  await page.getByRole('checkbox', { name: /Write tests/ }).click();
  await page.getByRole('button', { name: 'Save' }).click();

  await expect(app.getByText('Blocked (1)')).toBeVisible();
  await expect(taskTile('Ship release')).toHaveAccessibleName(/Waiting on: Write tests/);

  await taskActions('Ship release').click();
  const start = page.getByRole('menuitem', { name: /^Start/ });
  await expect(start).toBeDisabled();
  await expect(start).toHaveAccessibleName('Start Blocked by "Write tests"');
  await page.keyboard.press('Escape');

  // The unblocked task can still be started.
  await taskActions('Write tests').click();
  await expect(page.getByRole('menuitem', { name: 'Start', exact: true })).toBeEnabled();
  await page.keyboard.press('Escape');

  // Two tasks and one link were saved, and no status change was ever sent.
  expect(backend.writes).toEqual([
    { method: 'POST', table: 'tasks', body: { title: 'Write tests' } },
    { method: 'POST', table: 'tasks', body: { title: 'Ship release' } },
    {
      method: 'POST',
      table: 'task_dependencies',
      body: [{ task_id: shipRelease.id, depends_on_task_id: writeTests.id }],
    },
  ]);
  expect(backend.unexpected).toEqual([]);
});
