---
name: ticket-workflow
description: Use cuando el usuario pega un link o ID de ticket (Linear, Jira, Trello u otro tracker) y espera que Claude analice el ticket, cree la rama correspondiente, implemente, commitee y publique el trabajo. También aplica si el usuario dice explícitamente "trabajá este ticket" o pide crear una rama a partir de un ticket. NO aplica para crear ramas sin relación a un ticket, ni para el proceso de abrir la PR en sí mismo (ver playbook create-pr para eso, aunque esta skill también lo ofrece al final).
---

# Ticket Workflow

## Propósito

Llevar un ticket de un tracker (Linear, Jira, Trello, GitHub Issues, etc.) desde
que se recibe el link hasta que el trabajo está pusheado, comentado en el ticket
y opcionalmente con su PR abierta — siguiendo siempre la convención de ramas y
commits específica del repo donde se trabaja, sin volver a preguntar lo ya
configurado, y sin pushear ni commitear nunca sin confirmación explícita.

## Cuándo usarla

- El usuario pega un link de un ticket (`https://linear.app/...`, `https://empresa.atlassian.net/browse/...`, etc.).
- El usuario pega solo un ID (`EX-107`) y por contexto de la conversación ya se sabe el tracker.
- El usuario dice "poné manos a la obra con este ticket" o equivalente.

## Cuándo NO usarla

- Crear una rama sin ticket asociado (rama exploratoria, spike, etc.) — hacelo directo, sin este flujo.
- El usuario ya tiene una rama creada y solo pide ayuda a implementar código — no hace falta re-disparar el onboarding ni la creación de rama.
- Se pide explícitamente "solo leeme el ticket, no hagas nada todavía" — leé el ticket y parate ahí; no sigas el flujo completo.
- Crear la PR de un trabajo que no pasó por esta skill (ej. un hotfix manual) — usá directamente el playbook [`create-pr`](../../playbooks/create-pr.md).

## Pasos detallados

### 0. Detectar si es la primera vez en este repo

Antes de nada, revisar si existe `.claude/ticket-workflow.config.json` en el
repo de trabajo actual (ver [`reference/config-schema.md`](reference/config-schema.md)
para el formato exacto). Si el directorio actual contiene varios repos git
hijos (workspace con front/back), revisar en cada uno.

- **No existe en ninguno** → ir al paso 1 (onboarding).
- **Existe** → saltar directo al paso 2.

### 1. Onboarding (solo la primera vez, por repo)

Preguntar, en este orden, **una pregunta a la vez**:

1. Prefijo del workspace del tracker (ej. `EX` para `EX-107`). Si el ticket ya
   se pegó, se puede inferir del link/ID y solo confirmar.
2. Qué tipos de rama va a usar este repo (sugerir por defecto:
   `feature, fix, bug, hotfix, chore, refactor` y dejar que el usuario ajuste).
3. Idioma de la descripción de la rama y de los commits: español o inglés.
4. Convención de mensajes de commit — si el repo ya tiene una definida en su
   propio `CLAUDE.md`, `CONTRIBUTING.md` o `rules/`, usar esa y solo confirmarla;
   si no, preguntar explícitamente (no asumir Conventional Commits por defecto).
5. Rama base desde la que se crean las ramas de trabajo (default sugerido: `dev`).

Guardar todo en `.claude/ticket-workflow.config.json` en la raíz del repo
correspondiente. No commitear este archivo salvo que el usuario lo pida
explícitamente (es preferencia local, no necesariamente algo para compartir
con el equipo — si el usuario quiere compartirlo, sugerí agregarlo a
`.gitignore` si decide lo contrario, o commitearlo si quiere que el equipo
comparta la convención).

### 2. Leer el ticket

- Si el link corresponde a un tracker con MCP conectado en la sesión (ej.
  Linear vía `mcp__claude_ai_Linear__get_issue`), leerlo directo: título,
  descripción, labels, proyecto/equipo.
- Si no hay MCP disponible para ese tracker (Jira, Trello sin integración,
  etc.), avisar explícitamente: "no tengo acceso a [tracker] en esta sesión,
  pegame el título y la descripción del ticket para seguir." No usar WebFetch
  como sustituto salvo pedido explícito del usuario — la mayoría de estos
  links no son públicos.

### 3. Analizar el workspace

- Si el directorio de trabajo es un único repo git → trabajar ahí directamente,
  sin preguntar.
- Si el directorio contiene múltiples repos git hijos (ej. `proyecto/frontend`,
  `proyecto/backend`) → leer el contenido del ticket y decidir a cuál(es)
  aplica el cambio (ej. "error de color en un modal" → solo frontend; "el
  endpoint devuelve 500" → solo backend; "agregar campo nuevo en el formulario
  y persistirlo" → ambos). Comunicar la decisión antes de crear ninguna rama:
  "Por el contenido del ticket, esto aplica a frontend. ¿Confirmás o también
  hace falta tocar backend?"

### 4. Preguntar el tipo de rama

Siempre, incluso si ya existe el config: "¿Qué tipo de rama es este ticket:
fix, feature, bug, hotfix, chore o refactor?" (usar los tipos configurados en
el paso 1). El tipo nunca se infiere automáticamente del contenido del ticket.

### 5. Crear la rama

