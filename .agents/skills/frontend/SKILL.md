# Skill — Frontend Rails

## Objetivo

Manter o frontend simples, responsivo, acessível e integrado ao Rails sem criar uma segunda aplicação no navegador.

## Prioridade tecnológica

1. ERB / HTML semântico.
2. CSS da aplicação.
3. Turbo.
4. Stimulus.
5. JavaScript adicional somente quando necessário.

## Regras

- Mobile-first para fluxos públicos de agendamento.
- Não introduzir React, Vue, Angular ou SPA sem ADR aprovada.
- Não duplicar regras de negócio no JavaScript.
- Não gerar HTML inseguro a partir de dados de usuário.
- Preferir atualização de DOM por alvos Stimulus/Turbo em vez de manipulação arbitrária.
- Manter foco visível, labels, contraste e navegação por teclado.
- Estados de erro devem ser legíveis e próximos do campo correspondente.
- Estados críticos não podem depender apenas de cor.
- Respeitar `prefers-reduced-motion`.
