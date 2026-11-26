# ADR 0010 — Bloqueios transacionais de capacidade

## Status

Implementada e validada localmente no RF007; aguardando homologação.

## Contexto

Bloqueios precisam disputar a mesma capacidade das reservas e permitir operações em lote sem gravação parcial, alteração silenciosa de motivos ou remoção baseada em uma consulta desatualizada.

## Decisão

Adicionar a gestão em `/admin/slot_blocks`, disponível somente em development/test, pelo menu **Bloqueios**. Seleção, revisão e confirmação usam formulários HTML nativos, CSRF e Strong Parameters, sem JavaScript ou mudança de CSP. `BlockSelection` normaliza seleções duplicadas, limita os valores recebidos e reutiliza os instantes de `AgendaDefinition` em America/Sao_Paulo para horizonte e início estritamente futuro. Motivo é opcional, aparado e limitado a 250 caracteres; permanece restrito ao administrativo e à auditoria.

`BlockSlots` adquire as travas compartilhadas de `AgendaCapacityLock`, ordenadas por data/doca/janela, e reconsulta reservas e bloqueios na transação. Reservas agendadas, em operação ou liberadas rejeitam o lote inteiro. Bloqueios existentes permanecem intactos, inclusive motivo e timestamps; somente novas posições produzem registros e eventos `block`. Falhas de persistência ou auditoria revertem todo o lote. Os escritores de reservas do RF003/RF006 já usam as mesmas chaves e namespace.

`UnblockSlots` recebe confirmações assinadas com ID e revisão dos valores persistidos, incluindo timestamps em microssegundos, com finalidade específica e validade de duas horas. Não é necessário adicionar coluna de versão. Depois das travas de posição, recarrega e trava os registros, compara as revisões e revalida a elegibilidade temporal. Registro ausente, alterado ou confirmação inválida rejeita toda a seleção. O DELETE individual também exige correspondência com o ID da rota. A transação registra `unblock` com os valores originais antes da remoção, preservando a auditoria independente do registro removido. Reservas existentes continuam ocupando capacidade; remover um bloqueio não declara automaticamente a posição disponível.

A listagem oferece filtros por data/doca e paginação de 25 registros. Selecionar todos significa somente os elegíveis da página exibida, explicitamente indicado na tela. Registros históricos continuam consultáveis sem ação de desbloqueio. A matriz administrativa utiliza os bloqueios já carregados para consultar seus motivos, mantendo as duas consultas agrupadas do dashboard.

## Consequências e limites

Nenhuma migration, dependência ou regra operacional adicional. Permanecem oito docas, dez janelas e o horizonte existente. Motivos e tokens continuam filtrados dos logs. Não há autenticação provisória, no-show ou funcionalidades do próximo RF.

O protocolo fecha a concorrência entre os fluxos de reservas e bloqueios da aplicação. As constraints existentes protegem cada tabela; escritas SQL diretas ou futuros escritores que ignorem as travas compartilhadas ainda podem produzir sobreposição entre tabelas. Esta ADR complementa os limites registrados na ADR 0009, sem alegar uma constraint universal entre reservas e bloqueios.

## Validação

Suíte completa PostgreSQL: **182 testes, 2.306 assertions, zero falhas, erros ou skips**. Os 36 testes novos cobrem validações temporais, seleções, conflitos, atomicidade de auditoria/persistência, preservação de motivos, confirmação desatualizada, precisão temporal, paginação, CSRF habilitado, escaping, ambiente e idempotência pública. Seis testes de concorrência usam conexões independentes e observam contenção real no PostgreSQL: bloqueios duplicados, bloqueio/criação pública, bloqueio/alteração, bloqueio/reagendamento, desbloqueios concorrentes e lotes sobrepostos.

RuboCop: 78 arquivos sem infrações. Brakeman: zero avisos. Bundler Audit atualizado: nenhuma vulnerabilidade. Zeitwerk: carregamento válido.

Chromium validou bloqueio individual, lote de seis posições, conflito com reserva, desbloqueio individual, seleção completa de 80 posições, indisponibilidade pública, desbloqueio de 25 registros da página e preservação das demais páginas. Conferidos 87 eventos `block` e 26 `unblock`, reserva conflitante intacta e motivos ausentes no formulário público. Desktop, 390 px e 320 px sem overflow de página ou sobreposições; nenhuma violação de CSP, erro JavaScript ou falha inesperada de carregamento. O HTTP 409 do conflito foi esperado. Capturas em `tmp/rf007-screenshots/`.

Validação com dados fictícios no banco de teste e relógio controlado em servidor temporário, sem alterar o relógio do sistema ou reservas existentes. Somente os dados dessa validação foram removidos. O diretório continua sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`). Nenhuma pendência funcional identificada; aguarda homologação.
