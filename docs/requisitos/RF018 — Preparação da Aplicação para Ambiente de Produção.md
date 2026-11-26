# RF018 — Preparação da Aplicação para Ambiente de Produção

## 1. Objetivo

Preparar a aplicação DSV Doca Agenda para implantação
em ambiente de produção no domínio oficial:

    https://dsvbooking.tech

Preservar integralmente as funcionalidades existentes,
o ambiente de desenvolvimento e todas as proteções
de segurança implementadas nos requisitos anteriores.

Realizar todas as alterações necessárias no repositório
local para permitir uma implantação segura,
reproduzível e documentada.

Não realizar o deploy diretamente na VPS.

---

## 2. Infraestrutura existente

O servidor de produção já está preparado parcialmente.

Configurações confirmadas:

    Sistema operacional: Ubuntu 26.04
    IP público: 189.24.17.159
    Domínio oficial: dsvbooking.tech
    Docker Engine: 29.10.1
    Docker Compose: 5.8.0
    Docker Buildx: 0.39.1
    Nginx: 1.28.3
    Certbot: 5.10.0

Diretório da aplicação na VPS:

    /opt/apps/dsv-agendamentos

O repositório Git já foi clonado na VPS.

Docker e Nginx estão instalados, ativos e configurados
para inicialização automática.

Certbot está instalado e possui renovação automática.

Foi emitido um certificado temporário para o IP público:

    189.24.17.159

Certificado temporário:

    /etc/letsencrypt/live/189.24.17.159/fullchain.pem

Chave privada:

    /etc/letsencrypt/live/189.24.17.159/privkey.pem

O certificado temporário foi validado com sucesso.

A simulação de renovação também foi bem-sucedida.

O Nginx atualmente retorna:

    DSV Doca Agenda - HTTPS OK

A configuração definitiva utilizará:

    dsvbooking.tech

Ainda estão pendentes:

- Configuração do DNS.
- Emissão do certificado SSL para o domínio.
- Configuração do firewall.
- Configuração definitiva do proxy reverso.
- Implantação da aplicação.
- Homologação em produção.

Não executar essas ações diretamente na VPS.

---

## 3. Requisitos anteriores

Requisitos implementados:

    RF001 até RF012
    RF015
    RF016
    RF017

Requisitos suspensos:

    RF013 — Upload e armazenamento de documentos.
    RF014 — Notificações por e-mail via Power Automate.

Não implementar os requisitos suspensos.

Antes de iniciar, consultar:

    AGENTS.md
    README.md
    .agents/skills/
    docs/adr/
    docs/database/
    docs/requisitos/
    docs/security/

Consultar os documentos efetivamente existentes.

Verificar o código atual antes de realizar alterações.

Preservar todas as regras operacionais homologadas.

---

## 4. Identidade e domínio

Domínio oficial de produção:

    dsvbooking.tech

URLs previstas:

    https://dsvbooking.tech/
    https://dsvbooking.tech/agendar
    https://dsvbooking.tech/login
    https://dsvbooking.tech/admin

Preservar as rotas efetivamente implementadas.

Não criar novas rotas apenas para corresponder
aos exemplos anteriores.

Utilizar o domínio como configuração de ambiente.

Não incorporar o domínio diretamente em:

- Controllers.
- Models.
- Services.
- Views.
- JavaScript.
- Regras de negócio.
- Testes que dependam de um domínio fixo.

Utilizar a variável APP_HOST ou o mecanismo
equivalente existente.

Configuração esperada:

    APP_HOST=dsvbooking.tech

Permitir alteração futura do domínio
sem modificar o código-fonte.

Não alterar automaticamente:

- Nome comercial da aplicação.
- Logo.
- Identidade visual.
- Layout.
- Textos das telas.

O domínio foi definido como dsvbooking.tech,
mas a identidade visual existente deverá
permanecer inalterada neste requisito.

---

## 5. Arquitetura obrigatória

Preservar:

- Ruby on Rails monolítico.
- MVC.
- Views ERB.
- Puma.
- PostgreSQL.
- Docker Compose.
- Worker de no-show existente.
- Nginx instalado diretamente no host.
- Certbot instalado diretamente no host.

Fluxo de produção:

    Internet
        |
    Nginx - HTTPS
        |
    127.0.0.1:3000
        |
    Rails + Puma
        |
    PostgreSQL

O worker deverá utilizar o mesmo banco
e a mesma imagem da aplicação.

Cloudflare poderá ser utilizado posteriormente.

