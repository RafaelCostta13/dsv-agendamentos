# DSV Doca Agenda

Monólito Rails para evolução incremental do agendamento de docas. O RF001 prepara somente a fundação: página ERB inicial, PostgreSQL e ambiente Docker. O RF002 adiciona a estrutura de reservas, bloqueios e auditoria; o RF003 implementa o agendamento público e o RF004, a consulta administrativa local; o RF005 adiciona check-in e liberação.

**Situação:** ambiente local operacional em Docker, com lockfile e suíte PostgreSQL executada. O painel administrativo e as operações do RF005 estão restritos a development/test, aguardando homologação local.

## Arquitetura e versões

Desenvolvimento: navegador → Puma/Rails em Docker → PostgreSQL em Docker.

| Componente | Versão definida |
| --- | --- |
| Ruby / imagem oficial | 3.4.13 / `ruby:3.4.13-slim` |
| Rails | 8.1.4.1 |
| Bundler | 2.6.2 |
| Puma | 8.0.5 |
| PostgreSQL / imagem oficial | 17.12 / `postgres:17.12-alpine` |
| Propshaft | 1.3.2 |
| Minitest | série 5, `~> 5.25`; patch pendente do lockfile |
| RuboCop | `rubocop-rails-omakase` 1.1.0; dependências pendentes do lockfile |
| Brakeman | 8.1.1 |
| Bundler Audit | 0.9.3 |
| Docker / Compose encontrados na sessão | 29.9.2 / v5.6.1 |

