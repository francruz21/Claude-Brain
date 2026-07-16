# `.claude/ticket-workflow.config.json` — esquema

Vive en la raíz de **cada repo de trabajo** (front, back, etc.), nunca en
`claude-brain`. Se crea la primera vez que se usa la skill `ticket-workflow`
en ese repo, durante el onboarding.

## Campos

| Campo | Tipo | Ejemplo | Descripción |
|---|---|---|---|
| `workspacePrefix` | string | `"EX"` | Prefijo del tracker para este proyecto. Se usa para reconocer y formatear el ID del ticket. |
| `branchTypes` | string[] | `["feature", "fix", "bug", "hotfix", "chore", "refactor"]` | Tipos de rama válidos para este repo. Se le pregunta al usuario cuál usar en cada ticket. |
| `descriptionLanguage` | `"es"` \| `"en"` | `"es"` | Idioma de la descripción en el nombre de rama y en los commits. |
| `baseBranch` | string | `"dev"` | Rama desde la que se crean las ramas de trabajo, y contra la que nunca se commitea/pushea directo. |
| `commitConvention` | string | `"conventional-commits"` | Convención de mensajes de commit. Puede ser un valor libre si el repo usa algo propio (ej. `"jira-smart-commits"`). |
| `branchPattern` | string | `"{type}/{ticketId}-{description}"` | Patrón de armado del nombre de rama. Placeholders soportados: `{type}`, `{ticketId}`, `{description}`. |

## Ejemplo completo

```json
{
  "workspacePrefix": "EX",
  "branchTypes": ["feature", "fix", "bug", "hotfix", "chore", "refactor"],
  "descriptionLanguage": "es",
  "baseBranch": "dev",
  "commitConvention": "conventional-commits",
  "branchPattern": "{type}/{ticketId}-{description}"
}
```

## Notas

- Este archivo es **local al repo de trabajo**, no a `claude-brain`. Cada
  proyecto tiene el suyo, con su propia convención.
- Si el repo tiene un workspace con varios sub-repos (front/back), cada uno
  tiene su propio config — pueden diferir (ej. front en español, back en
  inglés) si así lo definió el usuario en el onboarding de cada uno.
- Commitear este archivo al repo de trabajo es una decisión del usuario, no
  algo que la skill decida por su cuenta. Si el equipo entero usa Claude Code
  con esta misma convención, tiene sentido compartirlo; si es preferencia
  individual, puede ir en `.gitignore`.
