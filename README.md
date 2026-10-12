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
`io.supabase.flutterquickstart://login-callback`. For a hosted project, add
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
