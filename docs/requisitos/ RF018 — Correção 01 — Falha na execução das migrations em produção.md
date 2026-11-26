# RF018 — Correção 01 — Falha na execução das migrations em produção

## 1. Contexto

Durante a primeira implantação da aplicação DSV Doca Agenda
na VPS de produção, foram concluídas com sucesso as seguintes etapas:

- Configuração do ambiente de produção.
- Geração das credenciais.
- Inicialização do PostgreSQL 17.12.
- Criação dos três usuários do PostgreSQL.
- Validação dos privilégios administrativos.
- Configuração do TRUSTED_PROXY_CIDRS.
- Build da imagem Docker de produção.
- Validação do usuário non-root 10001:10001.

Entretanto, durante a execução do comando:

    docker compose \
      --env-file .env.production \
      -f compose.production.yaml \
      up -d web worker

O serviço migrate encerrou com exit code 1.

O Docker Compose bloqueou corretamente a inicialização
dos serviços web e worker.

## 2. Erro identificado

Logs apresentados pelo serviço migrate:

    /home/rails is not writable.
    Bundler will use /tmp/bundler... as your home directory temporarily.
    bin/rails aborted!
    failed to execute:
    psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc
    --output /dev/null --file /rails/db/structure.sql
    dsv_doca_agenda_production

    Tasks: TOP => db:migrate

## 3. Hipótese de causa raiz

O Dockerfile.production instala a biblioteca libpq5
no estágio de runtime, mas aparentemente não instala
o cliente de linha de comando PostgreSQL (psql).

A aplicação utiliza db/structure.sql.

O Rails depende do executável psql para carregar
essa estrutura durante a preparação inicial do banco.

Confirmar tecnicamente essa hipótese antes de implementar
a correção.

## 4. Correção obrigatória

Analisar o Dockerfile.production e:

- Instalar um cliente PostgreSQL compatível com o
  PostgreSQL 17.12 utilizado em produção.
- Verificar a versão disponibilizada pelos repositórios
  da distribuição da imagem base.
- Preferir um cliente da mesma versão major do servidor.
- Garantir que psql esteja disponível no PATH.
- Verificar a necessidade de disponibilizar pg_dump,
  considerando o uso de structure.sql pelo Rails.
- Não instalar o servidor PostgreSQL na imagem Rails.
- Manter a imagem multi-stage.
- Evitar dependências desnecessárias.
- Preservar a execução non-root.

Caso sejam identificados outros problemas no processo
de carregamento de structure.sql, investigar e corrigir
a causa raiz sem elevar os privilégios desnecessariamente.

## 5. Corrigir aviso do Bundler

Investigar o aviso:

    /home/rails is not writable.

Configurar uma localização temporária gravável para
os arquivos que o Bundler efetivamente necessita.

Utilizar os diretórios tmpfs já existentes, quando adequado.

Garantir:

- Compatibilidade com filesystem read-only.
- Compatibilidade com UID/GID 10001.
- Nenhuma necessidade de executar como root.
- Nenhuma alteração desnecessária no BUNDLE_PATH.
- Nenhuma instalação de gems durante o runtime.
- Nenhum novo volume persistente desnecessário.

## 6. Preservar os controles de segurança

Não remover ou enfraquecer:

- read_only: true.
- cap_drop: ALL.
- no-new-privileges.
- Usuário non-root.
- Separação dos usuários PostgreSQL.
- Restrições do usuário runtime.
- Rede interna Docker.
- Proteções das tabelas de auditoria.
- Dependência obrigatória do serviço migrate.
- ADMIN_ACCESS_ENABLED=false.
- Proteção dos arquivos de credenciais.
- Publicação exclusiva da porta Rails no loopback.

## 7. Restrições relacionadas ao banco

O banco de produção já foi inicializado.

Portanto, a correção deve permitir uma nova tentativa
de execução das migrations sobre o volume existente.

Não executar ou recomendar:

- docker compose down -v.
- docker volume rm.
- rails db:drop.
- rails db:reset.
- Exclusão do banco existente.
- Recriação desnecessária dos usuários.
- Regeneração das credenciais.
- Concessão de privilégios de superuser ao migrator.
- Concessão de privilégios administrativos ao runtime.

Verificar se uma tentativa parcialmente executada de
carregamento da estrutura pode deixar objetos no banco.

Documentar um procedimento seguro de diagnóstico e
recuperação caso essa situação seja identificada.

## 8. Testes obrigatórios

Executar os testes em ambiente local isolado,
utilizando a configuração real de produção.

### Teste 01 — Build

Construir a imagem utilizando Dockerfile.production.

Confirmar:

- Build concluído.
- Assets compilados.
- Usuário 10001:10001.
- Cliente PostgreSQL disponível.

### Teste 02 — Cliente PostgreSQL

Validar:

    command -v psql
    psql --version
    pg_dump --version

### Teste 03 — Primeira inicialização

Utilizar um banco PostgreSQL novo exclusivamente
no ambiente local de testes.

Validar:

- Inicialização do banco.
- Criação dos usuários.
- Carregamento de structure.sql.
- Execução das migrations.
- Execução de production:grant_runtime.
- Serviço migrate encerrado com exit code 0.
- Inicialização do web.
- Inicialização do worker.

### Teste 04 — Reexecução

Executar novamente o serviço migrate sobre o mesmo banco.

Confirmar:

- Execução bem-sucedida.
- Ausência de duplicação de registros.
- Preservação dos dados.
- Preservação dos privilégios.
- Ausência de operações destrutivas.

### Teste 05 — Segurança

Confirmar:

- Runtime non-root.
- Filesystem read-only.
- Ausência de privilégios administrativos no runtime.
- Restrições de alteração da auditoria.
- Ausência de credenciais reais na imagem.
- Ausência de credenciais reais nos logs.

### Teste 06 — Healthchecks

Validar:

- PostgreSQL healthy.
- Web healthy.
- Endpoint /up retornando HTTP 200.
- Endpoint /ready retornando HTTP 200.
- Worker em execução.
- Funcionamento da comunicação entre o host e
  a porta publicada do Rails.

### Teste 07 — Regressão

Executar a suíte de testes existente e as ferramentas
de análise de segurança e qualidade do projeto.

## 9. Documentação

Atualizar, quando necessário:

- docs/requisitos/RF018.md
- docs/deploy/production.md
- Dockerfile.production
- Demais arquivos diretamente relacionados à correção.

Registrar:

- Causa raiz confirmada.
- Arquivos alterados.
- Versão do cliente PostgreSQL.
- Testes executados.
- Resultados efetivamente obtidos.
- Riscos ou pendências identificados.
- Procedimento seguro para atualizar a VPS.
- Atualização do IMAGE_TAG para o novo commit.

## 10. Critérios de aceite

A correção será considerada concluída somente quando:

- O cliente PostgreSQL estiver disponível.
- A estrutura SQL for carregada corretamente.
- O serviço migrate encerrar com exit code 0.
- Web e worker iniciarem corretamente.
- Os healthchecks forem aprovados.
- Os controles de segurança forem preservados.
- A reexecução das migrations for segura.
- Nenhum dado existente for perdido.

## 11. Encerramento

Não realizar deploy na VPS.
Não acessar o banco de produção.
Não realizar push automaticamente.
Não avançar para outro requisito funcional.

Apresentar o relatório técnico da correção e aguardar
a homologação do responsável pelo projeto.