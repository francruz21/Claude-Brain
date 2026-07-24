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
   Este default es solo el *fallback* cuando el ticket no trae ninguna señal
   propia — ver paso 2 y paso 5 para el caso en que el ticket especifica su
   propia rama base vía tag/label.

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
- **Revisar las labels/tags del ticket buscando una señal de ambiente/rama
  de origen** (ej. `stage`, `dev`, `hotfix`, `prod`), independientemente del
  tracker. Esta señal determina desde qué rama se corta la rama de trabajo
  en el paso 5 — no confundir con el tipo de rama del paso 4, que es sobre
  la naturaleza del cambio, no sobre su origen.

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

**Excepción — tickets de Linear:** si el ticket se leyó por el MCP de Linear
(`get_issue`), este paso se omite. Linear ya devuelve su propio nombre de
rama canónico en el campo `gitBranchName` de la respuesta, y ese nombre no
lleva prefijo de tipo — ver paso 5.

**Excepción a la excepción — el repo valida el nombre de rama por CI:** antes
de aplicar la excepción de arriba, revisar si el repo tiene un check de CI
tipo "Branch name convention" (o un `docs/branch-conventions.md`) que exija
un prefijo de tipo. Si existe, ese validador gana sobre el uso verbatim de
`gitBranchName`: sí preguntar el tipo en este paso, y armar el nombre según
el patrón del paso 5. Un `gitBranchName` de Linear con prefijo de usuario
(ej. `franciscocruz/edw-138-...`) casi nunca matchea un regex que empiece
con `(feat|fix|...)`, así que en repos con este check la excepción de Linear
no aplica. Guardar el hallazgo en `.claude/ticket-workflow.config.json` del
repo (campo `branchNameCI`) para no tener que redescubrirlo cada vez.

### 5. Crear la rama

1. Determinar la rama base para **este ticket específico** — nunca asumir
   directamente la `baseBranch` configurada sin revisar antes la señal del
   paso 2:
   - **El ticket tiene un tag/label de ambiente** (ej. `stage`, `dev`,
     `hotfix`) → esa es la rama base, aunque sea distinta de la `baseBranch`
     default configurada en `.claude/ticket-workflow.config.json`. No pedir
     confirmación extra — el tag ya es la señal explícita.
   - **El ticket NO tiene ningún tag de ambiente** → preguntar explícitamente
     antes de crear nada: "¿Desde qué rama parto esta rama de trabajo: `dev`,
     `stage`, u otra?" No completar en silencio con la `baseBranch` default —
     la ausencia de tag no equivale a "usar el default", equivale a "hace
     falta preguntar".
   - Aplica a cualquier tracker (Linear, Jira, etc.), no solo a Linear.
2. Actualizar la rama base resultante desde el remoto: `git fetch origin &&
   git checkout <rama-base> && git pull origin <rama-base>`.
3. Crear la rama de trabajo desde ahí.

   **Tickets de Linear, repo SIN CI de nombre de rama:** usar **tal
   cual, sin modificar** el valor del campo `gitBranchName` que devuelve
   `get_issue` como nombre de la rama — no el patrón
   `{type}/{ticketId}-{descripción}` de abajo. Esto es lo que permite que
   Linear trackee automáticamente la rama (y luego el PR) contra el ticket
   en su propia UI; inventar un nombre propio rompe ese tracking aunque el
   ticket ID aparezca en el nombre. Ejemplo: si `get_issue` devuelve
   `"gitBranchName": "franciscocruz/edw-138-usuario-validador-del-hub-..."`,
   la rama se llama exactamente eso, en ambos repos si el ticket toca
   varios.

   **Tickets de Linear, repo CON CI de nombre de rama** (ver excepción a la
   excepción del paso 4): usar el patrón `{type}/{TICKET-ID}-{slug}`, donde
   `{slug}` es la parte de `gitBranchName` posterior al ticket ID, sin el
   prefijo de usuario. Ejemplo: `gitBranchName` =
   `franciscocruz/edw-138-usuario-validador-del-hub-modificar-flujo-boton-rechazar`
   con `type=feat` da `feat/EDW-138-usuario-validador-del-hub-modificar-flujo-boton-rechazar`.
   Si la PR ya se creó contra el nombre viejo y hay que renombrar la rama en
   GitHub, **no usar el endpoint de rename de la API** (`POST
   .../branches/{branch}/rename`) — cierra automáticamente cualquier PR
   abierta porque borra el ref viejo (`head_ref_deleted`) en vez de
   actualizar su head. En cambio: renombrar local (`git branch -m`), pushear
   la rama nueva, borrar la vieja, y abrir una PR nueva contra la rama
   renombrada (la PR vieja queda cerrada como referencia histórica).

   **Cualquier otro tracker** (Jira, Trello, GitHub Issues sin este campo):
   usar el patrón `{type}/{ticketId}-{descripción-corta}`, en el idioma
   configurado y en `kebab-case`. Ejemplo, para
   `https://linear.app/example/issue/EX-107/ERROR-FRONT-MODAL-COLOR` con
   `type=fix` y `descriptionLanguage=es` (caso hipotético sin `gitBranchName`
   disponible):

   ```
   fix/EX-107-solucion-error-color-modal
   ```

   En inglés hubiera sido `fix/EX-107-fix-modal-color-error`.