Não depender obrigatoriamente do Cloudflare.

Não introduzir:

- Redis.
- Sidekiq.
- Kubernetes.
- Microsserviços.
- React.
- Vue.
- Novos serviços externos.

---

## 6. Problemas identificados

A configuração encontrada na VPS possui:

- RAILS_ENV padrão development.
- Montagem do código-fonte local em /rails.
- SECRET_KEY_BASE não repassada explicitamente.
- APP_HOST não repassada explicitamente.
- Política de restart apenas no worker.
- Mesmo POSTGRES_USER para banco e aplicação.
- Dockerfile predominantemente orientado
  ao ambiente de desenvolvimento.
- Ausência de .env.production.example na VPS.

Verificar também se os seguintes arquivos
estão presentes e rastreados pelo Git:

    .gitignore
    .dockerignore
    .env.example
    .env.production.example
    .ruby-version
    .rubocop.yml
    .agents/

A ausência dos arquivos ocultos pode estar
relacionada ao comando git add * utilizado
anteriormente.

Não recriar arquivos sem verificar
se já existem no ambiente local.

Corrigir os problemas confirmados.

---

## 7. Docker Compose de produção

Preservar:

    compose.yaml

como configuração de desenvolvimento.

Criar um arquivo independente:

    compose.production.yaml

O ambiente de produção deverá funcionar
sem depender das configurações de desenvolvimento.

Comando previsto:

    docker compose \
      --env-file .env.production \
      -f compose.production.yaml \
      up -d

Adaptar a sequência de inicialização
às migrations e demais serviços auxiliares.

Não executar esse comando na VPS
durante o desenvolvimento do requisito.

Utilizar um nome de projeto Compose
específico para produção.

Garantir isolamento dos volumes
de desenvolvimento e produção.

---

## 8. Serviços de produção

Configurar os serviços permanentes:

    db

        PostgreSQL.

    web

        Rails e Puma.

    worker

        Worker de no-show existente.

Criar, se necessário, um serviço auxiliar:

    migrate

Responsável exclusivamente pela execução
controlada das migrations.

O serviço auxiliar não deverá permanecer
em execução após concluir sua função.

Web, worker e migrate deverão utilizar
a mesma imagem de produção.

Não criar containers desnecessários.

---

## 9. Dockerfile de produção

Criar:

    Dockerfile.production

Preservar o Dockerfile de desenvolvimento.

Utilizar inicialmente as versões existentes:

    Ruby: 3.4.13
    Bundler: 2.6.2

Confirmar compatibilidade com Gemfile.lock.

Utilizar build multi-stage.

Separar:

- Build das dependências.
- Compilação das gems.
- Compilação dos assets.
- Imagem final de runtime.

A imagem final deverá conter somente
os componentes necessários à execução.

Garantir:

- Execução como usuário não root.
- Dependências reproduzíveis.
- Gemfile.lock preservado.
- Ausência de credenciais reais.
- Permissões adequadas.
- Bibliotecas de runtime disponíveis.
- Assets compilados.

Não incluir ferramentas de desenvolvimento
desnecessárias na imagem final.

Não atualizar indiscriminadamente
as versões das dependências.

---

## 10. Dependências Ruby

Configurar, quando compatível:

    BUNDLE_DEPLOYMENT=1
    BUNDLE_FROZEN=1
    BUNDLE_WITHOUT=development:test

Utilizar exclusivamente as dependências
necessárias ao ambiente de produção.

Não executar bundle update automaticamente.

Não modificar o Gemfile.lock durante o build.

Verificar todas as gems utilizadas por:

- Rails.
- PostgreSQL.
- Autenticação.
- Exportação Excel.
- QR Code.
- Worker.
- Assets.

---

## 11. Compilação de assets

Identificar o mecanismo de assets existente.

Compilar os assets durante o build
da imagem de produção.

Garantir funcionamento de:

- CSS.
- JavaScript.
- Logo DSV.
- Formulário público.
- Login.
- Painel administrativo.
- Dashboard.
- Comprovantes.
- QR Code.

Utilizar SECRET_KEY_BASE_DUMMY
durante o build, quando compatível.

Não utilizar SECRET_KEY_BASE real no build.

Não exigir acesso ao banco de produção
para compilar os assets.

Não enfraquecer as validações de segurança
do runtime para permitir a compilação.

---

## 12. Portas e redes

Rails e Puma deverão escutar
dentro do container em:

    0.0.0.0:3000

