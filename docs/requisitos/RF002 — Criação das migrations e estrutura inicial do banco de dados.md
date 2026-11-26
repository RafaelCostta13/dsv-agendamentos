# RF002 — Criação das migrations e estrutura inicial do banco de dados

## 1. Objetivo

Criar a estrutura inicial do banco de dados da aplicação
DSV Doca Agenda, utilizando PostgreSQL e migrations
nativas do Ruby on Rails.

Estabelecer uma base simples, consistente e segura para
o desenvolvimento dos próximos requisitos.

Neste requisito, implementar exclusivamente:

- Migrations.
- Models Active Record básicos.
- Colunas e tipos de dados.
- Índices.
- Constraints.
- Integridade dos dados.
- Testes da estrutura do banco.
- Documentação do banco de dados.

Não implementar funcionalidades operacionais.

Não implementar usuários, autenticação ou autorização.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/rails/SKILL.md
- .agents/skills/security/SKILL.md
- docs/adr/
- docs/requisitos/RF001 — Fundação da aplicação e preparação do ambiente de desenvolvimento.md
- docs/referencias/

Analisar a estrutura criada no RF001.

Preservar a arquitetura monolítica Ruby on Rails.

Utilizar exclusivamente o PostgreSQL como banco de dados.

Não reutilizar código da implementação descartada.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Simplificação da arquitetura

A aplicação possui oito docas físicas fixas.

As janelas de horários também são fixas.

Não será necessário criar tabelas específicas para
cadastrar docas ou janelas de horários.

Não criar as tabelas:

- docks
- time_slots
- users
- roles
- permissions
- sessions

Não implementar cadastros administrativos para docas
ou janelas de horários.

As definições operacionais fixas serão centralizadas
no backend Rails.

Não duplicar essas definições em JavaScript.

---

## 4. Tabelas iniciais

Criar exclusivamente as seguintes tabelas de negócio:

    bookings
    slot_blocks
    audit_events

Models correspondentes:

    Booking
    SlotBlock
    AuditEvent

As tabelas internas utilizadas pelo Rails deverão
ser preservadas.

Não adicionar entidades que não sejam necessárias
ao escopo deste requisito.

---

## 5. Convenções do banco de dados

Utilizar as convenções nativas do Rails:

- Nomes de tabelas em inglês.
- Nomes de tabelas no plural.
- Nomes de models no singular.
- Colunas em snake_case.
- Chaves primárias bigint.
- Timestamps conforme padrão Rails.
- PostgreSQL como banco oficial.
- Active Record como ORM.
- Migrations versionadas.
- Índices e constraints explícitos.

Manter o fuso operacional:

    America/Sao_Paulo

Armazenar timestamps em UTC.

Utilizar o tipo date para datas operacionais.

Não armazenar datas ou horários utilizando strings
quando existir um tipo de dado apropriado.

---

## 6. Docas físicas

A aplicação terá oito docas físicas.

Identificadores:

    01
    02
    03
    04
    05
    06
    07
    08

Utilizar valores numéricos de 1 a 8 no banco de dados.

O zero à esquerda será utilizado apenas na apresentação.

Nome do atributo:

    dock_number

Tipo:

    smallint

Adicionar check constraint permitindo somente valores
entre 1 e 8.

Não criar uma tabela de cadastro de docas.

Não definir neste requisito quais docas pertencem
ao recebimento ou à expedição.

A distribuição operacional será definida posteriormente.

A quantidade de oito docas substitui a quantidade
de sete docas presente na especificação original.

---

## 7. Janelas de horários

Utilizar as dez janelas fixas da especificação funcional.

    Janela 01 — 08:00 às 09:00
    Janela 02 — 09:00 às 10:00
    Janela 03 — 10:00 às 11:00
    Janela 04 — 11:00 às 12:00
    Janela 05 — 12:00 às 13:00
    Janela 06 — 13:00 às 14:00
    Janela 07 — 14:00 às 15:00
    Janela 08 — 15:00 às 16:00
    Janela 09 — 16:00 às 17:00
    Janela 10 — 17:00 às 17:48

A última janela possui duração de 48 minutos.

Não alterar o encerramento para 18:00.

