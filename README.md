# SQ

A Flutter + Supabase app: magic-link sign-in, a user profile with an avatar,
and a task list where tasks can be blocked by other tasks.

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (Dart 3)
- A Supabase project, either hosted or local via the
  [Supabase CLI](https://supabase.com/docs/guides/local-development)

### 1. Set up the database

The schema, row level security policies, triggers and the `avatars` storage
bucket are all in `supabase/migrations`.

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

On Android and iOS the magic link opens the app through
`io.supabase.sqproject://login-callback`. For a hosted project, add
that URL under **Authentication → URL Configuration → Redirect URLs** in the
dashboard. The local stack already allows it (`supabase/config.toml`).

Web sign-in redirects to the project's Site URL, so set that to wherever you
serve the web app.

### 3. Add your credentials

Copy `supabase.example.json` to `supabase.json` (git-ignored) and fill in your
project URL and anon or publishable key. Find them in the dashboard under
**Project Settings → API**, or in the output of `supabase start`.

### 4. Run

```bash
flutter run --dart-define-from-file=supabase.json
```

The app stops at startup with an error if `SUPABASE_URL` or
`SUPABASE_ANON_KEY` is missing.

## How it works

The Flutter app talks to Supabase directly with the anon or publishable key,
so every rule lives in two places:

- **The app** checks first, to disable actions and explain why before you
  try them.
- **The database** enforces the same rules, so anyone calling the API
  directly with the same key gets the same answer.

If the two ever disagree, for example because the data changed in another
tab, the database wins. The app then shows the database's error message.

### Tasks and dependencies

A task can be blocked by other tasks (`task_dependencies`). A task is blocked
while any task it depends on isn't done.

| Rule | In the app (`lib/models/task.dart`) | In the database |
| --- | --- | --- |
| A blocked task can't be started or marked done | **Start** and **Mark done** are disabled in the task menu, with "Blocked by …" underneath | `tasks_enforce_status_gating` trigger |
| A done task can't be reopened while a task that depends on it has started | **Move back to To do** is disabled, with "Can't reopen: …" | `tasks_enforce_status_gating` trigger |
| A task that has started can only depend on finished tasks | Saving the dependency dialog is refused with an explanation | `task_dependencies_enforce_gating` trigger |
| No cycles (A blocked by B blocked by A) | The dependency dialog only lists tasks that wouldn't create one | `task_dependencies_prevent_cycle` trigger |
| A task can't depend on itself | Not offered in the dialog | `check` constraint |

The triggers lock the rows they check (`for share`), so two changes made at
the same moment can't both get past the same rule. They raise readable
messages such as `Blocked by "Write tests"`, and the app shows those as is.

### Who can see and change what

Row level security limits each user to their own data:

- **Tasks:** users see and change only the tasks they own. Dependencies can
  only link two tasks owned by the same user.
- **Profiles:** anyone can read them; users can only create or edit their
  own. A profile is created automatically at sign-up by a trigger that can't
  be called through the API. Usernames must be unique, but blank ones are
  allowed.

### Avatars

Avatars go in the public `avatars` storage bucket under `<user id>/`.

| Rule | In the app (`lib/components/avatar.dart`) | In the database |
| --- | --- | --- |
| JPEG, PNG or WebP only | Other files are refused with "Use a JPEG, PNG or WebP image." | The bucket's allowed types, plus a `.jpg`, `.jpeg`, `.png` or `.webp` extension check in the upload policy |
| 1 MB or smaller | Larger files are refused before uploading | The bucket's 1 MiB size limit |
| Only into your own folder | The app always uploads to `<your user id>/` | Upload policy on `storage.objects` |
| No overwriting or deleting | Each upload gets a new file name | No update or delete policies exist |

SVG and HTML are excluded on purpose: the bucket is public, and a file served
with one of those types can run script in a visitor's browser.

## Development

```bash
flutter analyze
```

```bash
flutter test
```

The tests don't need a Supabase project: the tasks page tests run against a
fake in-memory backend.

## Supabase MCP server

`.mcp.json` registers the Supabase MCP server for Claude Code in **read-only**
mode with only the `database`, `docs`, `debugging` and `development` tools.
Set `SUPABASE_PROJECT_REF` to your project ref before starting Claude Code.

For write access, add a personal server that stays out of the repo:

```bash
claude mcp add --scope local --transport http supabase-write "https://mcp.supabase.com/mcp?project_ref=<your-project-ref>&features=database%2Cdocs%2Cdebugging%2Cdevelopment"
```
