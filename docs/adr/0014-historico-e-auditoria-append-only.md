# ADR 0014 — Histórico e auditoria append-only

## Status

Implementada e validada por testes automatizados no RF011; aguardando homologação manual do responsável.

## Decisão

Adicionar **Histórico** à navegação, com GET `/admin/audit_events` e `/admin/audit_events/:id`, somente em development/test. A consulta geral ordena por `created_at DESC, id DESC`, permite período do evento no fuso de Brasília, ação, entidade permitida e protocolo exato normalizado. O período usa início inclusivo e início do dia seguinte exclusivo. O parâmetro `booking_protocol` evita a opção reservada `protocol` dos helpers de URL Rails. Filtros e paginação permanecem em GET, sem ações de edição/exclusão ou gravações de consulta.

`Admin::AuditPage` limita a 25 eventos por página e carrega os protocolos associados em uma única consulta. O índice existente `(entity_type, entity_id)` é reutilizado; não foi demonstrada necessidade de índice adicional. A página de detalhes da reserva recebe uma linha do tempo paginada, em ordem crescente por horário/ID, limitada àquela entidade e reserva. A tabela geral usa três consultas quando há referências a agendamentos: contagem, página de eventos e referências agrupadas, sem N+1.

Helpers e partials compartilhados centralizam nomes, ícones Unicode, cores, origens e comparação. Diferenciar alteração e reagendamento somente quando os estados históricos permitem; caso contrário, usar descrição genérica. A origem corresponde aos caminhos de escrita conhecidos e aos snapshots compatíveis; eventos insuficientes ou desconhecidos não recebem uma origem inventada. Não há atribuição individual de operador.

Somente campos operacionais conhecidos dos snapshots são apresentados. Não há JSON bruto nem exposição automática de atributos desconhecidos, dados pessoais ou campos técnicos. Ausência histórica aparece como **Não registrado**, sem reconstrução com a posição atual. O protocolo atual pode identificar a referência da reserva, sem preencher os valores históricos. Eventos de desbloqueio usam os valores anteriores e permanecem consultáveis após a remoção do bloqueio. Lotes continuam sendo eventos individuais, sem agrupamentos presumidos. Motivos e observações usam escaping e texto legível.

## Proteção no PostgreSQL

A migration `20261125140000_protect_audit_events` cria função e trigger `audit_events_append_only`, que rejeita UPDATE e DELETE por linha, inclusive SQL e operações em lote. INSERT e SELECT permanecem disponíveis. Não há bypass por parâmetro, variável de sessão ou funcionalidade administrativa. Nenhuma auditoria existente é alterada, e os services transacionais continuam gravando seus próprios eventos como antes.

Usar `config.active_record.schema_format = :sql` e `db/structure.sql`: o dump Ruby não preserva triggers PostgreSQL. O snapshot `db/schema.rb` foi substituído pelo SQL gerado. O pacote `postgresql-client` fornece `pg_dump`/`psql` para os comandos nativos de dump/carga do Rails, inclusive novas instalações. Nenhuma gem, tabela de negócio, coluna, constraint ou índice existente foi substituído.

Essa proteção não torna o histórico absolutamente imutável perante o proprietário/superusuário do banco. Privilégios superiores podem desabilitar/remover o trigger, executar TRUNCATE ou alterar a estrutura. Manutenção autorizada exige backup, janela exclusiva, transação com trava exclusiva da tabela e reativação do trigger antes do commit; não faz parte dos fluxos da aplicação. Não há exclusão por idade, expiração ou política nova de retenção.

## Validação

Suíte completa: **228 testes, 3.047 assertions, zero falhas, erros ou skips**. Os onze testes novos cobrem filtros, limites do dia em São Paulo, paginação de 62 eventos, ordenação, três consultas agrupadas, comparação, dados incompletos, escaping, eventos removidos, no-shows sucessivos, consulta sem efeitos colaterais e restrição de ambiente. A proteção foi exercitada por updates/deletes de instância e em lote, rollback de transação e restauração do SQL em schema PostgreSQL isolado, onde o trigger também impediu DELETE.

Os testes anteriores de concorrência mantiveram suas verificações. Somente a limpeza dos dados fictícios foi adaptada, por helper restrito a Rails test: transação, trava exclusiva, desativação do trigger apenas durante a limpeza direcionada e reativação antes de encerrar. A proteção fica ativa durante a execução dos testes.

RuboCop: 19 arquivos sem infrações. Brakeman: zero avisos. Gemfile/lockfile não foram alterados; Bundler Audit não foi repetido. Não houve validação manual de navegador ou screenshots, conforme orientação do responsável. O diretório permanece sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`).