Nome do atributo:

    slot_number

Tipo:

    smallint

Adicionar check constraint permitindo somente valores
entre 1 e 10.

Não criar tabela de cadastro de janelas.

Não criar registros de disponibilidade para cada
combinação de data, doca e janela.

A disponibilidade será calculada posteriormente
com base nos agendamentos e bloqueios existentes.

A capacidade nominal será de 80 posições por dia,
considerando oito docas e dez janelas.

---

## 8. Tabela bookings

### 8.1 Objetivo

Armazenar os agendamentos de coleta e entrega
de veículos.

Esta será a principal tabela operacional da aplicação.

### 8.2 Estrutura

Identificação:

    id              bigint
    protocol        varchar(50)
    request_id      uuid

Agendamento:

    booking_date    date
    dock_number     smallint
    slot_number     smallint
    operation       varchar(20)
    status          varchar(30)

Responsável pelo agendamento:

    contact_name    varchar(80)
    company         varchar(100)

Dados fiscais e veículo:

    invoice         varchar(44)
    plate           varchar(7)
    vehicle_model   varchar(80)

Controle operacional:

    checkin_at      timestamp
    released_at     timestamp
    release_remark  text
    change_reason   text

Controle técnico:

    lock_version    integer
    created_at      timestamp
    updated_at      timestamp

### 8.3 Campos obrigatórios

Configurar NOT NULL para:

- protocol
- request_id
- booking_date
- dock_number
- slot_number
- operation
- status
- contact_name
- company
- invoice
- plate
- vehicle_model
- lock_version
- created_at
- updated_at

Os campos de controle operacional deverão aceitar
valores nulos enquanto os respectivos eventos ainda
não tiverem ocorrido.

### 8.4 Valores padrão

Configurar:

    status = agendado
    lock_version = 0

Não definir valores padrão fictícios para:

- Protocolo.
- Nota fiscal.
- Placa.
- Responsável.
- Empresa.
- Operação.
- Doca.
- Janela.

### 8.5 Protocolo

O atributo protocol será utilizado futuramente como
identificador público do agendamento.

Criar índice único.

O protocolo deverá ser independente do ID interno.

Não implementar o gerador de protocolos neste RF.

### 8.6 Request ID

Utilizar o tipo UUID nativo do PostgreSQL.

Criar índice único.

O atributo será utilizado posteriormente para
garantir a idempotência das solicitações de
agendamento.

Não implementar o fluxo de idempotência neste RF.

### 8.7 Data do agendamento

Utilizar o tipo date.

Não implementar neste requisito:

- Horizonte de agendamento.
- Validação de datas futuras.
- Calendário operacional.
- Feriados.
- Dias úteis.

Essas regras serão implementadas posteriormente.

### 8.8 Nota fiscal

O atributo invoice deverá utilizar o tipo string.

Não utilizar:

- integer
- bigint
- float
- decimal

A nota fiscal deverá preservar zeros à esquerda.

Exemplo:

    000123456

Limitar o armazenamento a 44 caracteres.

Adicionar uma constraint para aceitar somente
sequências de 1 a 44 dígitos numéricos.

Não implementar validação fiscal de chave NF-e.

Não implementar múltiplas notas fiscais por reserva.

### 8.9 Placa

Armazenar a placa utilizando varchar(7).

A estrutura deverá suportar placas brasileiras
nos padrões antigo e Mercosul.

Exemplos:

    ABC1234
    ABC1D23

Armazenar futuramente os valores normalizados,
sem espaços ou hífens.

A normalização e as validações funcionais completas
serão implementadas em requisito posterior.

Não realizar consultas a serviços externos.

### 8.10 Responsável pelo agendamento

O atributo contact_name representa a pessoa que
realizou o agendamento.

Não representa necessariamente o motorista.

Não criar neste requisito campos de:

- CPF.
- CNH.
- Telefone.
- Documento de identidade.
- Cadastro de motorista.

### 8.11 Operação

Valores permitidos:

    entrega
    coleta

Adicionar check constraint no PostgreSQL.

Não permitir valores diferentes dos definidos.

Não implementar compatibilidade entre operação
e número da doca neste requisito.

