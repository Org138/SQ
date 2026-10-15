# SQ
[![CI](https://github.com/Org138/SQ/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Org138/SQ/actions/workflows/ci.yml)

A Flutter + Supabase app: magic-link sign-in, a user profile with an avatar, and a task list where tasks can be blocked by other tasks.

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (Dart 3)
- A Supabase project, either hosted or local via the
  [Supabase CLI](https://supabase.com/docs/guides/local-development)

### 1. Set up the database

The schema, row level security policies, triggers and the `avatars` storage bucket are all in `supabase/migrations`.

Hosted project:

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

Local stack (applies the migrations on start):

```bash
supabase start
```

### 2. Allow the sign-in redirect

On Android and iOS the magic link opens the app through `io.supabase.sqproject://login-callback`. For a hosted project, add that URL under **Authentication → URL Configuration → Redirect URLs** in the dashboard. The local stack already allows it (`supabase/config.toml`).

Web sign-in redirects to the project's Site URL, so set that to wherever you serve the web app.

### 3. Add your credentials

Copy `supabase.example.json` to `supabase.json` (git-ignored) and fill in your project URL and anon or publishable key. Find them in the dashboard under **Project Settings → API**, or in the output of `supabase start`.

### 4. Run

```bash
flutter run --dart-define-from-file=supabase.json
```

The app stops at startup with an error if `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing.

On web, the magic link always returns to the project's Site URL, but Flutter serves on a random port by default. Pin the port so it matches, for example `http://localhost:3000`

```bash
flutter run -d chrome --web-port 3000 --dart-define-from-file=supabase.json
```

## How it works

The Flutter app talks to Supabase directly with the anon or publishable key, so every rule lives in two places:

- **The app** checks first, to disable actions and explain why before you   try them.
- **The database** enforces the same rules, so anyone calling the API   directly with the same key gets the same answer.

If the two ever disagree, for example because the data changed in another tab, the database wins. The app then shows the database's error message.

### Tasks and dependencies

A task can be blocked by other tasks (`task_dependencies`). A task is blocked while any task it depends on isn't done.

| Rule | In the app (`lib/models/task.dart`) | In the database |
| --- | --- | --- |
| A blocked task can't be started or marked done | **Start** and **Mark done** are disabled in the task menu, with "Blocked by …" underneath | `tasks_enforce_status_gating` trigger |
| A done task can't be reopened while a task that depends on it has started | **Move back to To do** is disabled, with "Can't reopen: …" | `tasks_enforce_status_gating` trigger |
| A task that has started can only depend on finished tasks | Saving the dependency dialog is refused with an explanation | `task_dependencies_enforce_gating` trigger |
| No cycles (A blocked by B blocked by A) | The dependency dialog only lists tasks that wouldn't create one | `task_dependencies_prevent_cycle` trigger |
| A task can't depend on itself | Not offered in the dialog | `check` constraint |

The gating triggers lock the rows they check (Postgres: `for share`), and the cycle check makes each user's dependency changes take turns (an advisory lock), so two changes made at the same moment can't both get past the same rule. They raise readable messages such as `Blocked by "Write tests"`, and the app shows those as is.

### Who can see and change what

Row level security limits each user to their own data:

- **Tasks:** users see and change only the tasks they own. Dependencies can only link two tasks owned by the same user.
- **Profiles:** anyone can read them; users can only create or edit their own. A profile is created automatically at sign-up by a trigger that can't be called through the API. Usernames must be unique, but blank ones are allowed.

### Avatars

Avatars go in the public `avatars` storage bucket under `<user id>/`.

| Rule | In the app (`lib/components/avatar.dart`) | In the database |
| --- | --- | --- |
| JPEG, PNG or WebP only | Other files are refused with "Use a JPEG, PNG or WebP image." | The bucket's allowed types, plus a `.jpg`, `.jpeg`, `.png` or `.webp` extension check in the upload policy |
| 1 MB or smaller | Larger files are refused before uploading | The bucket's 1 MiB size limit |
| Only into your own folder | The app always uploads to `<your user id>/` | Upload policy on `storage.objects` |
| No overwriting or deleting | Each upload gets a new file name | No update or delete policies exist |
| No listing the bucket | The app only builds public URLs | No select policy exists; public URLs don't need one |

SVG and HTML are excluded on purpose: the bucket is public, and a file served with one of those types can run a script in a user's browser.

### Agents hit the same rules

The rules live in the database, so an AI agent with database access gets the same answers as the app:

- **Reading as a user:** row level security limits the agent to that user's tasks only when it acts as that user, like the `psql` run below, which switches to the `authenticated` role with the user's JWT claims. Roles that skip row level security, such as `postgres`, `service_role` and the read-only MCP server's `supabase_read_only_user`, see every user's rows, so an agent using them has to filter by owner itself.
- **Read-only access:** in a read-only session, like the one the read-only MCP server in `.mcp.json` uses, Postgres refuses every write.
- **Writing:** the gating triggers don't check who is asking, so they refuse a blocked start even from the `postgres` role, which skips row level security.

Row level security depends on who is asking, but the task state rules don't, and agents often connect as a service rather than as a user, so rules that must hold whatever the identity belong in triggers or constraints.

This transcript is from Claude Code working with the local stack (`supabase start`) through `psql`, as a demo user with three tasks. "Ship release" depends on "Set up CI", which is done, and on "Write tests", which is in progress. It asks "What's blocking my next task?" in a read-only transaction, then tries to start the blocked task:

```text
> What's blocking my next task?

begin read only;
set local role authenticated;  -- plus the demo user's JWT claims
show transaction_read_only;
 transaction_read_only
-----------------------
 on

with next_task as (
  select id, title from public.tasks
  where status = 'todo' order by created_at limit 1
)
select n.title as next_task, b.title as depends_on, b.status,
       case when b.status <> 'done' then 'BLOCKING' else 'ok' end as verdict
from next_task n
join public.task_dependencies d on d.task_id = n.id
join public.tasks b on b.id = d.depends_on_task_id
order by verdict, b.title;
  next_task   | depends_on  |   status    | verdict
--------------+-------------+-------------+----------
 Ship release | Write tests | in_progress | BLOCKING
 Ship release | Set up CI   | done        | ok
rollback;

> Start "Ship release".

begin;
set local role authenticated;  -- plus the demo user's JWT claims
update public.tasks set status = 'in_progress' where title = 'Ship release';
ERROR:  23514: Blocked by "Write tests"
HINT:  Finish those tasks first.
CONTEXT:  PL/pgSQL function public.enforce_task_status_gating() line 24 at RAISE
rollback;
```

The refusal is the same `Blocked by "Write tests"` message the app shows. When the run was repeated, starting the task inside the read-only transaction failed with `cannot execute UPDATE in a read-only transaction`. Running the update as `postgres` failed with the same `Blocked by` error. "Ship release" stayed To do every time. `supabase/tests/database/tasks.test.sql` checks the same refusal in CI.

The same check against the hosted project went through MCP instead of `psql`: reads used the read-only `supabase` server, and only the start attempt used `supabase-write`. The read-only server has no signed-in user (`auth.uid()` is null and it can't switch to `authenticated`), so the query filters by owner itself:

```text
> What's blocking my next task?

[supabase] with me as (select id from public.profiles where username = '<user>'),
next_task as (
  select t.id, t.title from public.tasks t, me
  where t.owner_id = me.id and t.status = 'todo' order by t.created_at limit 1
)
select n.title as next_task, b.title as depends_on, b.status,
       case when b.status <> 'done' then 'BLOCKING' else 'ok' end as verdict
from next_task n
join public.task_dependencies d on d.task_id = n.id
join public.tasks b on b.id = d.depends_on_task_id
order by verdict, b.title;
  next_task   | depends_on  |   status    | verdict
--------------+-------------+-------------+----------
 Ship Release | Write Tests | in_progress | BLOCKING
 Ship Release | Set Up CI   | done        | ok

> Start "Ship Release".

[supabase-write] update public.tasks set status = 'in_progress'
where title = 'Ship Release' and owner_id = (...);
ERROR:  23514: Blocked by "Write Tests"
HINT:  Finish those tasks first.
CONTEXT:  PL/pgSQL function public.enforce_task_status_gating() line 24 at RAISE

[supabase] select title, status from public.tasks where title = 'Ship Release' ...;
    title     | status
--------------+--------
 Ship Release | todo
```
### Log-ping for Edge Function Logs

`supabase/functions/log-ping` writes one line, `log-ping: called`, to the project's Edge Function logs and returns `{"ok": true}`. It gives a quick check that functions are deployed and that their logs are being recorded. Callers must send the publishable or secret key in the `apikey` header.

A `pg_cron` job calls it at 00:00 UTC on days 1, 6, 11, 16, 21, 26 and 31 of each month, so the runs are 1-5 days apart (`supabase/migrations/20261014222000_schedule_log_ping.sql`). The job runs inside Postgres, so it only fires while the project is running, and missed runs are skipped rather than caught up. It reads the project URL and key from the Vault secrets `project_url` and `publishable_key`. Where those aren't set, as on the local stack, it makes no request.


## Development

```bash
flutter analyze
```

```bash
flutter test
```

The tests don't need a Supabase project: the tasks page tests run against a fake in-memory backend.

The database tests in `supabase/tests/database` check the row level security policies, the task gating triggers and the avatar upload rules with [pgTAP](https://supabase.com/docs/guides/database/testing). They need the local stack, which needs Docker:

```bash
supabase start
```

```bash
supabase test db
```

pgTAP runs in a single session, so one test that needs two sessions at once is a script instead. It adds A blocked by B and B blocked by A at the same moment and checks that the second is refused. It needs `psql`:

```bash
supabase/tests/concurrency/dependency_cycle_race.sh
```

The browser tests in `e2e/` open the release web build in Chromium with [Playwright](https://playwright.dev):

- **Sign in:** sends a magic link from the sign-in page.
- **Task board:** starts signed in, creates two tasks, makes one depend on the other, and checks that the blocked task's **Start** is disabled and that no status change was sent.

They don't need Supabase either: the tests answer the app's requests themselves and check what it sent. They need Node.js 18 or newer:

```bash
flutter build web --release --no-web-resources-cdn --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=browser-test-key
```

```bash
cd e2e && npm ci && npx playwright install chromium && npx playwright test
```

GitHub Actions runs all of these (`.github/workflows/ci.yml`) on every pull request and every push to `main`.

## Supabase MCP server

`.mcp.json` registers the Supabase MCP server for Claude Code in **read-only** mode with only the `database`, `docs`, `debugging` and `development` tools. Set `SUPABASE_PROJECT_REF` to your project ref before starting Claude Code. There is no fallback, so if it is unset Claude Code reports the missing variable instead of connecting to a placeholder project.

For write access, add a personal server that stays out of the repo:

```bash
claude mcp add --scope local --transport http supabase-write "https://mcp.supabase.com/mcp?project_ref=<your-project-ref>&features=database%2Cdocs%2Cdebugging%2Cdevelopment"
```

The Supabase agent skills aren't committed. After cloning, install them into `.agents/skills` and link them for Claude Code:

```bash
npx skills add supabase/agent-skills
```