1. Actualizar la rama base configurada (`baseBranch`, ej. `dev`) desde el
   remoto: `git fetch origin && git checkout dev && git pull origin dev`.
2. Crear la rama de trabajo desde ahí, con el patrón
   `{type}/{ticketId}-{descripción-corta}`, en el idioma configurado y en
   `kebab-case`. Ejemplo, para
   `https://linear.app/example/issue/EX-107/ERROR-FRONT-MODAL-COLOR` con
   `type=fix` y `descriptionLanguage=es`:

   ```
   fix/EX-107-solucion-error-color-modal
   ```

   En inglés hubiera sido `fix/EX-107-fix-modal-color-error`.

### 6. Implementar

Trabajar el ticket normalmente, priorizando cualquier skill o rule específica
del repo de trabajo por sobre las genéricas de `claude-brain` (ej. si el repo
tiene su propia convención de testing, esa gana).

### 7. Commit — con confirmación

Proponer el mensaje de commit según la convención configurada (o la
descubierta en el repo) y mostrarlo al usuario antes de commitear. Ejemplo:

> Propongo este commit: `fix: soluciona error de color en modal (EX-107)`. ¿Confirmás?

Nunca ejecutar `git commit` sin una confirmación explícita en el turno actual.

### 8. Push — con confirmación

Preguntar explícitamente antes de pushear: "¿Publico la rama `fix/EX-107-...`
al remoto?" Nunca pushear sin confirmación, y **nunca** pushear ni commitear
directo contra la rama base (`dev` u otra configurada) — solo contra la rama
de trabajo recién creada.

### 9. Comentario en el ticket — automático

Inmediatamente después de un push confirmado, publicar un comentario en el
ticket (vía el MCP del tracker correspondiente) con un resumen profesional y
conciso de lo trabajado. No pedir confirmación adicional para este paso — ya
quedó autorizado al confirmar el push. Ver ejemplo en
[`reference/examples.md`](reference/examples.md).

### 10. Pull Request — con confirmación

Preguntar si se quiere abrir la PR contra la rama base, usando
[`templates/pull-request.md`](../../templates/pull-request.md) del repo
`claude-brain` (o el template propio del repo de trabajo si existe). Si el
usuario confirma, crearla; si no, dejar la tarea cerrada en el paso 9.

### 11. Segunda vez en adelante

Si el config ya existe para este repo, saltar directo del paso 2 al 4 (no se
repite el onboarding). Los únicos puntos que siempre requieren pregunta son:
el tipo de rama (paso 4), la confirmación de commit (paso 7), la confirmación
de push (paso 8) y la confirmación de PR (paso 10).

## Checklist

- [ ] Se verificó si existe `.claude/ticket-workflow.config.json` antes de preguntar nada.
- [ ] El ticket se leyó por MCP o se pidió pegado manual — nunca se inventó contenido.
- [ ] Se analizó si el workspace tiene un repo o varios, y se comunicó la decisión de en cuál(es) trabajar.
- [ ] Se preguntó el tipo de rama para este ticket específico.
- [ ] La rama se creó desde la base actualizada del remoto, con el patrón configurado.
- [ ] El commit se propuso y se confirmó explícitamente antes de ejecutarse.
- [ ] El push se confirmó explícitamente antes de ejecutarse, y nunca fue contra la rama base.
- [ ] Se publicó el comentario de resumen en el ticket tras el push.
- [ ] Se preguntó si se quiere abrir la PR.

## Ejemplos

Ver [`reference/examples.md`](reference/examples.md) para un flujo completo de
punta a punta, incluyendo el onboarding de primera vez y el comentario final
publicado en el ticket.

## Errores comunes

- **Preguntar el onboarding de nuevo** cuando el config ya existe — revisar
  siempre el archivo antes de preguntar cualquier cosa que ya podría estar
  configurada.
- **Commitear o pushear sin decirlo explícitamente en el turno** — una
  confirmación de una tarea anterior no cuenta para la tarea actual.
- **Pushear contra `dev`** por asumir que la rama de trabajo ya "es" la base —
  siempre verificar `git branch --show-current` antes de pushear.
- **Inventar el prefijo del workspace** a partir del nombre de la empresa en
  vez del ID real del ticket (ej. asumir `EXAMPLE-107` cuando el ID real es
  `EX-107`).
- **No decidir qué repos tocar** cuando el workspace tiene varios, y crear
  ramas en todos "por las dudas" — analizar el ticket primero, y confirmar la
  decisión con el usuario en vez de branchear todo.
- **Publicar el comentario en el ticket antes del push real**, o pedir
  confirmación redundante para ese comentario — el punto de autorización es el
  push, no un paso aparte.

## Buenas prácticas

- El resumen del comentario en el ticket debe ser útil para alguien que no
  vio el trabajo: qué cambió, por qué, y en qué rama/PR está — no un genérico
  "se resolvió el ticket."
- Si el usuario corrige algo de la convención (ej. "en realidad los fix van
  con guion bajo, no guion medio"), actualizar el config inmediatamente, no
  solo para ese ticket.
- Si el repo de trabajo tiene su propio `CLAUDE.md` o `rules/` con convención
  de commits o de ramas, esa información gana sobre cualquier default sugerido
  acá — preguntar solo lo que realmente falta definir.
