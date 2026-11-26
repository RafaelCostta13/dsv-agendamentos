# RF018 — Revisão e simplificação da arquitetura de produção

## 1. Objetivo

Simplificar a arquitetura de produção da aplicação DSV Doca Agenda,
reduzindo a complexidade de implantação, atualização e manutenção.

O projeto é desenvolvido e mantido por uma única pessoa,
sem equipe dedicada de DevOps, infraestrutura ou CI/CD.

A arquitetura deve priorizar:

- Simplicidade.
- Estabilidade.
- Facilidade de manutenção.
- Facilidade de implantação.
- Segurança básica e proporcional.
- Menor quantidade possível de configurações.
- Utilização dos recursos nativos do Rails e Docker.

Utilizar uma abordagem semelhante à adotada no sistema RFID.

Este requisito substitui as exigências de infraestrutura
excessivamente complexas estabelecidas anteriormente no RF018.

## 2. Escopo

Alterar exclusivamente a infraestrutura de implantação
e as configurações relacionadas ao ambiente de produção.

Não alterar:

- Regras de negócio.
- Interfaces da aplicação.
- Fluxo de agendamento.
- Autenticação dos usuários.
- Controle de acesso.
- Perfis administrativos.
- Histórico de operações.
- Auditoria funcional.
- Funcionamento do worker.
- Funcionalidades implementadas nos requisitos anteriores.

Não reescrever a aplicação.

## 3. Arquitetura definitiva

Manter:

- Ruby on Rails.
- Puma.
- PostgreSQL.
- Docker.
- Docker Compose.
- Nginx instalado diretamente na VPS.
- Certbot instalado diretamente na VPS.

Utilizar somente três serviços no Docker Compose:

### web

Responsável pela aplicação Rails e pelo servidor Puma.

### worker

Responsável pelas tarefas automáticas existentes na aplicação,
incluindo o processamento de não comparecimento.

### db

Responsável pelo PostgreSQL.

Não adicionar:

- Redis.
- Sidekiq.
- Kubernetes.
- Microsserviços.
- Serviços de CI/CD.
- Containers adicionais de infraestrutura.
- Serviços permanentes de migrations.
- Nginx dentro do Docker.

## 4. Dockerfile.production

Simplificar o Dockerfile de produção.

Manter:

- Versão atual do Ruby.
- Versão atual do Bundler.
- Utilização do Gemfile.lock.
- Instalação das gems necessárias para produção.
- Compilação dos assets durante o build.
- Cliente PostgreSQL 17.
- Executáveis psql e pg_dump.
- Inicialização do Puma.

O build multi-stage poderá ser mantido caso não introduza
complexidade adicional de manutenção.

Permitir que os containers Rails sejam executados como root,
conforme decisão do responsável pelo projeto.

Remover as exigências específicas relacionadas a:

- UID/GID 10001.
- Criação obrigatória do usuário rails.
- Configurações especiais de permissões para esse usuário.
- Diretórios temporários exclusivos para contornar
  restrições de escrita.

Não utilizar modo privileged.

Não montar o socket Docker dentro dos containers.

Não alterar o usuário padrão ou o funcionamento interno
da imagem oficial do PostgreSQL.

## 5. Docker Compose de produção

Manter o arquivo:

    compose.production.yaml

Simplificar sua estrutura.

Remover:

- Serviço migrate.
- Dependência service_completed_successfully.
- Filesystem read-only obrigatório.
- Configurações personalizadas de tmpfs.
- Configurações de UID/GID.
- Configurações excessivas de capabilities.
- Restrições que dificultem a execução dos comandos Rails.
- Outras configurações sem necessidade prática comprovada.

Manter:

- Serviços web, worker e db.
- Reinicialização automática dos serviços permanentes.
- Healthcheck do PostgreSQL.
- Healthcheck da aplicação.
- Volumes persistentes.
- Rotação básica dos logs.
- Variáveis de ambiente.
- Imagem compartilhada entre web e worker.

O ambiente de desenvolvimento deve continuar funcionando
normalmente.

## 6. Rede Docker

Utilizar uma única rede privada do Docker Compose,
compartilhada pelos serviços:

- web.
- worker.
- db.

A comunicação entre os serviços deverá utilizar
os respectivos nomes internos do Docker Compose.

