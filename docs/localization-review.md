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

None known. Resolved so far (checked by search, not by a fluent speaker):

- "Magic link" no longer appears in any translation. Since Lingo.dev run
  `lrg_avaYGGA0O0S59HA2L7DG`, each locale uses its glossary term for
  "sign-in link" (de "Anmeldelink", es "enlace de inicio de sesión", fr
  "lien de connexion").
- French `errorOutOfDate` said "Actualisez la page", but the app has no
  pages. The English now says "Refresh the list", and since run
  `lrg_hEHIHZLuPgnAtfz2cozp` the French says "Actualisez la liste".
