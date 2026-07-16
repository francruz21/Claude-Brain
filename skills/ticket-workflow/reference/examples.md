# Ejemplo de flujo completo — `ticket-workflow`

## Escenario

Workspace `~/proyectos/acme/` con dos repos git: `acme/frontend` y
`acme/backend`. Primera vez que se usa la skill en `frontend`. El usuario pega:

```
https://linear.app/acme/issue/EX-107/ERROR-FRONT-MODAL-COLOR
```

## Turno 1 — onboarding (primera vez en este repo)

> **Claude:** No encuentro `.claude/ticket-workflow.config.json` en este repo,
> así que antes de arrancar necesito configurar algunas cosas (solo se
> pregunta una vez).
>
> ¿Cuál es el prefijo de este workspace en el tracker? Por el link parece ser `EX`, ¿confirmás?

> **Usuario:** sí, EX

> **Claude:** ¿Qué tipos de rama usás en este repo? Te sugiero por defecto
> `feature, fix, bug, hotfix, chore, refactor` — ¿los dejamos así o ajustamos?

> **Usuario:** dejalos así

> **Claude:** ¿La descripción de la rama y de los commits va en español o en inglés?

> **Usuario:** español

> **Claude:** No encontré una convención de commits definida en este repo
> (ni `CONTRIBUTING.md` ni reglas propias). ¿Qué convención querés usar?

> **Usuario:** Conventional Commits

> **Claude:** Por último, ¿desde qué rama remota partimos las ramas de trabajo? (sugerido: `dev`)

> **Usuario:** dev, sí

Claude guarda `.claude/ticket-workflow.config.json` con esos valores.

## Turno 2 — lectura del ticket y análisis del workspace

> **Claude:** Leí el ticket EX-107 vía Linear: "Error de color en modal —
> el modal de confirmación muestra el botón principal en gris en vez del
> color de marca." Por el contenido, esto aplica solo a `frontend`, no hace
> falta tocar `backend`. ¿Confirmás?

> **Usuario:** sí

## Turno 3 — tipo de rama

> **Claude:** ¿Qué tipo de rama es este ticket: fix, feature, bug, hotfix, chore o refactor?

> **Usuario:** fix

## Turno 4 — rama y trabajo

Claude actualiza `dev` local desde el remoto y crea:

```
fix/EX-107-solucion-error-color-modal
```

Implementa el cambio de color del botón.

## Turno 5 — commit

> **Claude:** Propongo este commit:
> `fix: soluciona error de color en boton principal del modal (EX-107)`
> ¿Confirmás?

> **Usuario:** sí

## Turno 6 — push

> **Claude:** ¿Publico la rama `fix/EX-107-solucion-error-color-modal` al remoto?

> **Usuario:** dale

Claude pushea la rama (nunca `dev`) y, automáticamente, publica este
comentario en el ticket EX-107 (sin pedir confirmación adicional):

> **Comentario publicado en EX-107 (Linear):**
>
> **Resuelto en `fix/EX-107-solucion-error-color-modal`**
>
> El botón principal del modal de confirmación usaba el color gris por
> defecto del componente base en vez de la variable de color de marca
> (`--color-primary`). Se corrigió el override de estilos en
> `ConfirmModal.tsx` para heredar la variable correcta.
>
> Rama pusheada y lista para PR.

## Turno 7 — PR

> **Claude:** ¿Abro la Pull Request de `fix/EX-107-solucion-error-color-modal` contra `dev`?

> **Usuario:** sí

Claude crea la PR usando `templates/pull-request.md`.

## Segunda vez (ticket EX-114, mismo repo)

El usuario pega el link de EX-114. Como el config ya existe, Claude **no**
repite el onboarding — pasa directo a leer el ticket, analizar a qué repo(s)
aplica, y preguntar el tipo de rama.