A publicação no host deverá ser:

    127.0.0.1:3000:3000

Não publicar o Puma em todas
as interfaces do servidor.

O PostgreSQL não deverá possuir
portas publicadas no host.

O worker não deverá possuir
portas publicadas no host.

Utilizar a rede interna do Docker.

Não utilizar network_mode: host.

Não expor a API do Docker.

Não montar o socket Docker.

---

## 13. Volumes persistentes

Configurar volumes persistentes para:

- PostgreSQL.
- Armazenamento necessário da aplicação.

Não montar o código-fonte do host:

    - .:/rails

em produção.

O código deverá estar incorporado
à imagem Docker.

Garantir permissões adequadas para:

    /rails/log
    /rails/tmp
    /rails/tmp/pids
    /rails/storage

Não utilizar chmod 777.

Não excluir volumes existentes.

Não compartilhar volumes de desenvolvimento
com produção.

Não utilizar docker compose down -v
nos procedimentos operacionais.

---

## 14. Inicialização automática

Configurar:

    restart: unless-stopped

para os serviços permanentes:

    db
    web
    worker

Não aplicar restart permanente
ao serviço de migrations.

Testar recuperação após:

- Reinicialização dos containers.
- Reinicialização dos serviços.
- Interrupção temporária do banco.
- Encerramento do processo web.
- Encerramento do worker.

Documentar as limitações.

Um estado unhealthy não implica
reinicialização automática do container.

---

## 15. PostgreSQL

Preservar inicialmente:

    postgres:17.12-alpine

Verificar compatibilidade
e avisos de segurança.

Separar as credenciais de banco em:

### Usuário administrativo

Responsável pela inicialização
e administração do PostgreSQL.

### Usuário de migrations

Responsável pela estrutura
e alterações autorizadas do banco.

### Usuário operacional

Utilizado por Rails e worker.

O usuário operacional não poderá possuir:

- SUPERUSER.
- CREATEDB.
- CREATEROLE.
- BYPASSRLS.
- Permissões administrativas desnecessárias.
- Propriedade desnecessária das tabelas.

Garantir que o usuário definido
inicialmente pela imagem PostgreSQL
não seja utilizado indiscriminadamente
como usuário operacional.

Preservar as proteções do RF017.

Revisar:

    config/database.yml
    config/initializers/production_database_privileges.rb

Não repassar credenciais administrativas
ao web ou worker.

---

## 16. Inicialização e privilégios do banco

Preparar um mecanismo seguro
de inicialização do PostgreSQL.

Preferencialmente utilizar:

    deploy/postgres/

Com scripts compatíveis com:

    docker-entrypoint-initdb.d

Ou mecanismo equivalente documentado.

Criar os usuários e privilégios necessários.

Não versionar senhas.

Não interpolar credenciais inseguramente
em comandos SQL.

Não registrar credenciais nos logs.

Garantir grants mínimos necessários.

Configurar default privileges
para migrations futuras.

Documentar que scripts de inicialização
são executados somente em volumes vazios.

Preparar procedimento não destrutivo
para bancos existentes.

Não recriar o banco a cada inicialização.

---

## 17. Auditoria append-only

Preservar integralmente
as proteções da auditoria.

O usuário operacional deverá conseguir
inserir novos eventos.

Não deverá conseguir:

- Atualizar eventos existentes.
- Excluir eventos existentes.
- Executar TRUNCATE na auditoria.
- Alterar a estrutura da auditoria.
- Desabilitar mecanismos de proteção.

Validar utilizando as credenciais
do usuário operacional.

Preservar a atomicidade entre operações
de negócio e eventos de auditoria.

---

## 18. Migrations

Revisar:

    bin/docker-entrypoint

Não executar migrations simultaneamente
em web e worker.

Utilizar uma etapa explícita
de migrations com credenciais autorizadas.

Sequência esperada:

    1. Inicializar PostgreSQL.
    2. Aguardar disponibilidade.
    3. Executar migrations.
    4. Validar estrutura e privilégios.
    5. Inicializar web.
    6. Inicializar worker.

Adaptar os comandos à implementação real.

Não utilizar:

    db:drop
    db:reset

Não executar seeds com usuários
ou credenciais padrão.

Não excluir registros existentes.

---

## 19. Variáveis de ambiente

Criar ou revisar:

    .env.production.example

O arquivo deverá ser versionado
e conter somente valores ilustrativos.

O arquivo real:

    .env.production

deverá permanecer exclusivamente
no ambiente de implantação.