### 8.12 Status

Valores permitidos:

    agendado
    em_operacao
    liberado
    cancelado
    reagendamento

Adicionar check constraint no PostgreSQL.

Não utilizar valores numéricos implícitos para
representar os estados.

Os valores armazenados deverão ser explícitos.

Não implementar as transições entre estados
neste requisito.

### 8.13 Controle de concorrência

Utilizar lock_version conforme o mecanismo nativo
de optimistic locking do Active Record.

Tipo:

    integer

Valor padrão:

    0

Obrigatório.

Adicionar constraint impedindo valores negativos.

Não criar mecanismos paralelos de versionamento.

### 8.14 Horários operacionais

Os atributos checkin_at e released_at representam
os horários efetivos dos eventos operacionais.

Adicionar proteção estrutural para impedir:

- Liberação sem horário de check-in.
- Liberação anterior ao horário de check-in.

Uma reserva com status em_operacao deverá possuir
checkin_at preenchido.

Uma reserva com status liberado deverá possuir:

- checkin_at
- released_at
- release_remark com 3 a 500 caracteres úteis.

Não implementar as ações de check-in e liberação.

---

## 9. Integridade dos agendamentos

### 9.1 Capacidade por doca e janela

Uma combinação de:

- booking_date
- dock_number
- slot_number

não poderá possuir mais de uma reserva que
consuma capacidade.

Estados que consomem capacidade:

- agendado
- em_operacao
- liberado

Estados que não consomem capacidade:

- cancelado
- reagendamento

Criar índice único parcial no PostgreSQL.

Estrutura conceitual:

    CREATE UNIQUE INDEX bookings_active_slot_unique
    ON bookings (
        booking_date,
        dock_number,
        slot_number
    )
    WHERE status IN (
        'agendado',
        'em_operacao',
        'liberado'
    );

Utilizar as migrations Rails para criar o índice.

O PostgreSQL deverá impedir a duplicidade mesmo
quando duas transações ocorrerem simultaneamente.

Não depender exclusivamente de validações
do Active Record.

### 9.2 Histórico

Agendamentos cancelados ou em reagendamento poderão
possuir a mesma combinação histórica de data,
doca e janela de outros registros.

Não excluir esses registros.

Uma reserva liberada deverá continuar consumindo
a janela originalmente reservada.

### 9.3 Ocupação física

Uma doca física poderá possuir somente um veículo
com status em_operacao.

Criar índice único parcial utilizando dock_number.

Estrutura conceitual:

    CREATE UNIQUE INDEX bookings_dock_occupation_unique
    ON bookings (dock_number)
    WHERE status = 'em_operacao';

A proteção deverá considerar todas as datas
e todas as janelas.

Uma operação antiga ainda não liberada deverá
impedir outra operação simultânea na mesma doca.

Não implementar a lógica operacional neste RF.

---

## 10. Tabela slot_blocks

### 10.1 Objetivo

Armazenar bloqueios de posições específicas
da agenda.

Cada registro representa uma combinação de:

- Data.
- Doca.
- Janela.

### 10.2 Estrutura

    id              bigint
    blocked_date    date
    dock_number     smallint
    slot_number     smallint
    reason          varchar(250)
    created_at      timestamp
    updated_at      timestamp

### 10.3 Campos obrigatórios

Configurar NOT NULL para:

- blocked_date
- dock_number
- slot_number
- created_at
- updated_at

O motivo poderá ser opcional.

### 10.4 Constraints

Permitir somente:

    dock_number entre 1 e 8
    slot_number entre 1 e 10

Criar índice único composto utilizando:

    blocked_date
    dock_number
    slot_number

Não permitir dois bloqueios para a mesma posição.

### 10.5 Usuários

Não adicionar neste momento:

- user_id
- created_by_id
- blocked_by_id

Não criar foreign keys para uma tabela users
que ainda não existe.

A identificação do responsável será adicionada
posteriormente através de uma nova migration,
quando a autenticação for implementada.

### 10.6 Fora do escopo

Não implementar:

- Bloqueio em lote.
- Desbloqueio em lote.
- Interface de bloqueios.
- Validação de bloqueios futuros.
- Serviços operacionais de bloqueio.

