# Banco de dados — DSV Doca Agenda

A estrutura inicial do RF002 continha `bookings`, `slot_blocks` e `audit_events`. O RF015 adicionou `users`; consulte [colunas, índices, constraints e diagrama](schema.md) e as ADRs pertinentes.

O formato oficial do snapshot é SQL (`db/structure.sql`), para preservar a trigger append-only da auditoria. Migrations e testes foram executados no PostgreSQL.

## Valores fixos do domínio

`lib/agenda_definition.rb` centraliza oito docas numéricas de 1 a 8 e dez janelas. O zero à esquerda das docas será apenas apresentação. Não haverá cadastro de docas ou janelas nem registros prévios de disponibilidade. Capacidade nominal: 80 posições por dia. O formulário público usa docas 1–3 para entrega e 4–8 para coleta; o backend valida a mesma distribuição.

| Janela | Início | Fim |
| --- | --- | --- |
| 01 | 08:00 | 09:00 |
| 02 | 09:00 | 10:00 |
| 03 | 10:00 | 11:00 |
| 04 | 11:00 | 12:00 |
| 05 | 12:00 | 13:00 |
| 06 | 13:00 | 14:00 |
| 07 | 14:00 | 15:00 |
| 08 | 15:00 | 16:00 |
| 09 | 16:00 | 17:00 |
| 10 | 17:00 | **17:48** |

A última janela tem 48 minutos. O RF002 prevalece sobre a quantidade antiga de sete docas da especificação, que foi preservada como referência histórica.

## Preparação e validação

Primeiro resolva as pendências do [RF001](../requisitos/RF001%20%E2%80%94%20Funda%C3%A7%C3%A3o%20da%20aplica%C3%A7%C3%A3o%20e%20prepara%C3%A7%C3%A3o%20do%20ambiente%20de%20desenvolvimento.md): Docker/rede, instalação de gems e lockfile. Os comandos abaixo pressupõem `.env` local configurado, imagens construídas e serviços em execução, conforme o README da raiz.

```sh
docker compose ps
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:migrate:status
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec web bin/rails test
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit check --update
```

Migrations, em ordem: `20261125130000_create_bookings.rb`, `20261125130100_create_slot_blocks.rb`, `20261125130200_create_audit_events.rb`. Todas utilizam `ActiveRecord::Migration[8.1]` e `change` reversível. Não executam operações destrutivas sobre dados existentes; não use rollback das tabelas depois de armazenar dados sem avaliar o impacto.

O Rails gera `db/schema.rb` com `db:migrate`. Se necessário, execute `docker compose exec web bin/rails db:schema:dump`, revise e versione o resultado. Não escreva o schema para simular uma migration executada.

### Recriar a estrutura sem alterar o banco existente

Valide as migrations em um banco novo com nome exclusivo, mantendo as mesmas credenciais locais. Exemplo, depois de confirmar que o nome abaixo não está em uso:

```sh
docker compose exec -e POSTGRES_DB=dsv_rf002_disposable_20261125 web bin/rails db:prepare
docker compose exec -e POSTGRES_DB=dsv_rf002_disposable_20261125 web bin/rails db:migrate:status
docker compose exec -e POSTGRES_DB=dsv_rf002_disposable_20261125 -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec -e POSTGRES_DB=dsv_rf002_disposable_20261125 web bin/rails test
```

A suíte usa o banco separado `dsv_rf002_disposable_20261125_test`. Não reutilize esse nome se já existir; escolha outro identificador exclusivo. Não execute `db:drop`, `db:reset` ou remoção de volumes sobre o ambiente existente. A limpeza desses bancos deve ser tratada separadamente depois da validação.

## Integridade e testes

Os testes de estrutura inspecionam tipos, tamanhos, obrigatoriedade, defaults, índices e constraints validadas. Os testes de constraints usam SQL com parâmetros vinculados, sem validações ou coerções dos models, inclusive para verificar NULL em `lock_version`. A maioria dos dados de preparação é inserida por `insert_all!`, sem callbacks.

A classe de concorrência desabilita transações automáticas apenas para seus dois testes. Duas conexões independentes iniciam transações, disputam o mesmo índice e aguardam confirmação por filas. Uma terceira conexão observa a contenção via `pg_blocking_pids`; os testes só passam se exatamente uma transação confirmar e a outra receber `RecordNotUnique`. Há limites de espera no PostgreSQL, nas filas e nas threads. A limpeza afeta somente os protocolos aleatórios gerados por esses testes. O pool padrão de três conexões do RF001 atende essa estratégia.

Não usar SQLite como substituto do PostgreSQL. A suíte completa também inclui a regressão do RF001.

## Persistência, limites e próximos requisitos

