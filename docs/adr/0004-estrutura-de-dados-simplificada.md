# ADR 0004 — Estrutura de dados inicial simplificada

## Status

Aceita pelo escopo explícito do RF002, em 25/11/2026. Validação de execução pendente.

## Contexto

O RF002 define oito docas físicas fixas e dez janelas fixas, substituindo as sete docas da referência original. Nesta etapa não existem cadastros administrativos, usuários ou fluxos operacionais.

## Decisão

Criar somente `bookings`, `slot_blocks` e `audit_events`, com chaves primárias bigint, migrations Rails e PostgreSQL. Não criar tabelas de docas, janelas, usuários, papéis, permissões ou sessões.

Centralizar as definições fixas no backend em `AgendaDefinition`: docas de 1 a 8, janelas de 1 a 10 e horários, com a última janela das 17:00 às 17:48. A distribuição das docas por operação permanece indefinida. As migrations preservam seus próprios limites literais para permanecerem reproduzíveis mesmo após futuras alterações do domínio.

Usar constraints no PostgreSQL e índices únicos parciais para capacidade por data/doca/janela e ocupação física por doca, além de optimistic locking nativo por `lock_version`. Models possuem somente validações estruturais, sem serviços, fluxos ou callbacks de operação.

A auditoria utiliza referência genérica `entity_type`/`entity_id`, inicialmente limitada a `Booking` e `SlotBlock`, sem associação polimórfica que carregue classes dinamicamente e sem foreign key. Não há `updated_at`, dependência de usuários nem integração automática de auditoria nesta etapa.

## Consequências

- Capacidade nominal de 80 posições diárias, sem pré-gerar registros de disponibilidade.
- Índices e constraints protegem cada tabela, inclusive contra gravações que ignorem validações Active Record.
- Cancelamento e reagendamento não consomem capacidade; liberação mantém a posição reservada.
- Uma operação antiga ainda aberta impede nova ocupação física da mesma doca, independentemente da data/janela.
- A referência genérica da auditoria pode apontar para entidade ausente; isso permite preservar o histórico de bloqueios removidos. A consistência e a escrita transacional da auditoria deverão ser tratadas pelos fluxos futuros.
- Auditoria é conceitualmente append-only; impedir efetivamente alterações/exclusões ainda depende de requisito operacional. Não foram adicionados métodos próprios de alteração ou exclusão.
- Índices independentes não impedem sobreposição entre `bookings` e `slot_blocks`. Essa proteção compartilhada deverá ser implementada e testada antes de liberar funcionalidades operacionais. Não há triggers, funções PL/pgSQL ou advisory locks neste RF.

## Alternativas consideradas

Cadastros de docas/janelas, estrutura de usuários antecipada e mecanismo transacional compartilhado entre reservas/bloqueios foram excluídos pelo RF002. As ADRs 0001–0003 permanecem vigentes.