Configuração conceitual:

    RAILS_ENV=production

    APP_HOST=dsvbooking.tech

    RAILS_PORT=3000

    SECRET_KEY_BASE=

    ADMIN_ACCESS_ENABLED=false

    POSTGRES_HOST=db

    POSTGRES_PORT=5432

    POSTGRES_DB=dsv_doca_agenda_production

    POSTGRES_USER=

    POSTGRES_PASSWORD=

Adicionar as variáveis necessárias
para os usuários administrativo
e de migrations.

Adaptar os nomes às convenções
efetivamente utilizadas no projeto.

Não criar variáveis duplicadas
com a mesma responsabilidade.

Documentar:

- Finalidade.
- Obrigatoriedade.
- Valor esperado.
- Serviço que utiliza.
- Forma segura de geração.

Não incluir valores reais.

---

## 20. Distribuição de segredos

Garantir que as variáveis
sejam efetivamente disponibilizadas
aos containers necessários.

Não assumir que:

    docker compose --env-file

injeta automaticamente todas
as variáveis no container.

Utilizar repasse explícito
e restrito por serviço.

Não entregar todas as credenciais
a todos os containers.

Falhar de forma segura
quando faltarem variáveis obrigatórias.

Não utilizar valores padrão inseguros
em produção.

---

## 21. SECRET_KEY_BASE

Documentar a geração segura:

    openssl rand -hex 64

Ou mecanismo oficial equivalente do Rails.

Garantir:

- Chave forte.
- Chave persistente entre reinicializações.
- Chave não versionada.
- Chave não incorporada ao build.
- Chave não registrada em logs.

Documentar impactos de rotação.

Não gerar uma nova chave automaticamente
a cada inicialização do container.

---

## 22. Segurança dos arquivos Git

Revisar:

    .gitignore
    .dockerignore

