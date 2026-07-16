# Playbook: Resolver un ticket (Linear / Jira / otro tracker)

Este playbook es la versión narrativa del proceso que implementa la skill
[`ticket-workflow`](../skills/ticket-workflow/SKILL.md) — usalo como
referencia de alto nivel; para el detalle de cada paso (preguntas exactas,
formato de config, ejemplos) andá a la skill.

## Proceso

1. **Recibir el ticket.** El usuario pega un link o ID. Si hay MCP conectado
   para ese tracker, leerlo directo; si no, pedir que se pegue el contenido.
2. **Verificar convención del repo.** ¿Ya existe configuración de ramas/commits
   para este repo? Si no, es la primera vez — onboarding breve (una sola vez).
3. **Analizar impacto.** ¿El ticket toca uno o varios repos del workspace
   (front/back)? Decidirlo por el contenido del ticket y confirmarlo con el
   usuario antes de crear nada.
4. **Definir tipo de rama.** Siempre se pregunta, incluso si el resto ya está
   configurado.
5. **Crear la rama** desde la base actualizada, con el patrón acordado.
6. **Implementar** el cambio, apoyándose en las convenciones propias del repo.
7. **Commitear** solo con confirmación explícita, con mensaje según la
   convención del repo.
8. **Pushear** solo con confirmación explícita, nunca contra la rama base.
9. **Comentar el ticket** automáticamente tras el push, con un resumen
   profesional de lo hecho.
10. **Ofrecer abrir la PR** contra la rama base, con confirmación.

## Cuándo usar este playbook en vez de la skill directamente

En la práctica, casi siempre conviene invocar directamente la skill
`ticket-workflow` — el playbook es útil como resumen para explicarle el
proceso a otra persona (o a vos mismo) sin entrar al detalle técnico de la
skill.
