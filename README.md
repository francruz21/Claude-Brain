# Claude-Brain

Personal knowledge base for Claude Code — skills, rules, playbooks, templates and best practices that work across all your projects.

## Qué contiene

| Carpeta | Qué es | Cuándo se usa |
|---|---|---|
| [`skills/`](skills/) | Capacidades formales de Claude Code (`SKILL.md` con frontmatter) | Se autodescubren cuando aplican, o se invocan con `/nombre-skill` |
| [`rules/`](rules/) | Comportamiento esperado y restricciones (git, commits, testing, code review) | Siempre activas como contexto de fondo |
| [`playbooks/`](playbooks/) | Procesos punta a punta en prosa (resolver un ticket, hacer una PR, refactorizar) | Cuando no hace falta (o no existe) una skill formal para el proceso |
| [`templates/`](templates/) | Plantillas reutilizables (PR, commit, ADR, RFC, bug report, etc.) | Al crear cualquiera de esos artefactos |
| [`examples/`](examples/) | Ejemplos completos y reales de uso de los templates | Como referencia de "qué tan detallado" debe quedar un artefacto |
| [`architecture/`](architecture/) | Cómo está organizado este repo y cómo lo consume Claude | Para entender el propio repo |
| [`checklists/`](checklists/) | Listas de verificación cortas y accionables | Antes de dar por cerrada una PR, un release, un review |
| [`best-practices/`](best-practices/) | Guías de fondo sobre AI Engineering y uso de Claude Code | Como contexto general, no como proceso paso a paso |

## Instalación

Las Skills de Claude Code se autodescubren desde `~/.claude/skills/` (skills
personales, disponibles en cualquier proyecto). Este repo no copia archivos ahí:
crea symlinks, para que actualizar `claude-brain` actualice automáticamente las
skills instaladas.

```bash
./install.sh
```

Esto crea un symlink por cada carpeta de `skills/` hacia `~/.claude/skills/<nombre>`.

Para que Claude también tenga presente `rules/`, `playbooks/` y `templates/` en
cualquier proyecto (no son Skills formales, así que no se autodescubren), sumá
una referencia a este repo en tu `~/.claude/CLAUDE.md` global. `install.sh` te
muestra el bloque a pegar si todavía no está.

## Cómo se usa en un repo de trabajo

1. Cloná o mantené actualizado `claude-brain` en tu máquina.
2. Corré `install.sh` una vez (y de nuevo cada vez que agregues una skill nueva).
3. En cualquier repo de cliente, Claude Code va a tener disponibles todas las
   skills instaladas, además del contexto de `rules/`, `playbooks/` y
   `templates/` referenciado desde tu `CLAUDE.md` global.
4. Las convenciones propias de cada repo de cliente (su propio `CLAUDE.md`,
   sus propias rules) **siempre tienen prioridad** sobre lo genérico de este
   repo. `claude-brain` es la base, no un reemplazo del criterio de cada proyecto.

## Filosofía

- **Nada de archivos vacíos.** Cada archivo de este repo tiene contenido útil,
  no placeholders.
- **Escalable a cientos de skills.** La estructura no asume un número fijo de
  skills — `skills/TEMPLATE.md` documenta el formato obligatorio para que sumar
  una nueva sea mecánico.
- **Independiente de cualquier código de cliente.** Este repo nunca debe
  contener lógica de negocio, credenciales, ni nada específico de un proyecto.
- **La convención del repo de cliente gana.** Cuando una rule o skill de acá
  choca con algo definido en el repo donde se está trabajando, gana el repo
  de trabajo.

## Mantenimiento

Este repo se alimenta con el tiempo: cada vez que resuelvas un proceso nuevo de
forma reutilizable, conviene volcarlo acá como skill, rule, playbook o template,
en vez de dejarlo como conocimiento tácito de una sola conversación.
