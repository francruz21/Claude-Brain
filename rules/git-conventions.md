# Git Conventions

## Comportamiento esperado

- Toda rama de trabajo se crea a partir de la rama base configurada para ese
  repo (por defecto `dev`; ver
  [`skills/ticket-workflow/reference/config-schema.md`](../skills/ticket-workflow/reference/config-schema.md)),
  actualizada desde el remoto antes de branchear.
- El nombre de rama sigue el patrón `{type}/{ticketId}-{descripción-corta-en-kebab-case}`,
  ej. `fix/EX-107-solucion-error-color-modal`. El `type` es siempre uno de los
  configurados para ese repo (`feature`, `fix`, `bug`, `hotfix`, `chore`,
  `refactor`, u otro que el repo defina).
- Cada rama tiene un propósito único y acotado — evitar ramas que acumulan
  varios tickets no relacionados.

## Prioridades

1. La convención de ramas propia del repo de trabajo (si existe, ej. en su
   `CONTRIBUTING.md`) gana sobre lo que sugiere esta rule.
2. Si no hay convención propia, se usa el patrón de arriba, configurado una
   sola vez por repo (ver `ticket-workflow`).

## Restricciones

- **Nunca** commitear directo contra la rama base (`dev`, `main`, u otra
  configurada) de ningún repo. Todo commit va contra una rama de trabajo.
- **Nunca** pushear sin confirmación explícita del usuario en el turno actual
  — una confirmación de un push anterior no cubre el siguiente.
- **Nunca** hacer force-push a una rama compartida, ni reescribir historia ya
  publicada, sin pedido explícito del usuario.
- **Nunca** borrar ramas remotas sin confirmación explícita.

## Ejemplos

✅ Correcto:
```
git fetch origin
git checkout dev
git pull origin dev
git checkout -b fix/EX-107-solucion-error-color-modal
```

❌ Incorrecto: crear la rama desde el estado local de `dev` sin actualizarlo
primero (puede quedar desactualizada respecto al remoto).

❌ Incorrecto: `git push origin dev` directo, sin pasar por una PR — incluso
si el cambio es "chiquito".