Ruby e Rails foram escolhidos após consultar as fontes oficiais: [Ruby 3.4.13](https://www.ruby-lang.org/en/news/2026/11/18/ruby-3-4-13-released/), [releases Rails](https://www.rubyonrails.org/releases), [compatibilidade Rails 8.1](https://guides.rubyonrails.org/8_1_release_notes.html) e [suporte PostgreSQL](https://www.postgresql.org/support/versioning/). Rails 8.1 requer Ruby >= 3.2. As versões configuradas ainda precisam ser instaladas e auditadas juntas; não há declaração de ausência de vulnerabilidades nas dependências.

Puma usa três threads por padrão, com pool do Active Record do mesmo tamanho. O fuso é `America/Sao_Paulo`, os timestamps são persistidos em UTC e o idioma padrão é `pt-BR`.

## Pré-requisitos

- Git e checkout com metadados `.git` utilizáveis.
- Docker com daemon acessível ao usuário e Docker Compose com suporte a `depends_on.condition: service_healthy`.
- Acesso de rede ao Docker Hub, repositórios Debian, RubyGems e GitHub para instalar e auditar dependências.
- Porta 3000 disponível, ou outra porta em `RAILS_PORT`.

Não é necessário instalar Ruby, PostgreSQL, Node.js ou Nginx no host.

## Configuração inicial

Na raiz do projeto, copie o exemplo **somente se ainda não houver um `.env`**:

```sh
cp .env.example .env
id -u
id -g
```

Edite `.env`: defina uma senha local e ajuste `LOCAL_UID` e `LOCAL_GID` pelos valores acima em Linux/WSL **antes do build**. Isso permite que o usuário não-root do container crie arquivos no bind mount sem alterar sua propriedade para root. Não sobrescreva configurações locais existentes.

Mantenha `POSTGRES_HOST=db`, `POSTGRES_PORT=5432` e `RAILS_ENV=development`. `RAILS_PORT` muda somente a porta publicada no host; Puma continua em `0.0.0.0:3000` dentro do container. Não é necessária `RAILS_MASTER_KEY` nesta fundação.

### Bootstrap do lockfile (somente se ausente)

O `Gemfile.lock` está presente e os builds usam as versões resolvidas em modo congelado. Os comandos abaixo são apenas para um novo bootstrap caso o lockfile esteja ausente; não são necessários no checkout atual:

```sh
docker compose config --quiet
docker compose build
docker compose run --rm --no-deps web bundle lock --local
docker compose build
```

O comando `bundle lock --local` grava no bind mount o conjunto resolvido e instalado no primeiro build. **Revise e versione `Gemfile.lock` antes de homologar o RF001.** Os builds seguintes detectam o lockfile e usam Bundler com `frozen=true`, rejeitando divergências com o Gemfile. Sem esse arquivo, a resolução transitiva do primeiro build ainda não é reproduzível.

### Preparar os bancos e iniciar

```sh
docker compose up -d db
docker compose run --rm web bin/setup
docker compose up -d
docker compose ps
```

O Compose aguarda o healthcheck do PostgreSQL antes dos comandos web. `bin/setup` executa `db:prepare` em development e test, em sequência. Não execute preparações/migrations em paralelo. O entrypoint não executa operações de banco, apenas remove PID antigo ao iniciar Puma e repassa os sinais ao processo com `exec`.

- Página inicial: http://localhost:3000/
- Processo Rails: http://localhost:3000/up
- Prontidão com consulta `SELECT 1`: http://localhost:3000/ready

Se mudar `RAILS_PORT`, ajuste os endereços. `/ready` retorna `ok` com HTTP 200 ou `unavailable` com HTTP 503, sem detalhes internos. A verificação de migrations do development é preservada nas páginas comuns e não intercepta os dois healthchecks. O healthcheck de web usa `/ready`; o de db usa `pg_isready` por TCP.

## Comandos de desenvolvimento

```sh
# Iniciar, encerrar sem excluir volumes e reiniciar
docker compose up -d
docker compose down
docker compose restart

# Estado e logs
docker compose ps
docker compose logs -f web db

# Console e migrations (um processo por vez)
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare

# Testes e qualidade
docker compose exec web bin/rails test
docker compose exec web bin/rubocop
docker compose exec web bin/brakeman --no-pager
docker compose exec web bin/bundler-audit check --update

# PostgreSQL: as variáveis são expandidas dentro do container
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

# Verificação HTTP
curl -i http://localhost:3000/
curl -i http://localhost:3000/up
curl -i http://localhost:3000/ready
```

`bin/ci`, dentro de web, prepara os bancos e executa os checks. O wrapper gerado de Brakeman mantém a verificação de versão mais recente; se exigir atualização, atualize a gem e o lockfile, sem desligar a checagem.

O bind mount `.:/rails` permite atualizar Ruby, ERB e CSS sem rebuild; development mantém reload habilitado. As gems ficam em `/usr/local/bundle`, fora desse mount. Não há JavaScript personalizado, frontend separado ou ferramentas Node.js.

Após alterar o Gemfile, atualize as gems e reconstrua a imagem:

```sh
docker compose run --rm --no-deps web bundle update NOME_DA_GEM
docker compose build
docker compose up -d
```

Revise o diff do lockfile e execute testes e auditoria. Para alterar Ruby ou Bundler, mantenha `.ruby-version`, Gemfile.lock e Dockerfile consistentes. Se a versão do Ruby mudar, atualize o lock dentro de uma imagem com a nova versão antes do build definitivo congelado.

## Banco e persistência

`config/database.yml` usa as mesmas variáveis do Compose e do `.env.example`. O banco development usa `POSTGRES_DB`; test usa **sempre** o nome derivado `${POSTGRES_DB}_test`. Não aponte a suíte para produção. Production tem configuração inicial sem credenciais reais e não foi iniciado.

- `postgres_data`: `/var/lib/postgresql/data`, conforme PostgreSQL 17. Nenhuma porta do banco é publicada no host.
- `rails_storage`: `/rails/storage`, preparado para futura implementação de Active Storage, sem instalação, migrations ou uploads neste RF.
- Código e logs: bind mount do diretório atual. Arquivos temporários, logs e documentos estão ignorados no Git e no contexto de build.

Os volumes sobrevivem a restart, down, recriação dos containers e rebuild. **Não execute `docker compose down -v` nem remova volumes sem autorização e backup.** Trocar usuário/senha em `.env` não altera automaticamente um cluster PostgreSQL já inicializado.

### Validação de persistência pendente

Em ambiente operacional, crie uma tabela descartável com nome exclusivo, por exemplo `rf001_persistence_probe_20261125`, após confirmar que esse nome está livre. Insira um marcador sem dados reais, execute `docker compose down` e `docker compose up -d`, consulte o marcador e remova somente a tabela de teste. Não remova volumes nem use tabelas de negócio.

## Segurança e produção

CSRF e escaping Rails são preservados. A CSP permite recursos locais e bloqueia scripts (`script-src 'none'`), objetos e frames ancestrais. Os filtros Rails ocultam parâmetros sensíveis dos logs; o healthcheck não retorna mensagens de exceção. Não há credenciais criptografadas necessárias nesta etapa. `.env`, chaves privadas, uploads e credenciais locais não entram no Git nem na imagem.

Em produção: Internet → **Nginx instalado diretamente na VPS** → Puma/Rails em Docker → PostgreSQL em Docker. O Nginx não integra o Compose. `compose.production.yaml` e `Dockerfile.production` são independentes do ambiente local. Consulte [docs/deploy](docs/deploy/README.md) para preparação manual da VPS, proxy, backup e rollback. Nenhum deploy é executado pelo repositório.


## Estrutura do banco — RF002

Foram escritas as migrations `CreateBookings`, `CreateSlotBlocks` e `CreateAuditEvents`, com models básicos, constraints e índices de unicidade, capacidade e ocupação física. A aplicação passa a definir oito docas fixas e dez janelas, com a última encerrando às 17:48. Não há tabelas de docas, janelas ou usuários.

Consulte a [documentação do banco](docs/database/README.md), o [schema documentado](docs/database/schema.md) e a [ADR 0004](docs/adr/0004-estrutura-de-dados-simplificada.md). As migrations foram aplicadas e testadas em PostgreSQL. Desde o RF011, o snapshot oficial é `db/structure.sql`, incluindo a proteção da auditoria.

As constraints protegem cada tabela individualmente. Os fluxos operacionais utilizam travas compartilhadas de capacidade e auditoria transacional, conforme as ADRs dos requisitos posteriores.


## Cadastro e gerenciamento de usuários — RF015

O menu **Usuários** permite ao administrador cadastrar e consultar usuários, alterar perfil, ativar/desativar contas e redefinir senhas. Os perfis `admin`, `operator` e `viewer` controlam o acesso efetivo desde o RF016. Em produção, as rotas permanecem indisponíveis enquanto `ADMIN_ACCESS_ENABLED` não for habilitado explicitamente após homologação.

Para criar o primeiro administrador, execute em terminal interativo:

```sh
docker compose exec web bin/rails users:bootstrap_admin
```

A senha e sua confirmação são solicitadas sem eco; use no mínimo 12 caracteres e no máximo 72 bytes. O comando não sobrescreve um administrador existente e não cria usuários por padrão. Nenhum administrador de desenvolvimento foi criado durante a implementação.

Consulte a [ADR 0016](docs/adr/0016-gerenciamento-seguro-de-usuarios.md) e a [estrutura de dados](docs/database/schema.md). RF013 e RF014 permanecem suspensos.


## Formulário público — RF003

Após atualizar o código, reinicie web (`docker compose restart web`) para carregar os novos diretórios de forms/services. Acesse `http://localhost:3000/agendar`. Preencha os dados, selecione data/doca e use **Atualizar horários** para consultar as janelas; a confirmação revalida disponibilidade e horário no servidor. Entrega usa docas 1–3 e coleta usa docas 4–8. Não há autenticação na área pública.

A [ADR 0006](docs/adr/0006-formulario-publico-e-criacao-transacional.md) descreve idempotência, locks compartilhados e confirmação. O logo oficial `DSV_Logo.svg` foi integrado ao cabeçalho. A suíte PostgreSQL inclui regressões de disponibilidade por data, concorrência, idempotência e segurança do formulário público.


## Painel administrativo — RF004

Após atualizar/reconstruir a imagem, execute `docker compose up -d` e acesse:

- `http://localhost:3000/` e `http://localhost:3000/admin`: Dashboard com data, indicadores e matriz de docas/janelas.
- `http://localhost:3000/admin/bookings`: lista com filtros GET por data, doca, operação e status, até 25 reservas por página.
- `/admin/bookings/:id`: detalhes e retorno ao contexto da consulta.

O painel permite consulta e ações operacionais após login. Em produção, as rotas ficam desabilitadas por `ADMIN_ACCESS_ENABLED=false` até autorização e homologação; autenticação e matriz de permissões permanecem ativas quando habilitadas. A atualização é manual, pelo botão **Atualizar**.

`Admin::Dashboard` usa duas consultas agrupadas para reservas e bloqueios. Reservas agendadas, em operação e liberadas compõem os indicadores; canceladas e em reagendamento aparecem somente na lista. Disponibilidade reutiliza a regra pública de data/horizonte/início de janela. Os dados carregados alimentam a matriz e os indicadores, sem consultas por célula. Sobreposições entre reserva ativa e bloqueio são sinalizadas como inconsistência.

O layout ERB administrativo e seu CSS são independentes do formulário público. Consulte a [ADR 0007](docs/adr/0007-painel-administrativo-de-consulta.md) para filtros, paginação, restrição de ambiente e validação.


## Check-in e liberação — RF005

Em **Agendamentos → Visualizar → Controle operacional**, selecione **Registrar check-in** e confirme a entrada. A reserva deve estar agendada para hoje, a janela deve ter começado, a doca precisa estar livre e o horário deve ser anterior a 17:30. Quando uma condição impedir a ação, os detalhes mostram o motivo.

Para uma reserva **Em operação**, selecione **Liberar doca**, informe a observação de 3 a 500 caracteres e confirme. A liberação funciona após o expediente e em outra data. Ela libera a doca física e mantém a capacidade da janela original consumida. Operações em andamento após o fim da janela recebem o destaque **Horário excedido**, sem encerramento automático.

Os comandos são PATCH `/admin/bookings/:id/checkin` e `/admin/bookings/:id/release`, precedidos por páginas de confirmação GET. Reserva e auditoria são atualizadas na mesma transação. Conflitos de versão exigem consultar novamente os detalhes. Datas e horários efetivos são definidos no servidor, em horário de Brasília. Em produção, o acesso administrativo depende da configuração explícita e autenticação/autorização do RF016.

Consulte a [ADR 0008](docs/adr/0008-checkin-e-liberacao-transacionais.md) para concorrência, auditoria e validação.


## Cancelamento, alteração e reagendamento — RF006

Em **Agendamentos → Visualizar → Controle operacional**, reservas agendadas oferecem **Alterar agendamento** e **Cancelar agendamento**; reservas em reagendamento oferecem **Reagendar** e cancelamento. Reservas em operação, liberadas ou canceladas não aceitam essas ações.

Para alterar, selecione a data, doca e janela, informe o motivo e use **Revisar alteração**. Compare a posição atual e a nova antes de confirmar. Trocar data ou doca atualiza as janelas e preserva o motivo e a versão; a consulta permanece na seção de seleção. O destino precisa estar livre e válido para hoje ou os próximos dois dias. A própria reserva é desconsiderada somente durante sua edição.

O cancelamento exige confirmação e motivo, mantém a reserva consultável e libera a capacidade quando a posição ainda é elegível. Alterar/reagendar mantém ID, protocolo, request ID e dados cadastrais. Motivos exigem 3–500 caracteres. Uma seleção sem mudanças em reserva agendada não grava atualização ou auditoria.

As rotas GET de formulário são `/admin/bookings/:id/edit` e `/admin/bookings/:id/cancellation`; os comandos PATCH são `/admin/bookings/:id/reschedule` e `/admin/bookings/:id/cancel`. Em conflito de versão, consulte os detalhes atualizados antes de tentar novamente. As ações existem apenas em development/test.

Reenvios da criação original preservam o estado e a posição atuais, sem criar outra reserva ou reativar cancelamentos. Consulte a [ADR 0009](docs/adr/0009-cancelamento-e-reagendamento-com-capacidade.md) para travas, auditoria e limites de integridade entre reservas e bloqueios.

## Bloqueio e desbloqueio — RF007

No menu **Bloqueios** (`/admin/slot_blocks`), selecione uma data, uma ou mais docas e janelas, informe o motivo opcional e revise antes de confirmar. Selecionar todas as docas e todos os horários de uma data futura permite bloquear as 80 posições. Qualquer reserva ativa conflitante rejeita o lote inteiro; bloqueios existentes e seus motivos são preservados.

A lista permite filtrar por data/doca, consultar motivos e desbloquear individualmente ou por seleção confirmada. **Selecionar todos os elegíveis desta página** abrange até 25 registros, sem incluir outras páginas. Somente posições futuras dentro do horizonte podem ser desbloqueadas. Se a seleção ficar desatualizada, consulte novamente antes de confirmar. Remover um bloqueio preserva a auditoria e mantém as demais regras de disponibilidade.

A matriz administrativa permite consultar o motivo de posições bloqueadas. As rotas permanecem restritas a development/test. Consulte a [ADR 0010](docs/adr/0010-bloqueios-transacionais-de-capacidade.md) para atomicidade, concorrência e validação.

## Atrasos e no-show automático — RF008

Uma reserva agendada após o fim da janela apresenta **Chegada atrasada**, sem perder a possibilidade de check-in na mesma data antes das 17:30, se a doca estiver livre. **Horário excedido** continua indicando uma operação em andamento que ultrapassou sua janela; a saída permanece manual, inclusive após o expediente ou em outra data.

Às **17:30 inclusive**, reservas de hoje sem check-in tornam-se elegíveis para **Reagendamento obrigatório**. Reservas de dias anteriores também são processadas; datas futuras e estados em operação, liberado, cancelado ou reagendamento são preservados. O worker executa a verificação imediatamente ao iniciar e a cada minuto, sem depender de acesso à aplicação. Cada alteração registra `no_show` e seu motivo na auditoria, preservando identidade e posição original.

O card **Reagendamentos pendentes** representa todas as datas. Seu link abre a lista filtrada por status, onde **Visualizar → Reagendar** reutiliza o RF006. A atualização visual continua manual. A posição original não fica automaticamente disponível, pois as regras temporais e de disponibilidade permanecem válidas.

Após atualizar o código, use `docker compose up -d --build web worker`. Não há migrations ou novas dependências. O worker compartilha a imagem Rails e o PostgreSQL, sem portas externas, Redis ou fila adicional. Reinicie-o quando alterar seu código (`docker compose restart worker`). Para diagnóstico:

```sh
docker compose ps
docker compose logs --tail=50 worker
docker compose restart worker
docker compose exec -T web bin/rails test
```

Logs registram início/encerramento, contagens de execuções com atividade e falhas técnicas, sem dados pessoais; ciclos vazios não geram mensagens de rotina. Em falha isolada, a transação daquela reserva é revertida e as demais continuam. Falhas são sinalizadas e reavaliadas no ciclo seguinte, sem retry imediato. Após indisponibilidade ou reinício, as reservas elegíveis persistidas são recuperadas sem duplicar auditorias. Consulte a [ADR 0011](docs/adr/0011-processamento-recorrente-de-no-show.md) para a estratégia e os testes automatizados. A validação manual fica com o responsável pelo projeto.

## Atualização automática do Dashboard — RF009

O Dashboard atualiza indicadores, matriz e alertas a cada **5 segundos**, respeitando a data selecionada. O botão **Atualizar** solicita uma consulta imediata. As outras páginas e formulários continuam sem polling. Datas e indicadores são calculados pelo Rails; o horário de **Última atualização** vem da resposta do servidor, em horário de Brasília.

Em falha, os últimos dados e seu horário são preservados com aviso visível. Cada consulta tem timeout de 10 segundos; novas tentativas usam intervalos de 5, 10, 20 e até 30 segundos. Após sucesso, o intervalo retorna a 5 segundos. Abas ocultas pausam o polling e o retomam imediatamente quando visíveis. Sair do Dashboard encerra o ciclo. Não há recarregamento completo da página, nem atualizações sobrepostas; respostas antigas são descartadas ao trocar de data.

GET `/admin/dashboard/refresh?date=AAAA-MM-DD` devolve o mesmo partial HTML da consulta inicial, sem cache ou gravações. O worker de no-show continua independente, a cada minuto. Somente o Dashboard autoriza seu script local por nonce específico; as demais páginas preservam o bloqueio de scripts. Não há novas dependências, migrations, containers ou portas. Reinicie web após atualizar o código (`docker compose restart web`).

Testes automatizados:

```sh
docker compose exec -T web bin/rails test
docker compose exec -T web bin/rails test test/system/dashboard_polling_test.rb
```

Os testes de sistema usam Chromium no ambiente de teste, sem Capybara, Node.js ou dependências frontend. Caso o executável não esteja disponível, instale-o **somente nesse ambiente** (`docker compose exec -T -u root web sh -c 'apt-get update -qq && apt-get install --no-install-recommends -y chromium'`) ou informe `CHROMIUM_BIN` ao executar os testes. A instalação temporária é perdida ao recriar o container; não integra a imagem da aplicação. Consulte a [ADR 0012](docs/adr/0012-polling-html-do-dashboard.md) para decisões, testes e limites da amostra de desempenho.

## Comprovante e QR Code — RF010

Após confirmar uma reserva, `/agendar/confirmacao` apresenta o comprovante com protocolo, operação, data, doca, janela, empresa, placa e QR Code. Salve uma captura para apresentação na chegada. O comprovante não substitui o check-in: entrada somente após o início da janela, antes das 17:30 e conforme disponibilidade física da doca. Use a impressão nativa do navegador para imprimir; a navegação é ocultada no papel.

O acesso público depende da sessão que confirmou a reserva, por **30 minutos sem renovação por atualização**. Não há busca pública por protocolo, ID, placa ou nota fiscal. **Realizar novo agendamento** abre um formulário limpo, com novo request ID, e encerra o acesso ao comprovante anterior nessa sessão. No administrativo, use **Agendamentos → Visualizar → Visualizar comprovante** para consultar o registro atual.

Alterar/reagendar preserva o protocolo e atualiza os dados e QR nas novas consultas. Reservas canceladas ou em reagendamento não apresentam confirmação ativa nem QR. Em operação e liberadas mostram seu estado sem sugerir nova entrada. Capturas antigas não se atualizam; o banco permanece a fonte de verdade.

O QR é um PNG gerado em Ruby com `rqrcode` 3.2.0. Contém somente destino, sistema, protocolo, operação, data, doca, janela e fuso; não inclui empresa, placa, documentos ou credenciais. A imagem é gerada sob demanda, sem arquivos permanentes ou chamadas externas. Não há leitura de QR, check-in automático ou PDF no servidor.

Após atualizar, execute `docker compose up -d --build web worker` para instalar a nova gem na imagem compartilhada. Não há migrations. Para os testes de decodificação, instale `zbar-tools` **somente no ambiente de teste** (ou configure `ZBARIMG_BIN`); os testes de layout usam Chromium, conforme RF009:

```sh
docker compose exec -T -u root web sh -c 'apt-get update -qq && apt-get install --no-install-recommends -y zbar-tools chromium'
docker compose exec -T web bin/rails test
docker compose exec -T web bin/rails test test/system
```

Esses utilitários não fazem parte da imagem da aplicação e precisam ser reinstalados caso o container de teste seja recriado. Consulte a [ADR 0013](docs/adr/0013-comprovante-temporario-e-qr-code.md) para acesso, privacidade, dependências e resultados. Leitura física e impressão manual ficam para homologação do responsável.

## Histórico e auditoria — RF011

No menu **Histórico**, consulte as operações, filtre por período do evento, tipo, entidade ou protocolo exato e use **Visualizar** para comparar valores anteriores/posteriores. A listagem exibe 25 eventos por página, com os mais recentes primeiro. Em **Agendamentos → Visualizar**, a seção **Histórico do agendamento** apresenta a linha do tempo paginada em ordem cronológica, inclusive motivos, observações e no-shows sucessivos.

Valores históricos não são substituídos pela posição atual da reserva. Dados ausentes ou origens desconhecidas são identificados como não registrados. Bloqueios removidos continuam consultáveis pela auditoria. Não há edição/exclusão de eventos. Desde o RF016, novas operações administrativas registram ID, nome e perfil históricos do operador; eventos anteriores permanecem sem atribuição individual.

Após atualizar, execute:

```sh
docker compose up -d --build web worker
docker compose exec -T web bin/rails db:migrate
docker compose exec -T -e RAILS_ENV=test web bin/rails db:migrate
docker compose exec -T web bin/rails test
```

O PostgreSQL impede UPDATE e DELETE em `audit_events`; novas auditorias continuam sendo criadas. `db/structure.sql` substitui o snapshot Ruby para preservar o trigger em bancos novos, usando `postgresql-client` na imagem. Não há novas tabelas ou gems. A proteção não é absoluta contra administradores privilegiados do banco. O procedimento excepcional de manutenção está na [documentação do banco](docs/database/README.md); as decisões e resultados estão na [ADR 0014](docs/adr/0014-historico-e-auditoria-append-only.md).

## Exportação Excel — RF012

Em **Agendamentos**, aplique os filtros e selecione **Exportar Excel**. O arquivo inclui todos os resultados, independentemente da página, até **20.000 agendamentos**. A data inicial/final considera a data agendada, com limites inclusivos, e tem prioridade sobre a data individual. É possível exportar sem filtros, datas históricas/futuras e qualquer status. Acima do limite, reduza o período ou aplique outros filtros; nenhum registro é truncado silenciosamente.

O XLSX tem uma aba **Agendamentos**, com as 26 colunas definidas no RF012, cabeçalho, autofiltro e primeira linha congelada. Representa o estado atual de cada reserva, uma linha por registro, sem replicar sua auditoria. Datas e horas são nativas do Excel em horário de Brasília; notas fiscais são texto, preservando zeros à esquerda e até 44 dígitos. Informações ausentes permanecem vazias. Textos não viram fórmulas ou hyperlinks.

Os indicadores são calculados em minutos, com duas casas decimais, usando datas completas: duração = liberação − check-in; atraso = máximo entre zero e check-in − início agendado; excedido = máximo entre zero e liberação − fim agendado. Não há duração/excedido fictícios para operações ainda abertas. O atraso calculado não determina responsabilidade da transportadora, nem muda a classificação operacional do RF008.

GET `/admin/bookings/export.xlsx` é administrativo e exige permissão de exportação. O arquivo é gerado sincronamente em memória, sem persistência; cada geração concluída registra um evento com operador, quantidade e filtros, sem dados das linhas. Vinte mil linhas levaram aproximadamente 5,8 segundos e pico de 289 MiB no processo do benchmark local; exportações simultâneas exigem recursos adicionais e não foram ensaiadas como carga. Consulte os resultados e dependências na [ADR 0015](docs/adr/0015-exportacao-xlsx-de-agendamentos.md).

Após atualizar o código, execute `docker compose up -d --build web worker` para instalar `caxlsx` e atualizar a imagem compartilhada. Não há migrations. A leitura independente dos arquivos nos testes usa Roo no grupo test. Os pré-requisitos de teste do RF010 continuam aplicáveis.

```sh
docker compose exec -T web bin/rails test
docker compose exec -T -e RAILS_ENV=test -e RF012_ROWS=20000 web bundle exec ruby test/support/benchmark_booking_export.rb
```

O benchmark é opcional, aceita 100/1000/5000/10000/20000 linhas, usa exclusivamente o banco de teste e reverte todos os dados inseridos. Um exemplo fictício gerado pelos testes fica em `tmp/rf012-example.xlsx`. Não houve homologação manual no Microsoft Excel ou Power Query; essa validação fica com o responsável.

## Autenticação e autorização — RF016

`/admin` exige login. A área pública `/agendar`, sua confirmação e o QR Code continuam sem conta administrativa. O header mostra o usuário e oferece **Meu perfil**, **Alterar senha** e **Sair do sistema**. Contas com troca obrigatória pendente acessam somente a alteração de senha e o logout.

Permissões efetivas no backend:

| Funcionalidade | Admin | Operador | Consulta |
| --- | --- | --- | --- |
| Dashboard, agendamentos, comprovantes, histórico operacional e Excel | Sim | Sim | Sim |
| Check-in, liberação, cancelamento, reagendamento, bloqueio e desbloqueio | Sim | Sim | Não |
| Usuários e auditoria de usuários | Sim | Não | Não |
| Próprio perfil e própria senha | Sim | Sim | Sim |

Sessões expiram após 30 minutos sem interação ou 12 horas no total. O polling não renova a inatividade. Alterações administrativas de e-mail, perfil, estado ou senha revogam sessões. O login limita cinco falhas por e-mail e trinta tentativas por IP em quinze minutos. Não há recuperação por e-mail, remember me ou MFA.

Crie o primeiro administrador em terminal interativo, caso ainda não exista:

```sh
docker compose exec web bin/rails users:bootstrap_admin
```

Em produção, `ADMIN_ACCESS_ENABLED` permanece `false` por padrão. Habilite somente após homologar o roteiro do RF018, HTTPS, `SECRET_KEY_BASE`, hosts, proxy confiável, cookies Secure/HSTS e privilégios runtime do banco. O Nginx deve sobrescrever cabeçalhos encaminhados e somente seu peer exato deve ser confiável para `remote_ip`. A aplicação ainda não foi implantada.

Após atualizar:

```sh
docker compose up -d --build web worker
docker compose exec -T web bin/rails db:migrate
docker compose exec -T -e RAILS_ENV=test web bin/rails db:prepare
docker compose exec -T web bin/rails test
```

Consulte a [ADR 0017](docs/adr/0017-sessoes-autenticacao-e-autorizacao.md) e a [estrutura do banco](docs/database/schema.md).

## Revisão de segurança — RF017

Os achados, correções, inventário de rotas, testes e condições de publicação estão na [ADR 0018](docs/adr/0018-revisao-de-seguranca-e-condicoes-de-publicacao.md). A área pública limita leituras, consultas de disponibilidade e tentativas de criação por IP no PostgreSQL. Corpos HTTP têm limite de 64 KiB. Idempotência continua impedindo duplicações; tentativas limitadas não são contadas como novas reservas confirmadas.

Produção exige `APP_HOST` exato, `SECRET_KEY_BASE` com pelo menos 64 caracteres e `TRUSTED_PROXY_CIDRS` com peer de proxy definido. Use `.env.production.example` como referência sem segredos. `ADMIN_ACCESS_ENABLED=true` não dispensa autenticação e o boot runtime recusa privilégios PostgreSQL excessivos. `compose.production.yaml` separa credenciais admin, migration e runtime; o roteiro está em [docs/deploy](docs/deploy/README.md).

Web/worker executam sem capabilities adicionais e com `no-new-privileges`. Mantenha o acesso em loopback e a publicação desabilitada até validar privilégios do banco, TLS, proxies, firewall, imagens, backups e cache de navegação. Nenhum deploy foi realizado.
# dsv-agendamentos