Exemplo:

    POSTGRES_HOST=db
    POSTGRES_PORT=5432

O PostgreSQL não deverá publicar portas no host.

O worker não deverá publicar portas no host.

A aplicação Rails deverá publicar somente:

    127.0.0.1:3000:3000

O Puma deverá escutar em:

    0.0.0.0:3000

Dentro do container.

O acesso externo à aplicação deverá continuar sendo
realizado pelo Nginx instalado diretamente na VPS.

Não utilizar rede host.

Utilizar uma rede bridge privada convencional,
sem configurações avançadas desnecessárias.

Não exigir internal: true caso essa configuração
dificulte a comunicação entre o Nginx no host
e a aplicação ou futuras integrações externas.

O isolamento do PostgreSQL deve ser garantido pela
ausência de publicação de suas portas no host.

## 7. Simplificação do PostgreSQL

Remover a obrigatoriedade de utilizar três usuários distintos
para administração, migrations e execução da aplicação.

Adotar dois usuários:

### Administrador do PostgreSQL

Responsável pela administração do banco de dados.

### Usuário da aplicação

Responsável por:

- Conexão do Rails.
- Conexão do worker.
- Execução das migrations.
- Criação e alteração das tabelas da aplicação.
- Operações necessárias ao funcionamento do sistema.

O usuário da aplicação poderá ser proprietário do banco
e dos objetos necessários ao funcionamento do Rails.

Não deverá possuir:

- Privilégio de superuser.
- Privilégio de criação de outros bancos.
- Privilégio de criação de usuários.
- Privilégio BYPASSRLS.

Não é necessário manter um usuário exclusivo para migrations.

Remover a dependência obrigatória de:

    production:grant_runtime

Simplificar ou remover, quando necessário:

- lib/tasks/production.rake.
- bin/production-migrate.
- Initializers relacionados à separação obrigatória
  dos usuários de migrations e runtime.
- Scripts excessivamente complexos de concessão de privilégios.

Preservar a auditoria funcional da aplicação e suas regras.

Manter as proteções de auditoria existentes que forem
compatíveis com a arquitetura simplificada.

Documentar que um usuário proprietário das tabelas possui
capacidade administrativa sobre esses objetos, não sendo
possível garantir auditoria imutável contra o próprio
proprietário do banco.

Essa limitação é aceita nesta etapa do projeto.

## 8. Preservação do banco existente na VPS

ATENÇÃO:

O PostgreSQL de produção já está inicializado na VPS.

Informações atuais:

    PostgreSQL: 17.12
    Banco: dsv_doca_agenda_production
    Volume: dsv_agenda_production_postgres

Usuários existentes:

    dsv_agenda_admin
    dsv_agenda_migrator
    dsv_agenda_runtime

A execução de db:migrate já avançou até a tarefa
production:grant_runtime.

Portanto, considerar que as tabelas e as migrations
podem já estar presentes no banco.

A última falha encontrada foi:

    KeyError: key not found: "POSTGRES_MIGRATION_USER"

    /rails/lib/tasks/production.rake:10

    Tasks: TOP => production:grant_runtime

A nova arquitetura deverá permitir utilizar o banco existente,
sem necessidade de recriá-lo.

Preferencialmente, avaliar a reutilização do usuário
dsv_agenda_migrator como usuário definitivo da aplicação,
caso ele já seja proprietário das tabelas existentes.

Essa abordagem poderá reduzir a necessidade de transferir
a propriedade dos objetos do banco.

Confirmar essa condição antes de definir o procedimento.

Preparar instruções simples para a transição do ambiente
atual para a nova arquitetura.

Não acessar diretamente a VPS.

Não executar:

- docker compose down -v.
- docker volume rm.
- rails db:drop.
- rails db:reset.
- Exclusão de tabelas.
- Exclusão de registros.
- Exclusão indiscriminada de usuários.
- Regeneração desnecessária de credenciais.

Não alterar o nome do volume PostgreSQL existente.

Não alterar o nome do volume de storage existente.

Não remover usuários antigos antes de verificar
suas dependências e propriedades no banco.

Realizar backup antes de qualquer alteração de ownership
ou privilégios no banco existente.

## 9. Variáveis de ambiente

Simplificar o arquivo:

    .env.production.example