---

## 11. Integridade entre reservas e bloqueios

A aplicação não deverá permitir que uma posição
da agenda possua simultaneamente:

- Uma reserva que consome capacidade.
- Um bloqueio operacional.

Entretanto, bookings e slot_blocks são tabelas
diferentes.

Os índices únicos independentes dessas tabelas
não garantem essa proteção entre elas.

Neste RF, criar somente as estruturas individuais
e suas respectivas constraints.

Não implementar triggers, funções PL/pgSQL,
advisory locks ou mecanismos complexos de
concorrência entre tabelas neste momento.

Registrar essa pendência na documentação do banco.

A proteção transacional compartilhada entre
reservas e bloqueios deverá ser implementada
e testada antes de disponibilizar as respectivas
funcionalidades operacionais.

Não considerar essa garantia como implementada
apenas pela existência dos índices individuais.

---

## 12. Tabela audit_events

### 12.1 Objetivo

Preparar uma estrutura simples para armazenamento
do histórico das operações da aplicação.

A auditoria deverá ser utilizada futuramente para:

- Criação de agendamentos.
- Alteração de agendamentos.
- Cancelamentos.
- Reagendamentos.
- Check-in.
- Liberação.
- Bloqueio.
- Desbloqueio.

### 12.2 Estrutura

    id              bigint
    entity_type     varchar(50)
    entity_id       bigint
    action          varchar(50)
    previous_values jsonb
    new_values      jsonb
    reason          text
    created_at      timestamp

### 12.3 Campos obrigatórios

Configurar NOT NULL para:

- entity_type
- entity_id
- action
- created_at

Os atributos previous_values, new_values e reason
poderão aceitar valores nulos.

### 12.4 JSONB

Utilizar o tipo JSONB nativo do PostgreSQL.

Os campos serão utilizados futuramente para
armazenar os valores anteriores e posteriores
de uma alteração.

Exemplo conceitual:

    previous_values:
        dock_number: 1
        slot_number: 3

    new_values:
        dock_number: 2
        slot_number: 5

Não armazenar JSON serializado em campos text.

### 12.5 Entidades auditadas

Prever inicialmente:

    Booking
    SlotBlock

Adicionar índice composto:

    entity_type
    entity_id

Não utilizar nomes arbitrários de classes
fornecidos pelo navegador.

Não implementar carregamento dinâmico de classes
com base em dados externos.

A referência genérica entity_type e entity_id
não possui foreign key convencional.

Documentar essa limitação.

O histórico de um bloqueio deverá permanecer
disponível mesmo após seu desbloqueio.

### 12.6 Usuários

Não adicionar:

- user_id
- actor_id
- Foreign keys relacionadas à autenticação.

A identificação individual de operadores será
implementada futuramente.

### 12.7 Preservação

Os registros de auditoria serão tratados
conceitualmente como append-only.

Não implementar métodos de alteração ou exclusão
de eventos de auditoria.

Não adicionar updated_at, pois os eventos não
deverão ser editados pelas funcionalidades comuns.

Não implementar callbacks automáticos de auditoria.

Não implementar serviços de auditoria neste RF.

A proteção efetiva contra alterações indevidas e
a gravação transacional da auditoria deverão ser
implementadas junto aos respectivos fluxos.

---

## 13. Índices

### 13.1 Bookings

Criar:

- Índice único para protocol.
- Índice único para request_id.
- Índice para booking_date.
- Índice único parcial de capacidade.
- Índice único parcial de ocupação física.

### 13.2 Slot blocks

Criar:

- Índice único composto por blocked_date,
  dock_number e slot_number.

### 13.3 Audit events

Criar:

- Índice composto por entity_type e entity_id.

Avaliar a necessidade de índices adicionais
somente quando existirem consultas que os justifiquem.

Não criar índices duplicados.

Não realizar otimizações prematuras.

---

## 14. Models Active Record

Criar os models:

    app/models/booking.rb
    app/models/slot_block.rb
    app/models/audit_event.rb

Os models deverão utilizar a estrutura padrão
do Rails.

Neste requisito, manter os models simples.