4. Si la rama ya se había creado con el patrón genérico antes de notar que
   el ticket era de Linear, renombrarla en el momento con
   `git branch -m <nombre-nuevo>` (preserva cambios sin commitear) en vez de
   recrearla desde cero.

### 6. Implementar

Trabajar el ticket normalmente, priorizando cualquier skill o rule específica
del repo de trabajo por sobre las genéricas de `claude-brain` (ej. si el repo
tiene su propia convención de testing, esa gana).

**Si el cambio toca frontend:** antes de pasar al commit, levantar el cambio
en el navegador (skill `run`, o herramientas `claude-in-chrome` si no hay un
flujo de la app ya definido) y capturar una o más screenshots mostrando el
resultado — antes/después si aplica al bug o feature. Estas capturas no son
para mostrar en el chat y descartar: se adjuntan en el paso 9 (comentario del
ticket) y se incluyen en el paso 10 (descripción de la PR).

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
conciso de lo trabajado. **Si el cambio incluyó frontend, adjuntar al
comentario las screenshots capturadas en el paso 6** (ej. `create_attachment`/
`prepare_attachment_upload` en Linear, o el mecanismo de adjuntos propio del
tracker) — no alcanza con describir el cambio visual solo en texto si hay una
captura disponible. No pedir confirmación adicional para este paso — ya
quedó autorizado al confirmar el push. Ver ejemplo en
[`reference/examples.md`](reference/examples.md).

### 10. Pull Request — con confirmación

Preguntar si se quiere abrir la PR contra la rama base, usando
[`templates/pull-request.md`](../../templates/pull-request.md) del repo
`claude-brain` (o el template propio del repo de trabajo si existe). **Si el
cambio incluyó frontend, incluir en la descripción de la PR las mismas
screenshots del paso 6** (sección "Capturas de pantalla" del template) — no
alcanza con haberlas puesto solo en el comentario del ticket. Si el usuario
confirma, crearla; si no, dejar la tarea cerrada en el paso 9.

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
- [ ] Se revisaron los tags/labels del ticket para la rama base; si no había ninguno, se preguntó explícitamente en vez de asumir el default.
- [ ] La rama se creó desde la base actualizada del remoto, con el patrón configurado.
- [ ] El commit se propuso y se confirmó explícitamente antes de ejecutarse.
- [ ] El push se confirmó explícitamente antes de ejecutarse, y nunca fue contra la rama base.
- [ ] Se publicó el comentario de resumen en el ticket tras el push.
- [ ] Si el cambio fue de frontend, se capturaron screenshots y se incluyeron tanto en el comentario del ticket como en la descripción de la PR.
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
- **Inventar un nombre de rama para un ticket de Linear** en vez de usar el
  `gitBranchName` tal cual — aunque el nombre propio incluya el ID del
  ticket, rompe el auto-tracking de Linear entre la rama/PR y el issue. Pero
  ver la excepción a la excepción del paso 4: si el repo valida el nombre de
  rama por CI con un patrón de tipo obligatorio, ese check gana.
- **Asumir que `gitBranchName` de Linear siempre pasa el CI del repo** — su
  prefijo es el usuario (ej. `franciscocruz/...`), no un tipo, y varios repos
  exigen `{type}/{TICKET-ID}-{slug}` vía un check de CI. Confirmar esto antes
  de crear la rama, no después de que falle el PR.
- **Renombrar una rama remota con PR abierta usando el endpoint de rename de
  GitHub** (`branches/{branch}/rename`) — borra el ref viejo y GitHub cierra
  la PR automáticamente (`head_ref_deleted`) en vez de re-apuntarla. Para
  corregir un nombre de rama con PR ya abierta: rename local + push de la
  rama nueva + PR nueva contra ese nombre.
- **Publicar el comentario en el ticket antes del push real**, o pedir
  confirmación redundante para ese comentario — el punto de autorización es el
  push, no un paso aparte.
- **Asumir la `baseBranch` default cuando el ticket no tiene tag de
  ambiente** — la ausencia de señal significa preguntar, no completar en
  silencio con `dev` u otro default configurado.
- **Ignorar un tag de ambiente en el ticket y usar la `baseBranch` default
  igual** — el tag es una señal explícita por ticket y gana sobre el default
  del repo.
- **Omitir las screenshots en un cambio de frontend** — un comentario de
  ticket o una PR que solo describe en texto un cambio visual obliga al
  revisor a levantar la rama para ver qué cambió. Siempre capturar y adjuntar
  en ambos lugares (comentario del ticket y descripción de la PR) cuando el
  ticket toca UI.

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