Utilizar uma estrutura próxima de:

    RAILS_ENV=production
    APP_HOST=dsvbooking.tech
    ADMIN_ACCESS_ENABLED=false

    SECRET_KEY_BASE=

    RAILS_PORT=3000
    HOST_RAILS_PORT=3000
    RAILS_MAX_THREADS=3
    RAILS_LOG_LEVEL=info

    POSTGRES_HOST=db
    POSTGRES_PORT=5432
    POSTGRES_DB=dsv_doca_agenda_production

    POSTGRES_ADMIN_USER=dsv_agenda_admin
    POSTGRES_ADMIN_PASSWORD=

    POSTGRES_USER=
    POSTGRES_PASSWORD=

Adequar os nomes das variáveis ao funcionamento real
do Rails e do PostgreSQL.

O exemplo acima é uma referência, não sendo necessário
adotar exatamente todos os nomes caso exista uma alternativa
mais simples e consistente.

Remover as variáveis que não forem mais necessárias.

Não disponibilizar a senha administrativa do PostgreSQL
nos containers web e worker.

Não substituir automaticamente o arquivo .env.production
já existente na VPS.

Documentar somente as alterações necessárias nesse arquivo.

Manter:

- .env.production protegido pelo .gitignore.
- .env.production excluído do contexto de build.
- Credenciais fora do código-fonte.
- SECRET_KEY_BASE existente.

## 10. Configuração de proxy

Simplificar as configurações de proxy do Rails.

A arquitetura utilizará:

    Internet
        |
    Nginx na VPS
        |
    127.0.0.1:3000
        |
    Rails / Puma

Evitar a necessidade de identificar e configurar manualmente
o gateway Docker a cada implantação.

Não exigir configurações dinâmicas complexas de CIDR.

Manter o tratamento correto dos cabeçalhos encaminhados
pelo Nginx.

Garantir que o Nginx sobrescreva os cabeçalhos de origem
e protocolo enviados pelo cliente.

Não confiar indiscriminadamente em todos os proxies.

Preservar:

- Funcionamento do HTTPS.
- Identificação do domínio.
- Cookies seguros.
- Identificação adequada do IP do cliente.
- Limitação de tentativas de autenticação.

Adotar a solução mais simples compatível com esses controles.

## 11. Processo de deploy

O processo de implantação e atualização deverá ser simples,
manual e executado diretamente pelo responsável na VPS.

O fluxo desejado é:

### Atualizar código

    git pull --ff-only origin main

### Construir a imagem

    docker compose --env-file .env.production \
      -f compose.production.yaml build

### Inicializar banco, quando necessário

    docker compose --env-file .env.production \
      -f compose.production.yaml up -d db

### Executar migrations

    docker compose --env-file .env.production \
      -f compose.production.yaml run --rm web \
      bin/rails db:migrate

### Inicializar aplicação

    docker compose --env-file .env.production \
      -f compose.production.yaml up -d

### Verificar containers

    docker compose --env-file .env.production \
      -f compose.production.yaml ps

### Consultar logs

    docker compose --env-file .env.production \
      -f compose.production.yaml logs --tail=100

Este deverá ser o procedimento padrão de implantação.

Garantir que uma falha nas migrations seja apresentada
claramente ao operador.

O procedimento documentado deverá orientar a interrupção
do deploy caso as migrations falhem.

Não executar migrations automaticamente durante
a inicialização do web ou worker.

Não exigir atualização manual de IMAGE_TAG
a cada commit.

Utilizar uma identificação simples e estável para
a imagem local de produção.

A rastreabilidade da versão poderá ser realizada
pelo commit Git presente na VPS.

Não implementar pipelines, registries privados
ou mecanismos adicionais de CI/CD.

## 12. Nginx e SSL

Manter a arquitetura existente:

- Nginx instalado diretamente na VPS.
- Certbot instalado diretamente na VPS.
- Certificado Let's Encrypt.
- Redirecionamento HTTP para HTTPS.
- Proxy reverso para 127.0.0.1:3000.

Domínio oficial:

    dsvbooking.tech

Preservar os templates existentes que estiverem funcionando.

Simplificar apenas configurações comprovadamente
desnecessárias.

Não realizar alterações diretamente no servidor.

## 13. Segurança básica

Manter os controles essenciais de segurança.

### Infraestrutura