Garantir exclusão de:

    .env
    .env.*
    config/master.key
    config/credentials/*.key
    *.pem
    *.key
    *.p12
    *.pfx
    *.dump
    *.backup
    *.bak
    *.sql.gz
    backups
    logs
    arquivos temporários

Preservar:

    .env.example
    .env.production.example
    .ruby-version
    .rubocop.yml
    Gemfile.lock
    db/structure.sql
    .agents/
    AGENTS.md

Verificar arquivos sensíveis
eventualmente rastreados.

Não reescrever o histórico Git.

Não imprimir valores sensíveis.

Caso existam credenciais expostas,
registrar a necessidade de rotação.

---

## 23. Build context

Garantir que arquivos sensíveis
não sejam enviados ao build Docker.

Excluir quando apropriado:

- Histórico Git.
- Credenciais.
- Arquivos .env reais.
- Backups.
- Dumps.
- Logs.
- Documentação corporativa desnecessária.
- Relatórios de segurança.
- Arquivos temporários.
- Dependências locais.
- Skills de desenvolvimento.

Avaliar:

    Dockerfile.production.dockerignore

quando necessário.

Não excluir arquivos essenciais
ao funcionamento da aplicação.

---

## 24. Configuração Rails de produção

Revisar:

    config/environments/production.rb

Garantir:

- RAILS_ENV=production.
- Páginas de erro seguras.
- Assets disponíveis.
- Cookies seguros.
- HTTPS obrigatório para usuários externos.
- Content Security Policy.
- CSRF.
- Host Authorization.
- Logs seguros.
- Rate limiting.
- Sessões.
- Autorização.

Preservar as proteções do RF016
e do RF017.

Não habilitar páginas detalhadas
de desenvolvimento em produção.

---

## 25. Host Authorization

Configurar o host autorizado:

    dsvbooking.tech

através de APP_HOST.

Não aceitar hosts arbitrários.

Não desabilitar Host Authorization.

Permitir configuração temporária
do IP público, quando necessário
para testes controlados.

Não habilitar simultaneamente o IP
como endereço público alternativo
sem necessidade operacional.

O host definitivo deverá ser:

    dsvbooking.tech

Avaliar o funcionamento dos healthchecks
internos sem liberar hosts indevidos.

---

## 26. HTTPS e proxies

O HTTPS será finalizado pelo Nginx
instalado no host.

Fluxo:

    Cliente HTTPS
        |
    Nginx
        |
    HTTP local
        |
    Puma

Garantir tratamento adequado de:

    Host
    X-Forwarded-Proto
    X-Forwarded-For
    X-Real-IP

Avaliar force_ssl e assume_ssl
conforme a implementação Rails.

Evitar redirecionamentos infinitos.

Não confiar em cabeçalhos enviados
diretamente por clientes externos.

Definir proxies confiáveis
de forma restrita.

Não enfraquecer:

- Cookies Secure.
- Rate limiting.
- Identificação de IP.
- Proteção de sessões.

Preparar documentação para Cloudflare,
caso seja utilizado posteriormente.

---

## 27. Painel administrativo

Preservar por padrão:

    ADMIN_ACCESS_ENABLED=false

Não habilitar automaticamente
a publicação administrativa.

Quando autorizado, utilizar:

    ADMIN_ACCESS_ENABLED=true

Essa configuração deverá controlar
somente a disponibilidade das rotas.

Nunca deverá desabilitar:

- Autenticação.
- Autorização.
- Validação de sessões.
- Controle de perfis.
- Troca obrigatória de senha.

Preservar a matriz de permissões:

    admin
    operator
    viewer

Não criar bypass administrativo.

---

## 28. Puma

Revisar:

    config/puma.rb

Garantir funcionamento adequado
em produção.

Permitir configuração de:

- Threads.
- Workers.
- Porta.
- Pool de conexões.
- Timeouts.
- Encerramento gracioso.

Não presumir recursos de CPU e RAM
que não tenham sido confirmados.

Adotar valores iniciais conservadores
e documentar os parâmetros ajustáveis.

Considerar o consumo do PostgreSQL,
do worker e do processo web.

---

## 29. Worker de no-show

Preservar:

    bin/no-show-worker

Garantir que execute:

- Em produção.
- Com usuário não root.
- Com credenciais operacionais.
- Independentemente do navegador.
- Sem migrations automáticas.
- Sem duplicar processos de no-show.

Preservar:

- Frequência homologada.
- Idempotência.
- Concorrência.
- Auditoria.
- Recuperação após reinicialização.
- Regras de reagendamento automático.

---

## 30. Healthchecks

Preservar:

    /up
    /ready

Garantir que:

    /up

verifique a disponibilidade do Rails.

    /ready

verifique se a aplicação está apta
a operar conforme os controles existentes.

Configurar healthchecks para:

- PostgreSQL.
- Web.

Avaliar monitoramento do worker
sem criar infraestrutura desnecessária.

Garantir compatibilidade com:

- Host Authorization.
- HTTPS.
- Configuração de produção.
- Credenciais operacionais.

Não expor informações internas
ou dados sensíveis.

---

## 31. Logs

Configurar logs dos containers
com rotação.

Utilizar stdout e stderr
quando apropriado.

Permitir diagnóstico através de:

    docker compose logs

Avaliar o driver local do Docker
ou mecanismo equivalente.

Evitar crescimento ilimitado.

Preservar filtros de parâmetros.

Não registrar:

- Senhas.
- Tokens.
- Cookies.
- SECRET_KEY_BASE.
- Credenciais PostgreSQL.
- Dados pessoais desnecessários.

---

## 32. Segurança dos containers

Preservar, quando compatível:

    security_opt:
      - no-new-privileges:true

    cap_drop:
      - ALL

Não utilizar:

    privileged: true
    network_mode: host
    pid: host

Não montar o socket Docker.

Não conceder capabilities
desnecessárias.

Avaliar filesystem read-only
para web e worker, quando viável.

Não comprometer a inicialização
do PostgreSQL ou dos serviços.

---

## 33. Template Nginx definitivo

Criar:

    deploy/nginx/dsvbooking.tech.conf.example

Preparar uma configuração de referência
para o domínio oficial.

Host:

    dsvbooking.tech

Certificado futuro:

    /etc/letsencrypt/live/dsvbooking.tech/fullchain.pem

Chave privada futura:

    /etc/letsencrypt/live/dsvbooking.tech/privkey.pem

Destino do proxy:

    http://127.0.0.1:3000

Configurar no template:

- Porta HTTP 80.
- Porta HTTPS 443.
- Redirecionamento HTTP para HTTPS.
- TLS 1.2 e TLS 1.3.
- Cabeçalhos de proxy seguros.
- Timeouts apropriados.
- Limites de tamanho de requisição.
- Proteção contra exposição de informações.
- Cache adequado.
- Preservação da política de segurança do Rails.

Não duplicar cabeçalhos de segurança
de maneira contraditória.

Não utilizar redirecionamentos
baseados em Host não validado.

Não expor endpoints internos
de diagnóstico desnecessariamente.

Não configurar www.dsvbooking.tech
sem confirmação de que será utilizado.

Não instalar o template automaticamente.

Documentar que os arquivos do certificado
do domínio precisam existir antes de
ativar o Virtual Host HTTPS definitivo.

---

## 34. Certbot e validação ACME

Preservar a rota:

    /.well-known/acme-challenge/

Webroot:

    /var/www/html

Não encaminhar a validação ACME
para o Rails.

Não exigir autenticação nessa rota.

Preparar documentação para emissão
do certificado definitivo utilizando:

    sudo certbot certonly \
      --webroot \
      --webroot-path /var/www/html \
      -d dsvbooking.tech \
      --key-type ecdsa \
      --deploy-hook "nginx -t && systemctl reload nginx"

O comando deverá ser executado
somente após a configuração do DNS
e validação do acesso HTTP externo.

Não executar o comando neste requisito.

Documentar:

    sudo certbot certificates

    sudo certbot renew --dry-run

    sudo certbot renew --dry-run --run-deploy-hooks

Preservar a renovação automática.

Documentar a futura desativação segura
do certificado temporário do IP.

Não remover o certificado do IP
antes de validar o domínio definitivo
e remover suas referências do Nginx.

---

## 35. DNS

Documentar a configuração esperada:

    Tipo: A
    Nome: @
    Destino: 189.24.17.159

Domínio resultante:

    dsvbooking.tech

Caso Cloudflare seja utilizado,
documentar inicialmente a validação
com DNS Only.

Após validação do certificado,
avaliar a ativação do proxy Cloudflare.

Utilizar Full (strict) quando
o proxy Cloudflare for adotado
e o certificado da origem estiver válido.

Não configurar Flexible SSL.

Não criar registros AAAA
sem endereço IPv6 confirmado.

Não alterar o DNS diretamente.

---

## 36. Firewall e publicação

Documentar os requisitos de publicação:

- SSH restrito conforme infraestrutura.
- HTTP 80 permitido conforme necessidade.
- HTTPS 443 permitido.
- Puma 3000 não exposto publicamente.
- PostgreSQL 5432 não exposto publicamente.
- API Docker não exposta.

Considerar a interação entre Docker
e regras do firewall do host.

Não confiar exclusivamente no UFW
para proteger portas publicadas pelo Docker.

O firewall permanece pendente.

Não considerar a aplicação homologada
para publicação pública enquanto
os controles obrigatórios não estiverem
validados pelo responsável.

Não realizar alterações reais
no firewall.

---

## 37. Backup

Preparar uma estratégia simples
de backup do PostgreSQL.

Utilizar:

    pg_dump
    pg_restore

quando adequado.

Documentar:

- Criação de backups.
- Permissões dos arquivos.
- Frequência sugerida.
- Retenção sugerida.
- Criptografia.
- Armazenamento separado.
- Restauração.
- Teste de recuperação.

Considerar os usuários e privilégios
necessários à restauração.

Não incluir senhas em comandos.

Não publicar backups através do Nginx.

Não versionar backups.

Realizar testes exclusivamente
com dados fictícios.

Não restaurar sobre bancos reais.

Preservar constraints, índices,
triggers e auditoria.

---

## 38. Primeiro administrador

Preservar o mecanismo:

    bin/rails users:bootstrap_admin

Verificar sua compatibilidade
com Docker Compose de produção.

Documentar o comando efetivo.

Garantir:

- Entrada segura de senha.
- Ausência de senha padrão.
- Troca obrigatória de senha.
- Auditoria.
- Proteção contra duplicidade.
- Proteção do último administrador.

Não utilizar seeds com credenciais.

---

## 39. Primeira implantação

Criar um roteiro completo
para execução manual na VPS.

O roteiro deverá considerar que
o repositório já está localizado em:

    /opt/apps/dsv-agendamentos

Sequência:

    1. Verificar o estado do Git.

    2. Atualizar o repositório.

    3. Criar .env.production.

    4. Gerar credenciais.

    5. Configurar permissões.

    6. Validar o Docker Compose.

    7. Construir a imagem de produção.

    8. Inicializar PostgreSQL.

    9. Preparar privilégios.

    10. Executar migrations.

    11. Criar o primeiro administrador.

    12. Inicializar web e worker.

    13. Validar healthchecks.

    14. Testar a aplicação localmente.

    15. Validar DNS.

    16. Emitir certificado do domínio.

    17. Configurar proxy reverso.

    18. Validar HTTPS.

    19. Validar controles de segurança.

    20. Realizar backup inicial.

    21. Homologar a publicação.

Adaptar os comandos aos arquivos
realmente implementados.

Não fornecer comandos fictícios.

Não executar a implantação real.

---

## 40. Atualizações futuras

Documentar procedimento baseado em:

    git status

    git pull --ff-only

Construção da imagem de produção.

Backup antes de alterações relevantes.

Execução controlada de migrations.

Atualização de web e worker.

Validação dos healthchecks.

Não remover os volumes existentes.

Não executar docker system prune
automaticamente.

Não realizar atualizações destrutivas.

Documentar quando será necessária
uma janela de manutenção.

---

## 41. Rollback

Preparar procedimento de rollback.

Considerar:

- Imagem anterior.
- Commit anterior.
- Configurações anteriores.
- Compatibilidade das migrations.
- Backup disponível.

Identificar as imagens por versão
ou commit Git, quando apropriado.

Não depender exclusivamente
de uma tag latest sobrescrita.

Não presumir que retornar o código
anterior reverte alterações no banco.

Não executar rollback destrutivo
automaticamente.

---

## 42. Testes obrigatórios

Criar ambiente local isolado
representativo de produção.

Utilizar dados e credenciais fictícios.

Validar:

- Build da imagem.
- Inicialização de banco vazio.
- Inicialização de banco existente.
- Migrations.
- Privilégios PostgreSQL.
- Usuário operacional sem superuser.
- Auditoria append-only.
- Assets.
- Formulário público.
- Agendamento.
- Login.
- Autorização.
- Dashboard.
- Atualização automática.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- No-show.
- Comprovante.
- QR Code.
- Histórico.
- Exportação Excel.
- Usuários.
- Healthchecks.
- Persistência de dados.
- Reinicialização de containers.
- Backup.
- Restauração.

Validar também:

- Ausência de credenciais na imagem.
- Ausência de montagem do código-fonte.
- Ausência de portas públicas do banco.
- Puma restrito ao loopback.
- Execução Rails sem root.
- Ausência de credenciais administrativas
  no web e worker.
- Ambiente de desenvolvimento preservado.

Não conectar à VPS durante os testes.

---

## 43. Testes específicos do domínio

Validar a configuração conceitual
de produção com:

    APP_HOST=dsvbooking.tech

Utilizar requisições locais controladas
com os cabeçalhos adequados.

Não depender de DNS público
para executar os testes locais.

Validar:

- Host autorizado.
- Hosts não autorizados.
- Reconhecimento de HTTPS.
- Cookies Secure.
- Redirecionamentos.
- Ausência de open redirect.
- Proteção contra Host Header Injection.
- Healthchecks internos.
- Funcionamento atrás do proxy reverso.

Não declarar testes externos
do domínio como concluídos.

---

## 44. Ferramentas de qualidade

Executar:

- Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Avaliar Trivy ou ferramenta equivalente
para análise da imagem de produção.

Revisar as proteções do RF017
afetadas pelas alterações.

Não ignorar vulnerabilidades
críticas ou altas confirmadas.

Registrar ferramentas indisponíveis,
limitações e testes não executados.

---

## 45. Validação Docker Compose

Validar a configuração de desenvolvimento.

Validar a configuração de produção.

Utilizar:

    docker compose config --quiet

quando houver risco de exposição
de segredos.

Comprovar a configuração efetiva.

Não apresentar configurações
resolvidas contendo senhas reais.

Confirmar ausência de:

- RAILS_ENV=development em produção.
- Montagem .:/rails em produção.
- PostgreSQL publicado no host.
- Puma publicado em todas as interfaces.
- Credenciais administrativas no web.
- Credenciais administrativas no worker.
- Bypass de autenticação.

---

## 46. Documentação

Criar ou atualizar:

    docs/requisitos/RF018.md

    docs/deploy/README.md

    docs/deploy/production.md

    docs/deploy/backup-restore.md

    docs/deploy/rollback.md

    deploy/nginx/dsvbooking.tech.conf.example

    deploy/postgres/

Atualizar README.md.

Registrar decisões relevantes
em docs/adr/.

Documentar todas as variáveis
do ambiente de produção.

Documentar todos os comandos
necessários para a VPS.

Não incluir credenciais reais.

---

## 47. Estrutura esperada

Estrutura conceitual:

    dsv-agendamentos/
        .agents/
        app/
        bin/
        config/
        db/
        deploy/
            nginx/
                dsvbooking.tech.conf.example
            postgres/
        docs/
            deploy/
        lib/
        test/
        compose.yaml
        compose.production.yaml
        Dockerfile
        Dockerfile.production
        .dockerignore
        .env.example
        .env.production.example
        .gitignore
        .ruby-version
        Gemfile
        Gemfile.lock
        README.md
        AGENTS.md

Adaptar conforme necessidade.

Não criar arquivos vazios
sem finalidade.

Não duplicar código de negócio.

---

## 48. Critérios de aceitação

- [ ] Desenvolvimento preservado.
- [ ] Compose de produção independente.
- [ ] Dockerfile de produção.
- [ ] Build reproduzível.
- [ ] Assets compilados.
- [ ] Rails executando sem root.
- [ ] Worker executando sem root.
- [ ] Banco sem porta pública.
- [ ] Puma restrito ao loopback.
- [ ] Usuário operacional sem superuser.
- [ ] Credenciais administrativas isoladas.
- [ ] Auditoria append-only preservada.
- [ ] Migrations controladas.
- [ ] Variáveis de produção documentadas.
- [ ] Domínio dsvbooking.tech configurável.
- [ ] SECRET_KEY_BASE segura.
- [ ] Segredos excluídos do Git.
- [ ] Segredos excluídos do build.
- [ ] Código incorporado à imagem.
- [ ] Volumes persistentes.
- [ ] Restart configurado.
- [ ] Healthchecks funcionais.
- [ ] Worker funcional.
- [ ] Rotação de logs.
- [ ] Bootstrap administrativo.
- [ ] Template Nginx definitivo.
- [ ] Validação ACME preservada.
- [ ] Procedimento Certbot documentado.
- [ ] Backup e restauração testados.
- [ ] Atualização documentada.
- [ ] Rollback documentado.
- [ ] Testes de regressão executados.
- [ ] Segurança do RF017 preservada.

---

## 49. Entrega final

Apresentar:

### Resumo

- Alterações realizadas.
- Problemas encontrados.
- Correções implementadas.
- Decisões técnicas.
- Arquitetura final.

### Arquivos

- Arquivos criados.
- Arquivos modificados.
- Arquivos removidos, quando aplicável.
- Justificativas.

### Docker

- Serviços.
- Imagens.
- Portas.
- Redes.
- Volumes.
- Usuários.
- Healthchecks.
- Políticas de restart.

### PostgreSQL

- Inicialização.
- Separação de credenciais.
- Privilégios.
- Migrations.
- Proteção da auditoria.

### Segurança

- Resultados das ferramentas.
- Vulnerabilidades encontradas.
- Correções.
- Riscos residuais.
- Impedimentos para publicação.

### Testes

- Comandos executados.
- Resultados reais.
- Testes.
- Assertions.
- Falhas.
- Erros.
- Limitações.

### Implantação

Entregar o roteiro exato
para execução manual na VPS.

Considerar:

    /opt/apps/dsv-agendamentos

    dsvbooking.tech

    189.24.17.159

Não incluir credenciais reais.

### Git

Apresentar:

    git status --short

Não realizar push automaticamente.

---

## 50. Fora do escopo

Não implementar:

- RF013.
- RF014.
- Upload de documentos.
- Power Automate.
- Novas funcionalidades operacionais.
- Redesign.
- Alteração de identidade visual.
- Redis.
- Sidekiq.
- Kubernetes.
- Microsserviços.
- Integrações externas não autorizadas.

Não realizar:

- Deploy real.
- Acesso SSH à VPS.
- Alteração real do Nginx.
- Alteração do DNS.
- Alteração do Cloudflare.
- Alteração do firewall.
- Emissão de certificados.
- Exclusão de volumes.
- Exclusão de dados.
- Reescrita do histórico Git.
- Push automático.

---

## 51. Regra de parada

Ao concluir o RF018, PARE.

Não acessar a VPS.

Não publicar a aplicação.

Não habilitar automaticamente
o acesso administrativo.

Não iniciar novos requisitos.

Entregar:

- Implementação.
- Testes.
- Documentação.
- Evidências.
- Comandos de implantação.

Classificar o resultado como:

    PREPARADO PARA IMPLANTAÇÃO

    PREPARADO COM RESSALVAS

    NÃO PREPARADO — CORREÇÕES NECESSÁRIAS

Não declarar implantação concluída.

A implantação efetiva será realizada
manualmente pelo responsável,
após homologação das alterações.