# ADR 0009 — Cancelamento e reagendamento com capacidade

## Status

Implementada e validada localmente no RF006; aguardando homologação.

## Contexto

Gerenciar posições de reservas existentes exige liberar e adquirir capacidade sem perder o histórico, conflitar com check-in ou restaurar a posição antiga por um reenvio público.

## Decisão

Adicionar em development/test GET `/admin/bookings/:id/edit` e `cancellation`, e PATCH `reschedule` e `cancel`, em `Admin::BookingChangesController`. O cancelamento e o reagendamento permitem somente estados agendado/reagendamento. Nenhuma operação exclui reservas ou altera dados cadastrais, identidade, operação ou horários efetivos.

`BookingChangeRequest` normaliza o motivo (whitespace das extremidades; 3–500 caracteres) e valida posição pelo horizonte e instantes completos de `AgendaDefinition`. `BookingAvailability` aceita a exclusão interna do ID em edição; o formulário público não passa essa exclusão e continua vendo a posição como ocupada. Datas/docas consultam disponibilidade por navegação HTML nativa com PATCH sem gravação; o motivo e a versão recebidos são preservados. Antes da escrita há uma revisão com posição atual e selecionada. Não há JavaScript, API JSON ou alteração de CSP.

`ChangeBooking` reutiliza `AgendaCapacityLock` na ordem request → docas físicas ordenadas → posições ordenadas por data/doca/janela → registro. A posição original e o destino usam as mesmas chaves e namespace do RF003. A reserva é recarregada sob trava e o snapshot usado para localizar as travas deve continuar atual. Estado, versão recebida, horizonte, horário, bloqueios e reservas são revalidados. A ordem continua compatível com check-in/liberação (doca → registro). Erros de versão ou capacidade não são repetidos automaticamente.

O UPDATE da mesma reserva e a auditoria `cancel`/`reschedule` são atômicos. O motivo completo e os valores operacionais anteriores/posteriores ficam no evento; nenhum dado pessoal adicional é copiado. Cancelar muda status/motivo; mover mantém identidade e retorna ao estado agendado. O slot antigo só é liberado na transação que garante o destino. Uma reserva agendada sem mudança efetiva retorna “Nenhuma alteração foi realizada”, sem UPDATE ou auditoria, inclusive se sua posição já não for temporalmente elegível; isso não constitui nova reserva. Reagendamento exige posição elegível mesmo se coincidir com a anterior.

O replay do RF003 compara os dados cadastrais imutáveis do registro com a posição original do evento de criação. Para registros legados sem evento de criação, utiliza os valores anteriores do primeiro cancelamento/reagendamento. A consulta do registro existente ocorre sob request lock e row lock. O reenvio original devolve o mesmo registro no estado/posição atuais; dados incompatíveis geram conflito. Não há restauração, reativação ou novo evento. A auditoria existente é suficiente, sem snapshot de dados pessoais ou migration.

## Consequências e limites

Índices de capacidade, ocupação física e request ID continuam como proteção no PostgreSQL. Não há novas tabelas, migrations, índices ou dependências. Motivos e payloads anteriores/posteriores da auditoria são filtrados dos logs; Strong Parameters, CSRF, escaping, restrição de ambiente e controles do RF005 são preservados. A matriz e os indicadores existentes refletem o banco nas consultas normais.

O protocolo protege os escritores da aplicação que o utilizam. Escritas diretas ou futuros escritores de `slot_blocks` que ignorem a trava comum ainda podem produzir sobreposição entre tabelas; não há garantia universal por trigger. O futuro RF de bloqueios deverá adquirir as mesmas travas de posição e revalidar as reservas na transação. Não foram implementados bloqueios, no-show, autenticação ou histórico completo.

## Validação

Suíte PostgreSQL: 146 testes, 1.869 assertions, sem falhas, erros ou skips. Os 34 testes novos incluem sete disputas com conexões independentes e contenção observada no PostgreSQL: alterações pelo mesmo destino, alteração/criação pública, cancelamento/check-in, alteração/check-in, operações na mesma versão, cancelamentos duplicados e reagendamentos concorrentes. Também cobrem rollback, identidade, motivos, no-op, exclusão da própria reserva, datas/fuso, idempotência original, CSRF habilitado, XSS/SQL injection, ausência das rotas em produção e ocultação dos motivos nos logs SQL, inclusive nos payloads da auditoria.

RuboCop: 70 arquivos, sem infrações. Brakeman 8.1.1: zero avisos. Bundler Audit atualizado: nenhuma vulnerabilidade. Zeitwerk: carregamento válido. Chromium validou os fluxos de alteração com revisão, cancelamento e conflito de versão em contexto independente de sessão/CSRF. Validou também alternância entre as três datas após 14:30, preservação de motivo/versão, matriz e indicadores das datas envolvidas, rejeição direta de cancelamento em operação e manutenção do check-in/liberação. Screenshots em `tmp/rf006-screenshots/`, incluindo desktop, 390 px e 320 px; sem overflow de página, violações de CSP ou erros inesperados de console/rede. Os HTTP 409 das tentativas inválidas foram esperados e conferidos.

As operações usaram três reservas fictícias no banco de teste, com relógio controlado no servidor temporário, sem alteração do relógio do sistema. Confirmaram-se sete auditorias, IDs/protocolos preservados, capacidade correta e replay original sem restauração. Somente os dados desse teste foram removidos. Em development, os formulários de alteração/cancelamento também foram carregados no navegador, sem modificar as reservas existentes.

O diretório continua sem metadados Git utilizáveis: `git status --short` retorna `fatal: not a git repository`. Não há pendência funcional identificada; aguarda-se homologação sem avançar ao RF007.