Implementar apenas declarações necessárias para:

- Representação das tabelas.
- Atributos.
- Compatibilidade com optimistic locking.
- Validações estruturais básicas.

Não implementar:

- Services.
- Workflows.
- State machines.
- Callbacks complexos.
- Concerns.
- Consultas operacionais.
- Regras de disponibilidade.
- Autenticação.
- Autorização.

As constraints do PostgreSQL deverão permanecer
como proteção estrutural dos dados.

---

## 15. Migrations

Criar migrations independentes e organizadas.

Ordem sugerida:

    CreateBookings
    CreateSlotBlocks
    CreateAuditEvents

Utilizar a versão de migrations correspondente
à versão do Rails instalada no RF001.

Priorizar os recursos nativos:

- create_table
- add_index
- add_check_constraint
- timestamps

Utilizar SQL específico do PostgreSQL somente
quando necessário.

As migrations deverão:

- Ser reproduzíveis.
- Ser reversíveis quando possível.
- Possuir responsabilidades claras.
- Criar todos os índices previstos.
- Criar todas as constraints previstas.
- Executar corretamente no PostgreSQL.

Não modificar migrations anteriores.

Não alterar manualmente o schema para simular
a execução de uma migration.

Gerar o schema através dos comandos nativos
do Rails.

Não executar operações destrutivas em bancos
existentes.

---

## 16. Seeds

Não criar dados operacionais nos seeds.

Não criar:

- Usuários.
- Agendamentos.
- Bloqueios.
- Eventos de auditoria.
- Docas.
- Janelas de horários.

As docas e janelas são valores fixos do domínio
e não registros de cadastro.

Preservar o arquivo db/seeds.rb sem dados
fictícios de negócio.

Utilizar fixtures ou mecanismos de preparação
de dados exclusivamente no ambiente de teste.

---

## 17. Preservação do histórico

Não implementar exclusão automática de registros.

Não implementar retenção de 72 horas.

Não adicionar campos como:

- expires_at para reservas.
- retention_hours.
- deleted_at sem necessidade definida.

Não reutilizar registros antigos para representar
novos agendamentos.

Cada agendamento deverá possuir identidade própria.

A política definitiva de retenção será definida
em requisito posterior.

---

## 18. Segurança

Preservar todas as configurações do RF001.

Não criar novas rotas públicas.

Não criar controllers de negócio.

Não criar endpoints administrativos.

Não criar APIs.

Não criar views operacionais.

Não criar código JavaScript.

Não desabilitar proteções nativas do Rails.

Não alterar a Content Security Policy.

Não alterar as configurações de rede do Docker.

Não publicar a porta do PostgreSQL.

Não expor informações do banco através dos
endpoints de healthcheck.

A ausência de autenticação neste estágio não
autoriza a publicação da aplicação operacional
na Internet.

---

## 19. Testes automatizados

Utilizar Minitest e PostgreSQL.

Não utilizar SQLite para substituir o PostgreSQL
durante os testes.

### 19.1 Testes das migrations

Validar:

- Criação das três tabelas.
- Tipos das colunas.
- Campos obrigatórios.
- Valores padrão.
- Índices.
- Check constraints.

### 19.2 Testes de bookings

Validar:

- Protocolo único.
- Request ID único.
- Docas entre 1 e 8.
- Rejeição das docas 0 e 9.
- Janelas entre 1 e 10.
- Rejeição das janelas 0 e 11.
- Operações permitidas.
- Estados permitidos.
- Preservação dos zeros à esquerda da NF.
- Rejeição de NF com caracteres não numéricos.
- Controle de lock_version.
- Coerência entre check-in e liberação.

### 19.3 Testes de capacidade

Validar:

- Duas reservas agendadas no mesmo slot
  são impedidas.

- Uma reserva cancelada permite que outra
  utilize a mesma posição.

- Uma reserva em reagendamento permite que
  outra utilize a mesma posição.

- Uma reserva liberada continua consumindo
  a posição.

- Reservas em docas diferentes podem utilizar
  a mesma data e janela.

- Reservas em datas diferentes podem utilizar
  a mesma doca e janela.

### 19.4 Testes de ocupação física

