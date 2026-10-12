# SQ

Initial base for SQ project: a Flutter + Supabase  app.

## Getting Started

Updates on launch, use, etc. = later.

## Supabase MCP server

`.mcp.json` registers the Supabase MCP server for Claude Code in **read-only**
mode with only the `database`, `docs`, `debugging` and `development` tools.
Set `SUPABASE_PROJECT_REF` to your project ref before starting Claude Code.

For write access, add a personal server that stays out of the repo:

```bash
claude mcp add --scope local --transport http supabase-write "https://mcp.supabase.com/mcp?project_ref=<your-project-ref>&features=database%2Cdocs%2Cdebugging%2Cdevelopment"
```
