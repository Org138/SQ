# Translation review record

Lingo.dev machine-translates `lib/l10n/app_en.arb` into the other locales.
Nothing here has been checked by a fluent speaker until this file says so.

## How to review a locale

1. Read the locale's ARB file next to `app_en.arb`, and check the app in that
   language (set the device or browser language).
2. Prefer fixing wording through the Lingo.dev glossary and brand voice, or
   the English source text, over editing the translated ARB file by hand: a
   later `lingo.dev push` can retranslate the key and undo a hand edit.
3. Update the locale's row below: who reviewed, the date, and the commit whose
   ARB file you read. Add anything left to fix under **Open issues**.

To see what changed in a locale since its last review:

```bash
git diff <reviewed commit> -- lib/l10n/app_de.arb
```

## Status

| Locale | Language | Reviewed by | Date | Commit reviewed | Result |
|---|---|---|---|---|---|
| de | German | — | — | — | Not reviewed |
| es | Spanish | — | — | — | Not reviewed |
| fr | French | — | — | — | Not reviewed |

## Open issues

- **All locales:** "Magic Link" isn't translated consistently. es says
  "enlace de inicio de sesión". To be settled with a glossary entry.
