# SQ

Initial base for SQ project: a Flutter + Supabase quickstart app (magic-link sign-in, profile and avatar).

## Getting Started

### Supabase credentials

Credentials are not stored in the source. Pass them at build/run time with `--dart-define`, using your project's URL and anon key from the Supabase dashboard (Project Settings > API):

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

On Flutter 3.7 or later you can keep the values in a file instead: copy `supabase.example.json` to `supabase.json` (git-ignored), fill it in, and run:

```bash
flutter run --dart-define-from-file=supabase.json
```

The same flags work with `flutter build`. Never use the `service_role` key in the app.

Note: values passed this way are compiled into the app binary, so the anon key is still visible to anyone with the app. Protect your data with Row Level Security.