- PostgreSQL é a fonte de verdade; `postgres_data` mantém o cluster persistente após recriação de containers. A porta do banco permanece sem publicação no host.
- Datas operacionais são `date`. Timestamps Rails têm precisão de microssegundos e persistência em UTC; o fuso operacional continua `America/Sao_Paulo`.
- O RF003 implementa criação pública, protocolo aleatório, idempotência por UUID, normalização de placa, horizonte de três dias e consulta de disponibilidade. Não há validação fiscal de NF-e, feriados ou transições operacionais de estado.
- Reservas e bloqueios ainda podem coincidir entre tabelas. **A proteção transacional compartilhada é obrigatória antes de disponibilizar os fluxos operacionais.** Não foi simulada por testes que pressupõem sua existência.
- A auditoria não tem foreign key convencional nem associação que carregue classes. Seus tipos são restritos a `Booking`, `SlotBlock` e `User`. O histórico pode sobreviver à remoção da entidade referida.
- Os fluxos dos RF003–RF008 gravam auditoria na transação de negócio. Desde o RF011, UPDATE e DELETE em eventos são impedidos pelo PostgreSQL; consultas e novos eventos continuam disponíveis.
- Usuários e perfis cadastrais existem desde RF015. O RF016 adicionou sessões persistidas, autorização efetiva, limitação de login e identificação histórica do operador.
- Sessões expiradas/revogadas são removidas após 30 dias e tentativas técnicas após um dia pelo worker. Usuários e eventos de auditoria não são excluídos. Seeds não criam dados de negócio.
- A área administrativa possui controle de acesso, mas a publicação em produção permanece bloqueada por padrão até RF017/RF018.

## Usuários — RF015

A tabela `users` e os checks/índices estão descritos em [schema.md](schema.md). Crie o primeiro administrador pelo console interativo, após iniciar os serviços:

```sh
docker compose exec web bin/rails users:bootstrap_admin
```

Use um terminal interativo; a senha e a confirmação são lidas sem eco. A tarefa não sobrescreve nenhum administrador existente. Nenhum usuário é criado automaticamente. O primeiro login exige troca de senha.

## Sessões e tentativas de login — RF016

`sessions` guarda somente SHA-256 do token opaco, usuário, criação, última atividade, expiração absoluta, revogação e user agent limitado. O token original fica apenas no cookie protegido. A foreign key para `users` usa `RESTRICT`; índices cobrem token, usuário, expiração e revogação.

`login_attempts` guarda chaves SHA-256 de e-mail normalizado ou IP, tipo e instante. O PostgreSQL serializa contagens concorrentes com advisory locks. Os registros são técnicos e não substituem a auditoria append-only. A limpeza diária remove tentativas com mais de um dia e sessões 30 dias após expiração/revogação.

`audit_events` ganhou `actor_user_id`, `actor_name`, `actor_role` e `origin`. A FK do ator preserva integridade; nome e perfil preservam a apresentação histórica. Eventos antigos continuam com esses campos nulos. A trigger append-only não foi desabilitada para preencher histórico.


## Criação pública — RF003

`CreateBooking` consulta capacidade e bloqueios sob `AgendaCapacityLock`, preservando os índices existentes. Futuras alterações de capacidade precisam adquirir a mesma trava de posição (data/doca/janela) na transação. Escritores que não usam essa trava ainda podem causar conflito entre tabelas; não há garantia universal contra gravações SQL diretas. Consulte a [ADR 0006](../adr/0006-formulario-publico-e-criacao-transacional.md).

## Auditoria append-only — RF011

A migration `20261125140000_protect_audit_events` preserva os registros e instala a função/trigger que bloqueia UPDATE e DELETE. A estrutura oficial agora é `db/structure.sql`, pois `schema.rb` não representa triggers. O Rails usa os comandos habituais `db:migrate`, `db:schema:dump`, `db:schema:load` e `db:prepare`, respeitando o formato SQL. **Carga de schema é somente para banco novo/isolado**, nunca para substituir um banco operacional existente. A imagem Rails inclui `postgresql-client` para dump/carga.

Não há limpeza automática ou retenção por idade. Eventos de reservas canceladas e bloqueios removidos continuam disponíveis. O trigger não impede que um proprietário/superusuário altere a estrutura ou execute TRUNCATE; a aplicação não oferece essas operações. Consulte a [ADR 0014](../adr/0014-historico-e-auditoria-append-only.md).

Manutenção excepcional deve ser autorizada e revisada, com backup e acesso privilegiado ao banco. Em janela de manutenção, o procedimento é:

```sql
BEGIN;
LOCK TABLE audit_events IN ACCESS EXCLUSIVE MODE;
ALTER TABLE audit_events DISABLE TRIGGER audit_events_append_only;
-- Executar exclusivamente a manutenção previamente autorizada e revisada.
ALTER TABLE audit_events ENABLE TRIGGER audit_events_append_only;
COMMIT;
```

Em erro, usar ROLLBACK. Não deixar a proteção desativada após a manutenção. Esse procedimento não deve ser chamado pela aplicação. O helper de limpeza dos testes usa esse mecanismo somente no banco de teste, durante a remoção dos dados fictícios identificados; os cenários e testes de integridade executam com o trigger ativo.