Validar:

- Dois veículos em operação na mesma doca
  são impedidos.

- Dois veículos em operação em docas
  diferentes são permitidos.

- Uma operação não liberada de data anterior
  impede outra ocupação da mesma doca.

### 19.5 Testes de slot_blocks

Validar:

- Bloqueio válido.
- Rejeição de doca inválida.
- Rejeição de janela inválida.
- Rejeição de data nula.
- Rejeição de bloqueio duplicado.
- Limite do tamanho do motivo.

### 19.6 Testes de audit_events

Validar:

- Criação de evento.
- Campos obrigatórios.
- Armazenamento JSONB.
- Recuperação dos valores armazenados.
- Ausência de dependência da tabela users.

### 19.7 Testes das constraints

Validar as proteções diretamente no PostgreSQL,
inclusive ignorando as validações do Active Record.

Não testar somente as validações dos models.

Confirmar que o banco rejeita registros que
violem as constraints previstas.

Utilizar dados isolados no ambiente de teste.

### 19.8 Testes de concorrência

Testar os índices únicos parciais utilizando
conexões independentes e transações concorrentes.

Validar:

- Duas reservas disputando a mesma posição.
- Duas operações disputando a mesma doca.

Somente uma das operações incompatíveis poderá
ser confirmada.

Utilizar limites de espera para evitar testes
que permaneçam bloqueados indefinidamente.

Não implementar ainda testes de concorrência
entre bookings e slot_blocks como se essa
proteção já estivesse disponível.

### 19.9 Regressão

Executar todos os testes existentes do RF001.

Garantir que a criação das migrations não
comprometa o funcionamento da infraestrutura.

---

## 20. Execução e validação

Utilizar o ambiente Docker criado no RF001.

Verificar os containers:

    docker compose ps

Executar as migrations:

    docker compose exec web bin/rails db:migrate

Verificar o estado das migrations:

    docker compose exec web bin/rails db:migrate:status

Preparar o banco de teste utilizando o procedimento
definido no RF001.

Executar os testes:

    docker compose exec web bin/rails test

Executar as ferramentas de qualidade e segurança
já configuradas:

- RuboCop.
- Brakeman.
- Bundler Audit.

Não instalar ferramentas adicionais sem necessidade.

Validar a recriação da estrutura em um banco
descartável e independente.

Não executar:

    db:drop
    db:reset
    docker compose down -v

sobre o ambiente existente sem autorização.

Não remover volumes para solucionar problemas
de migrations.

---

## 21. Documentação

Criar o diretório:

    docs/database/

Criar os arquivos:

    docs/database/README.md
    docs/database/schema.md

Documentar:

- Tabelas existentes.
- Colunas.
- Tipos.
- Campos obrigatórios.
- Valores padrão.
- Índices.
- Constraints.
- Diagrama da estrutura.
- Estratégia de persistência.
- Proteções contra duplicidade.
- Limitações atuais.
- Pendências futuras.

Registrar que:

- Existem oito docas físicas fixas.
- Existem dez janelas fixas.
- Não haverá cadastro de docas.
- Não haverá cadastro de janelas.
- Usuários serão implementados posteriormente.
- Autenticação será implementada posteriormente.
- Autorização será implementada posteriormente.
- A distribuição das docas por operação ainda
  não foi definida.
- A proteção entre reservas e bloqueios ainda
  deverá ser implementada.
- A auditoria operacional ainda deverá ser
  integrada às transações de negócio.

Registrar a simplificação da arquitetura de dados
em uma ADR.

Utilizar a próxima numeração disponível.

Registrar as decisões deste requisito em uma ADR objetiva em `docs/adr/`.
Não criar documento adicional de entrega em `docs/requisitos/`.

Atualizar o índice de requisitos e o README.

Preservar a especificação funcional original.

---

## 22. Critérios de aceite

### 22.1 Estrutura

- [ ] Tabela bookings criada.
- [ ] Tabela slot_blocks criada.
- [ ] Tabela audit_events criada.
- [ ] Models Active Record criados.
- [ ] Tipos de dados corretos.
- [ ] Campos obrigatórios configurados.
- [ ] Valores padrão configurados.
- [ ] Migrations executadas sem erros.
- [ ] Schema atualizado.

