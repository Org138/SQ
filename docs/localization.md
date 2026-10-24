# Localization style guide

The app is written in English (`lib/l10n/app_en.arb`) and machine-translated
into German, Spanish and French by Lingo.dev. The glossary and brand voice
live on the Lingo.dev dashboard (**Infrastructure → Context**: the "App
Functions" glossary and **Brand voices**), not in this repository, so this
file is the record of what they should say. Change both together.

Review status for each language is in
[localization-review.md](localization-review.md).

## Form of address

Each language addresses the user the same way in every string.

| Locale | Language | Register | Examples |
|---|---|---|---|
| de | German | Informal **du** | "Melde dich … an", "deiner E-Mail-Adresse" |
| es | Spanish | Informal **tú** | "Inicia sesión", "tu correo electrónico" |
| fr | French | Formal **vous** | "Connectez-vous", "votre adresse e-mail" |

French uses *vous* because *tu* reads as overly familiar in app text for
adults, while informal German and Spanish are the norm in consumer apps.

Suggested brand voice for the Lingo.dev dashboard:

> Friendly, short and plain. German: address the user as "du". Spanish:
> address the user as "tú". French: address the user as "vous".

## Terminology

| English | de | es | fr |
|---|---|---|---|
| sign-in link | Anmeldelink | enlace de inicio de sesión | lien de connexion |

Use "sign-in link" in English text, not "magic link" or "login link". "Magic
link" is fine in code and developer docs, where it names the Supabase feature.