- HTTPS.
- Firewall no servidor.
- PostgreSQL sem porta pública.
- Rails publicado somente no loopback.
- Rede privada entre os containers.
- Credenciais fora do Git.
- Ausência de containers privilegiados.
- Ausência de montagem do socket Docker.
- Backup do banco de dados.

### Aplicação

- Autenticação.
- Controle de acesso por perfil.
- Proteção das senhas com bcrypt.
- Proteção CSRF.
- Proteção contra SQL Injection.
- Proteção contra XSS.
- Cookies seguros em produção.
- Limitação de tentativas de login.
- Validação dos dados no backend.
- Auditoria das operações.

Não remover controles funcionais de segurança
já implementados na aplicação.

Não adicionar novas camadas de segurança
neste requisito.

Melhorias adicionais de segurança poderão ser avaliadas
futuramente, conforme a necessidade real do projeto.

## 14. Testes

Realizar testes objetivos e suficientes para confirmar
o funcionamento da arquitetura simplificada.

Validar:

1. Build da imagem de produção.
2. Inicialização do PostgreSQL.
3. Disponibilidade do psql.
4. Disponibilidade do pg_dump.
5. Execução manual de db:migrate.
6. Reexecução de db:migrate sem erros.
7. Inicialização do web.
8. Inicialização do worker.
9. Endpoint /up.
10. Endpoint /ready.
11. Conexão com o PostgreSQL.
12. Funcionamento básico do agendamento.
13. Funcionamento básico da autenticação.
14. Persistência dos dados após reiniciar os containers.
15. Funcionamento do ambiente de desenvolvimento.

Executar os testes automatizados existentes
relacionados às alterações realizadas.

Não criar uma infraestrutura de testes adicional.

Não utilizar o banco de produção nos testes.

Não declarar testes como aprovados caso
não tenham sido efetivamente executados.

## 15. Documentação

Atualizar:

- README.md.
- docs/deploy/production.md.
- Documentação relacionada ao RF018.
- ADR relacionado à arquitetura de produção.
- AGENTS.md, caso existam instruções conflitantes
  com a nova arquitetura aprovada.

Remover instruções antigas que não sejam mais aplicáveis.

A documentação de deploy deve ser curta, objetiva
e adequada à manutenção por uma única pessoa.

Criar uma seção específica contendo os comandos
necessários para atualizar a VPS atual, considerando:

- PostgreSQL já inicializado.
- Volume existente.
- Credenciais existentes.
- Migrations possivelmente executadas.
- Transição para o usuário definitivo da aplicação.
- Remoção do container migrate antigo.
- Reconstrução da imagem.
- Inicialização do web e worker.

Apresentar os comandos na ordem correta de execução.

## 16. Critérios de aceite

O requisito será considerado concluído quando:

- Existirem somente três serviços permanentes.
- O serviço migrate não for mais necessário.
- O Rails puder executar db:migrate manualmente.
- O PostgreSQL existente puder ser preservado.
- O build da imagem funcionar.
- O web iniciar corretamente.
- O worker iniciar corretamente.
- Os healthchecks funcionarem.
- O deploy puder ser realizado com poucos comandos.
- Não houver necessidade de configurações manuais
  complexas a cada atualização.
- As funcionalidades existentes forem preservadas.
- Os controles básicos de segurança forem preservados.

## 17. Diretriz geral de implementação

Priorizar a solução mais simples que funcione corretamente.

Não implementar soluções excessivamente sofisticadas
para problemas que ainda não existem.

Não adicionar abstrações, dependências, serviços,
scripts ou configurações sem necessidade comprovada.

Considerar que o sistema será mantido por uma única pessoa.

Sempre que houver duas soluções tecnicamente adequadas,
preferir aquela que seja mais fácil de compreender,
implantar, diagnosticar e manter.

## 18. Entrega

Ao finalizar, apresentar um relatório objetivo contendo:

- Arquivos alterados.
- Configurações removidas.
- Configurações mantidas.
- Arquitetura final.
- Testes executados.
- Resultados obtidos.
- Eventuais limitações.
- Comandos para atualizar a VPS existente.

Não realizar deploy automaticamente.
Não acessar o servidor de produção.
Não realizar push automaticamente.
Não avançar para outro requisito funcional.

Aguardar a homologação do responsável pelo projeto.