### 22.2 Docas e janelas

- [ ] Banco aceita docas de 1 a 8.
- [ ] Banco rejeita docas inválidas.
- [ ] Banco aceita janelas de 1 a 10.
- [ ] Banco rejeita janelas inválidas.
- [ ] Nenhuma tabela docks criada.
- [ ] Nenhuma tabela time_slots criada.
- [ ] Última janela documentada até 17:48.

### 22.3 Integridade

- [ ] Protocolos duplicados impedidos.
- [ ] Request IDs duplicados impedidos.
- [ ] Reservas duplicadas no mesmo slot impedidas.
- [ ] Ocupação simultânea da mesma doca impedida.
- [ ] Bloqueios duplicados impedidos.
- [ ] Estados inválidos impedidos.
- [ ] Operações inválidas impedidas.
- [ ] Controle de lock_version funcional.
- [ ] Zeros à esquerda da NF preservados.
- [ ] Histórico não excluído automaticamente.

### 22.4 Simplificação

- [ ] Nenhuma tabela users criada.
- [ ] Nenhuma tabela roles criada.
- [ ] Nenhuma tabela permissions criada.
- [ ] Nenhuma tabela sessions criada.
- [ ] Nenhuma autenticação implementada.
- [ ] Nenhuma autorização implementada.
- [ ] Nenhuma dependência relacionada a usuários
      adicionada às tabelas de negócio.
- [ ] Nenhuma interface operacional criada.
- [ ] Nenhum JavaScript criado.
- [ ] Nenhum trigger desnecessário criado.
- [ ] Nenhum dado fictício criado nos seeds.

### 22.5 Testes

- [ ] Testes das migrations executados.
- [ ] Testes dos models executados.
- [ ] Testes das constraints executados.
- [ ] Testes de capacidade executados.
- [ ] Testes de ocupação física executados.
- [ ] Testes de concorrência executados.
- [ ] Testes do RF001 continuam passando.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.

### 22.6 Documentação

- [ ] Estrutura do banco documentada.
- [ ] Índices documentados.
- [ ] Constraints documentadas.
- [ ] Diagrama criado.
- [ ] ADR registrada.
- [ ] Pendências de integridade documentadas.
- [ ] Decisões do RF002 registradas em ADR objetiva.
- [ ] README atualizado.

---

## 23. Fora do escopo

Não implementar neste requisito:

- Cadastro de usuários.
- Autenticação.
- Autorização.
- Login.
- Logout.
- Recuperação de senha.
- Sessões.
- Perfis.
- Permissões.
- Cadastro de docas.
- Cadastro de janelas.
- Cadastro de motoristas.
- Cadastro independente de veículos.
- Cadastro independente de transportadoras.
- Motor de disponibilidade.
- Serviços de agendamento.
- Formulário público.
- Dashboard.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- No-show.
- Bloqueio operacional.
- Desbloqueio operacional.
- Serviços de auditoria.
- QR Code.
- Notificações por e-mail.
- Exportação Excel.
- Active Storage.
- Upload de documentos.
- APIs.
- JavaScript.
- Alterações de layout.
- Implantação em produção.

O objetivo deste RF é exclusivamente estabelecer
a estrutura inicial do banco de dados.

---

## 24. Entrega

Registrar somente uma ADR objetiva em `docs/adr/`, criando ou atualizando
uma ADR pertinente ao requisito, com contexto, decisão e consequências relevantes.
Não criar relatório de implementação, registro paralelo do RF, inventário de arquivos
ou reprodução dos critérios de aceite em outro documento.

Na resposta final, informar brevemente o que mudou, os testes executados
e eventuais impedimentos reais. Não inventar resultados nem declarar
concluída uma validação que não foi executada.

---

## 25. Regra de parada

Ao concluir o RF002, PARE.

Não implementar funcionalidades operacionais.

Não implementar usuários.

Não implementar autenticação ou autorização.

Não iniciar o desenvolvimento das interfaces.

Não avançar automaticamente para o RF003.

Aguardar homologação da estrutura do banco de dados.