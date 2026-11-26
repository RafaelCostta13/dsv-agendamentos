# RF001 — Fundação da aplicação e preparação do ambiente de desenvolvimento

## 1. Objetivo

Inicializar a aplicação DSV Doca Agenda utilizando Ruby on Rails,
PostgreSQL, Puma e Docker.

Estabelecer uma base de desenvolvimento limpa, segura, funcional,
reproduzível e preparada para a implementação incremental dos
próximos requisitos.

Neste requisito, o objetivo é exclusivamente preparar a
infraestrutura e a estrutura inicial da aplicação.

Não implementar funcionalidades de negócio.

---

## 2. Documentação obrigatória

Antes de iniciar a implementação, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/requisitos/
- docs/referencias/
- compose.yaml
- .env.example

Respeitar as decisões arquiteturais existentes.

A implementação anterior da aplicação foi descartada.

Não reutilizar código, migrations, views, JavaScript ou outras
estruturas provenientes da implementação anterior.

Trabalhar exclusivamente dentro do repositório atual.

Caso existam inconsistências na documentação ou na configuração
inicial, identificar e documentar antes de prosseguir.

---

## 3. Stack tecnológica

Utilizar:

- Ruby.
- Ruby on Rails.
- PostgreSQL.
- Puma.
- HTML.
- ERB.
- CSS.
- Docker.
- Docker Compose.
- Minitest.

Utilizar versões estáveis, suportadas e compatíveis entre si.

Verificar a compatibilidade das versões antes de instalar
as dependências.

Fixar e documentar as versões utilizadas.

Utilizar as ferramentas e convenções nativas do Rails.

Não introduzir neste requisito:

- React.
- Vue.
- Angular.
- Next.js.
- Redis.
- Node.js.
- TypeScript.
- Microsserviços.
- Frameworks CSS externos.
- Bibliotecas JavaScript adicionais.

Não utilizar JavaScript personalizado neste requisito.

Caso o Rails inclua dependências frontend nativas, manter
apenas o necessário para a estrutura inicial da aplicação.

---

## 4. Arquitetura do ambiente

### 4.1 Desenvolvimento

O ambiente de desenvolvimento deverá utilizar:

    Navegador
        |
        v
    Rails + Puma
        |
        v
    PostgreSQL

A aplicação Rails e o PostgreSQL deverão ser executados
através do Docker Compose.

O acesso à aplicação será realizado diretamente pelo Puma.

Endereço padrão:

    http://localhost:3000

Não utilizar Nginx no ambiente de desenvolvimento.

### 4.2 Produção futura

Preservar a arquitetura definida nas ADRs:

    Internet
        |
        v
    Nginx instalado diretamente na VPS
        |
        v
    Rails + Puma em Docker
        |
        v
    PostgreSQL em Docker

Não instalar ou configurar o Nginx neste requisito.

Não criar um container Nginx.

A implantação em produção será tratada posteriormente.

---

## 5. Verificação do ambiente

Antes de inicializar a aplicação, verificar:

- Sistema operacional utilizado.
- Diretório atual.
- Raiz do repositório Git.
- Disponibilidade do Docker.
- Disponibilidade do Docker Compose.
- Versão do Docker.
- Versão do Docker Compose.
- Disponibilidade do daemon Docker.
- Disponibilidade da porta 3000.
- Estrutura dos arquivos existentes.

Consultar:

    docker --version
    docker compose version
    docker info
    git status --short

Não instalar automaticamente dependências no sistema
operacional do usuário.

Não exigir instalação local de Ruby ou PostgreSQL caso
seja possível realizar a inicialização através do Docker.

Caso exista algum impedimento no ambiente, apresentar
claramente o problema identificado.

Não alterar configurações globais do sistema operacional.

---

## 6. Inicialização do Ruby on Rails

Inicializar uma nova aplicação Ruby on Rails monolítica
na raiz do repositório atual.

Configurar PostgreSQL como banco de dados.

A aplicação deverá utilizar a estrutura MVC padrão do Rails.

Não utilizar Rails em modo API-only.

Preservar todos os arquivos da base inicial, principalmente:

- AGENTS.md
- README.md
- .agents/
- docs/
- compose.yaml
- .env.example
- .gitignore
- .dockerignore

Não criar uma segunda pasta de aplicação dentro do
repositório atual.

A estrutura esperada deverá ser semelhante a:

    dsv-doca-agenda/
    ├── .agents/
    ├── app/
    │   ├── assets/
    │   ├── controllers/
    │   ├── helpers/
    │   ├── models/
    │   └── views/
    ├── bin/
    ├── config/
    ├── db/
    ├── docs/
    ├── lib/
    ├── log/
    ├── public/
    ├── storage/
    ├── test/
    ├── tmp/
    ├── AGENTS.md
    ├── Dockerfile
    ├── compose.yaml
    ├── Gemfile
    ├── Gemfile.lock
    ├── README.md
    ├── .ruby-version
    ├── .env.example
    ├── .gitignore
    └── .dockerignore

A estrutura apresentada é uma referência.

Preservar os diretórios adicionais gerados pelas
convenções nativas da versão do Rails utilizada.

---

## 7. Configuração do Ruby

Definir a versão do Ruby utilizada pelo projeto.

Criar ou atualizar:

- .ruby-version
- Gemfile
- Gemfile.lock
- Dockerfile

Garantir compatibilidade entre:

- Ruby.
- Rails.
- Bundler.
- Puma.
- PostgreSQL.
- Dependências nativas.

A versão do Ruby deverá ser consistente entre o
Dockerfile e os arquivos de configuração do projeto.

Versionar o Gemfile.lock.

Não utilizar versões experimentais ou sem suporte.

---

## 8. Dockerfile

Criar o Dockerfile da aplicação.

O Dockerfile deverá:

- Utilizar uma imagem oficial do Ruby.
- Possuir versão definida.
- Instalar apenas as dependências necessárias.
- Instalar as gems através do Bundler.
- Possuir diretório de trabalho definido.
- Executar o Puma.
- Executar a aplicação com usuário não-root.
- Garantir permissões adequadas dos diretórios.
- Permitir a execução dos comandos Rails.
- Permitir a execução dos testes.
- Ser reproduzível.

Não utilizar a tag latest.

Não copiar arquivos .env reais para dentro da imagem.

Não copiar credenciais privadas para dentro da imagem.

Não instalar Node.js sem necessidade comprovada.

Não adicionar Nginx ao Dockerfile.

Não realizar operações de banco de dados durante
a construção da imagem.

A imagem deverá ser construída independentemente
da disponibilidade do PostgreSQL.

---

## 9. Docker Compose

Revisar e ajustar o compose.yaml existente.

O Docker Compose deverá possuir inicialmente apenas
dois serviços:

- web
- db

### 9.1 Serviço web

Responsável por executar:

- Ruby.
- Ruby on Rails.
- Puma.

Configurar:

- Build através do Dockerfile.
- Variáveis de ambiente.
- Diretório de trabalho.
- Dependência do PostgreSQL.
- Porta da aplicação.
- Volumes necessários ao desenvolvimento.
- Healthcheck da aplicação.

O Rails deverá iniciar em ambiente development.

Configurar o bind do Puma dentro do container para:

    0.0.0.0:3000

Publicar a porta no host utilizando loopback:

    127.0.0.1:3000:3000

Permitir configurar a porta publicada através de
variável de ambiente, quando necessário.

Não utilizar o servidor de desenvolvimento exposto
publicamente.

### 9.2 Serviço db

Responsável por executar o PostgreSQL.

Utilizar imagem oficial do PostgreSQL com versão definida.

Configurar:

- Nome do banco.
- Usuário.
- Senha.
- Volume persistente.
- Healthcheck.
- Rede interna.

Utilizar pg_isready ou mecanismo equivalente para
verificar a disponibilidade do PostgreSQL.

Não publicar a porta 5432 no host por padrão.

A comunicação entre Rails e PostgreSQL deverá ocorrer
através da rede interna do Docker Compose.

Utilizar o nome do serviço db como hostname do banco.

Não utilizar localhost para conectar o Rails ao
PostgreSQL a partir do container web.

### 9.3 Inicialização

O serviço web deverá aguardar a disponibilidade do
PostgreSQL antes de realizar operações dependentes do banco.

Configurar a inicialização de maneira previsível.

Não utilizar sleeps com tempos fixos como única
estratégia de espera pelo banco.

Não executar migrations simultaneamente em processos
concorrentes.

### 9.4 Restrições

Não adicionar:

- Nginx.
- Redis.
- Adminer.
- pgAdmin.
- Containers de monitoramento.
- Containers de frontend.
- Serviços externos desnecessários.

---

## 10. Volumes e persistência

Configurar um volume persistente para o PostgreSQL.

Nome de referência:

    postgres_data

Os dados deverão permanecer disponíveis após:

- Reinicialização dos containers.
- Recriação dos containers.
- Encerramento do Docker Compose.
- Reconstrução da imagem da aplicação.

Utilizar o caminho de armazenamento recomendado pela
imagem oficial da versão do PostgreSQL selecionada.

Preparar também a estrutura de storage da aplicação
conforme a ADR existente.

Nome de referência:

    rails_storage

Neste requisito, não implementar upload de arquivos.

Não instalar ou criar migrations do Active Storage
caso ainda não sejam necessárias.

O objetivo é preparar a infraestrutura de persistência,
sem antecipar funcionalidades futuras.

Não executar docker compose down -v sem autorização.

Não excluir volumes existentes.

---

## 11. Ambiente de desenvolvimento

Configurar o ambiente para permitir alterações no
código-fonte sem reconstruir a imagem a cada mudança.

Garantir:

- Reload de código no ambiente development.
- Atualização das views.
- Atualização dos arquivos CSS.
- Execução de comandos Rails dentro do container.
- Execução de migrations.
- Execução de testes.
- Acesso ao console Rails.
- Consulta aos logs.

Utilizar bind mounts quando apropriado.

Evitar conflitos entre arquivos do host e arquivos
instalados durante o build da imagem.

Garantir que os volumes não ocultem dependências
necessárias à execução da aplicação.

Evitar problemas de permissões nos arquivos gerados
pelo container.

Não utilizar chmod 777 como solução genérica.

Alterações no Gemfile poderão exigir atualização
das dependências ou reconstrução da imagem.

Documentar esse procedimento no README.md.

---

## 12. Variáveis de ambiente

Revisar e atualizar o arquivo .env.example.

Utilizar variáveis de ambiente para configurações
que possam variar entre ambientes.

Prever inicialmente:

- RAILS_ENV
- RAILS_PORT
- POSTGRES_HOST
- POSTGRES_PORT
- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD

Utilizar nomes consistentes entre:

- compose.yaml
- .env.example
- config/database.yml

Evitar configurações duplicadas ou conflitantes.

O arquivo .env.example deverá conter apenas valores
ilustrativos destinados ao desenvolvimento.

Não utilizar credenciais reais de produção.

Não versionar o arquivo .env real.

Não sobrescrever um arquivo .env existente sem
autorização.

Documentar como criar a configuração local a partir
do arquivo de exemplo.

Não exigir RAILS_MASTER_KEY para desenvolvimento
quando a aplicação não necessitar de credenciais
criptografadas nesse ambiente.

---

## 13. Configuração do banco de dados

Configurar:

    config/database.yml

Separar os ambientes:

- development.
- test.
- production.

### 13.1 Desenvolvimento

Utilizar PostgreSQL através do serviço db.

As credenciais deverão ser recebidas através das
variáveis de ambiente.

### 13.2 Testes

Criar um banco de dados independente do banco de
desenvolvimento.

Garantir que os testes não utilizem ou modifiquem
o banco de desenvolvimento.

Não utilizar o banco de produção para testes.

### 13.3 Produção

Manter a estrutura de configuração necessária para
futura implantação.

Não configurar credenciais reais.

Não iniciar o ambiente de produção neste requisito.

### 13.4 Validação

Executar a preparação dos bancos de desenvolvimento
e teste.

Utilizar os comandos nativos do Rails.

Validar:

- Conexão com PostgreSQL.
- Criação do banco de desenvolvimento.
- Criação do banco de teste.
- Execução das migrations existentes.
- Separação entre os ambientes.

Não criar tabelas de negócio neste requisito.

---

## 14. Configuração do Puma

Utilizar o Puma como servidor da aplicação Rails.

Revisar:

    config/puma.rb

Configurar:

- Porta da aplicação.
- Bind adequado ao ambiente Docker.
- Quantidade de threads compatível com o ambiente.
- Encerramento adequado do processo.
- Configuração consistente com o pool do banco de dados.

Priorizar a configuração padrão do Rails quando
ela atender corretamente ao ambiente.

Não realizar otimizações prematuras de desempenho.

Não adicionar servidores web alternativos.

Não iniciar múltiplos servidores Rails desnecessariamente.

Garantir que a aplicação possa ser reiniciada sem
conflitos com arquivos PID antigos.

---

## 15. Idioma e fuso horário

Configurar o idioma padrão da aplicação:

    pt-BR

Configurar o fuso operacional:

    America/Sao_Paulo

Utilizar a configuração nativa do Rails para representar
corretamente esse fuso horário.

Garantir que:

- A aplicação utilize o horário de São Paulo.
- Os timestamps sejam persistidos em UTC.
- Datas e horários sejam convertidos corretamente.
- O idioma padrão esteja disponível.
- A configuração não dependa do relógio do navegador.

Criar a estrutura inicial de traduções quando necessário.

Não implementar regras de horários de agendamento
neste requisito.

---

## 16. Página inicial

Criar uma página inicial simples para comprovar
o funcionamento da aplicação.

Configurar a rota raiz:

    GET /

A página deverá apresentar somente:

    DSV Doca Agenda

    Ambiente de desenvolvimento

    Aplicação inicializada com sucesso.

Utilizar:

- Controller Rails.
- View ERB.
- Layout padrão da aplicação.
- HTML semântico.
- CSS local simples, somente se necessário.

A página deverá ser renderizada pelo servidor.

Não utilizar JavaScript para renderizar o conteúdo.

Não adicionar:

- Dashboard.
- Sidebar.
- Cards operacionais.
- Gráficos.
- Menu de navegação complexo.
- Formulário de agendamento.
- Tela de login.
- Animações.
- Bibliotecas de componentes.

O objetivo é validar o funcionamento da estrutura MVC.

O design definitivo será tratado posteriormente.

---

## 17. Healthcheck

Disponibilizar a rota:

    GET /up

Utilizar preferencialmente o mecanismo nativo de
healthcheck do Rails.

A rota deverá responder HTTP 200 quando a aplicação
estiver operacional.

Criar também uma verificação simples de conectividade
com o PostgreSQL.

Rota de referência:

    GET /ready

Comportamento esperado:

- HTTP 200 quando o Rails conseguir consultar o banco.
- HTTP 503 quando o banco estiver indisponível.

A verificação deverá executar uma consulta simples
e não destrutiva ao PostgreSQL.

Não retornar:

- Credenciais.
- Nome de usuário do banco.
- Endereços internos.
- Stack traces.
- Informações sensíveis.
- Detalhes internos de exceções.

Diferenciar a disponibilidade do processo Rails
da disponibilidade do banco de dados.

Configurar os healthchecks dos containers de acordo
com suas respectivas responsabilidades.

---

## 18. Segurança inicial

Desde a inicialização da aplicação, preservar todas
as proteções nativas do Ruby on Rails.

Garantir:

- Proteção CSRF habilitada.
- Escaping padrão das views ERB.
- Configuração inicial de Content Security Policy.
- Filtragem de parâmetros sensíveis nos logs.
- Proteção de credenciais.
- Banco de dados não exposto publicamente.
- Aplicação publicada somente no loopback.
- Execução da aplicação com usuário não-root.

Não desabilitar mecanismos de segurança para facilitar
o desenvolvimento.

### 18.1 Content Security Policy

Estabelecer uma configuração inicial restritiva,
compatível com a página criada neste requisito.

Não permitir desnecessariamente:

- unsafe-eval.
- unsafe-inline para scripts.
- Scripts externos.
- Origens irrestritas.
- Plugins ou objetos executáveis.

Não utilizar curingas amplos apenas para eliminar
erros de configuração.

Validar a presença do cabeçalho CSP nas respostas
da aplicação.

A política deverá permitir futuras evoluções controladas
e documentadas conforme os requisitos.

### 18.2 JavaScript

Não criar código JavaScript personalizado.

Não adicionar:

- eval.
- new Function.
- innerHTML.
- document.write.
- Scripts inline.
- Scripts de CDNs.

Não utilizar JavaScript para executar verificações
de segurança.

### 18.3 Credenciais

Não versionar:

- .env real.
- config/master.key.
- Chaves privadas.
- Tokens.
- Senhas.
- Credenciais de banco.
- Documentos privados.

Não apresentar segredos nos logs ou nas comunicações de implementação.

---

## 19. Gitignore

Revisar o arquivo .gitignore existente.

Garantir que não sejam versionados:

- Arquivos .env reais.
- Credenciais locais.
- Chaves privadas.
- Logs gerados.
- Arquivos temporários.
- PID files.
- Arquivos enviados pelos usuários.
- Dependências locais desnecessárias.
- Artefatos de build desnecessários.

Preservar o versionamento de:

- Gemfile.
- Gemfile.lock.
- .ruby-version.
- .env.example.
- Dockerfile.
- compose.yaml.
- AGENTS.md.
- .agents/
- docs/
- Código-fonte.
- Migrations.
- Testes.

Preservar os arquivos .keep necessários à estrutura
dos diretórios.

Validar as regras de exclusão utilizando git check-ignore
quando aplicável.

Não remover arquivos não relacionados ao requisito.

---

## 20. Dockerignore

Revisar o arquivo .dockerignore.

Evitar enviar desnecessariamente para o contexto de build:

- .git/
- Arquivos .env reais.
- Chaves privadas.
- Logs.
- Arquivos temporários.
- Documentos enviados.
- Dependências instaladas localmente.
- Artefatos desnecessários.

Garantir que os arquivos necessários à construção
da aplicação permaneçam disponíveis.

Não excluir arquivos essenciais ao funcionamento
do Rails.

---

## 21. Ferramentas de qualidade

Preparar a base para análise de qualidade e segurança.

Utilizar, quando compatíveis com a versão do Rails:

- Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Caso alguma dessas ferramentas já esteja presente
na estrutura gerada pelo Rails, preservar sua configuração.

Não duplicar dependências.

Configurar as ferramentas necessárias para permitir
sua execução no ambiente Docker.

Não desabilitar verificações apenas para obter
resultados positivos.

Não criar listas de exceções de segurança sem justificativa.

Caso uma ferramenta não possa ser instalada ou executada,
documentar o motivo.

A revisão aprofundada de segurança será realizada
no requisito seguinte.

---

## 22. Testes automatizados

Utilizar inicialmente a estrutura nativa do Rails
com Minitest.

Criar testes de integração para validar a estrutura
inicial da aplicação.

### 22.1 Página inicial

Validar:

- GET / retorna HTTP 200.
- A página apresenta DSV Doca Agenda.
- A resposta é renderizada pelo Rails.

### 22.2 Healthcheck

Validar:

- GET /up retorna HTTP 200.
- GET /ready retorna HTTP 200 com banco disponível.
- GET /ready retorna HTTP 503 quando o banco está
  indisponível.

Simular a indisponibilidade do banco nos testes
quando apropriado, sem destruir dados ou interromper
desnecessariamente outros ambientes.

### 22.3 Configuração

Validar:

- Conexão com PostgreSQL.
- Ambiente de teste independente.
- Fuso horário configurado.
- Idioma padrão configurado.

### 22.4 Segurança

Validar:

- Cabeçalho Content Security Policy.
- Ausência de exposição de detalhes internos nas
  respostas de erro do healthcheck.
- Ausência de JavaScript personalizado desnecessário.

Não enfraquecer as proteções Rails para facilitar
a execução dos testes.

---

## 23. Validação prática do Docker

Executar a validação da infraestrutura criada.

### 23.1 Configuração

Executar:

    docker compose config --quiet

Garantir que a configuração seja válida.

Não incluir a saída de configurações com segredos
na resposta final.

### 23.2 Build

Executar:

    docker compose build

Garantir que a imagem seja construída sem erros.

### 23.3 Inicialização

Executar:

    docker compose up -d

Validar:

    docker compose ps

Confirmar que os serviços web e db estão operacionais.

### 23.4 Banco

Preparar o banco através dos comandos nativos do Rails.

Comando de referência:

    docker compose exec web bin/rails db:prepare

O procedimento deverá ser adequado à estratégia de
inicialização adotada.

### 23.5 Aplicação

Validar:

    curl -i http://localhost:3000/
    curl -i http://localhost:3000/up
    curl -i http://localhost:3000/ready

As rotas deverão responder corretamente.

### 23.6 Testes

Executar:

    docker compose exec web bin/rails test

Executar também as ferramentas de qualidade e segurança
configuradas no projeto.

### 23.7 Reinicialização

Validar o comportamento após:

    docker compose restart

Confirmar que os serviços voltam a funcionar.

### 23.8 Persistência

Validar que o banco permanece disponível após
encerramento e recriação dos containers.

Realizar o teste utilizando dados descartáveis e
sem criar tabelas de negócio permanentes.

Não remover volumes durante o teste.

Não comprometer dados existentes.

---

## 24. Documentação

Atualizar o README.md.

O README deverá conter:

### 24.1 Informações do projeto

- Nome da aplicação.
- Objetivo.
- Arquitetura.
- Stack tecnológica.
- Versões utilizadas.

### 24.2 Pré-requisitos

- Docker.
- Docker Compose.
- Git.
- Outros pré-requisitos efetivamente necessários.

### 24.3 Configuração inicial

Documentar:

- Preparação do arquivo .env.
- Build dos containers.
- Inicialização da aplicação.
- Preparação do banco.
- Endereço de acesso.

### 24.4 Comandos de desenvolvimento

Documentar os comandos para:

- Iniciar os containers.
- Encerrar os containers.
- Reiniciar os containers.
- Reconstruir a imagem.
- Consultar os logs.
- Acessar o console Rails.
- Executar migrations.
- Executar testes.
- Executar Brakeman.
- Executar Bundler Audit.
- Executar RuboCop.
- Acessar o PostgreSQL pelo container.

Documentar somente comandos compatíveis com a
implementação realizada.

### 24.5 Persistência

Documentar:

- Volumes utilizados.
- Persistência do PostgreSQL.
- Estrutura de storage.
- Cuidados ao remover containers.
- Riscos associados à exclusão de volumes.

### 24.6 Produção

Informar que:

- O Nginx será instalado diretamente na VPS.
- O Nginx não faz parte do Docker Compose.
- O ambiente de produção ainda não foi implantado.
- A configuração definitiva de produção será
  tratada em requisito específico.

---

## 25. ADRs

Revisar as ADRs existentes em:

    docs/adr/

Preservar as decisões aprovadas:

- Arquitetura monolítica Rails.
- PostgreSQL.
- Docker.
- Puma.
- Nginx instalado diretamente na VPS.
- Active Storage com persistência futura.

Registrar novas decisões arquiteturais somente
quando forem necessárias.

Não criar ADRs para decisões triviais de implementação.

Não modificar silenciosamente decisões já aprovadas.

Documentar as escolhas de versões e dependências
no README ou em ADR quando arquiteturalmente relevante.

Registrar as decisões do RF001 em uma ADR objetiva em `docs/adr/`.
Não criar documento adicional de entrega em `docs/requisitos/`.

Atualizar o índice de requisitos, se existente.

---

## 26. Critérios de aceite

### 26.1 Estrutura

- [ ] Aplicação Rails inicializada na raiz do repositório.
- [ ] Estrutura MVC padrão preservada.
- [ ] Documentação inicial preservada.
- [ ] Skills existentes preservadas.
- [ ] ADRs existentes respeitadas.
- [ ] Gemfile criado.
- [ ] Gemfile.lock criado.
- [ ] Versão do Ruby definida.

### 26.2 Docker

- [ ] Dockerfile funcional.
- [ ] Docker Compose válido.
- [ ] Serviço web operacional.
- [ ] Serviço db operacional.
- [ ] Apenas web e db no Docker Compose.
- [ ] Nenhum container Nginx.
- [ ] Imagens com versões definidas.
- [ ] Aplicação executada com usuário não-root.
- [ ] Reload de código funcional no desenvolvimento.
- [ ] Healthchecks configurados.

### 26.3 Banco de dados

- [ ] PostgreSQL operacional.
- [ ] Rails conectado ao PostgreSQL.
- [ ] Banco de desenvolvimento configurado.
- [ ] Banco de teste independente.
- [ ] Migrations existentes executadas.
- [ ] Volume persistente configurado.
- [ ] Persistência validada.
- [ ] Porta do PostgreSQL não publicada no host.

### 26.4 Aplicação

- [ ] Puma operacional.
- [ ] Aplicação acessível em localhost:3000.
- [ ] Porta publicada somente no loopback.
- [ ] Página inicial responde HTTP 200.
- [ ] Rota /up funcional.
- [ ] Rota /ready funcional.
- [ ] Fuso America/Sao_Paulo configurado.
- [ ] Idioma pt-BR configurado.
- [ ] Nenhuma funcionalidade de negócio implementada.

### 26.5 Segurança

- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy configurada.
- [ ] Escaping padrão do ERB preservado.
- [ ] Parâmetros sensíveis filtrados nos logs.
- [ ] Credenciais protegidas.
- [ ] Arquivos .env reais ignorados pelo Git.
- [ ] Chaves privadas ignoradas pelo Git.
- [ ] Nenhum JavaScript personalizado criado.
- [ ] Nenhuma dependência frontend desnecessária.
- [ ] Nenhuma vulnerabilidade conhecida crítica
      ou alta sem tratamento.

### 26.6 Testes e qualidade

- [ ] Testes automatizados criados.
- [ ] Testes automatizados executados.
- [ ] Testes aprovados.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.
- [ ] Reinicialização dos containers validada.
- [ ] Limitações e pendências documentadas.

### 26.7 Documentação

- [ ] README atualizado.
- [ ] Versões utilizadas documentadas.
- [ ] Comandos de desenvolvimento documentados.
- [ ] Persistência documentada.
- [ ] Decisões do RF001 registradas em ADR objetiva.
- [ ] ADRs revisadas.

---

## 27. Fora do escopo

Não implementar neste requisito:

- Autenticação.
- Login.
- Logout.
- Cadastro de usuários.
- Recuperação de senha.
- Perfis de acesso.
- Controle de permissões.
- Dashboard.
- Sidebar.
- Layout definitivo.
- Cadastro de docas.
- Cadastro de janelas.
- Cadastro de veículos.
- Cadastro de motoristas.
- Agendamento de veículos.
- Motor de disponibilidade.
- Check-in.
- Liberação de veículos.
- Cancelamento.
- Reagendamento.
- Auditoria operacional.
- QR Code.
- Notificações por e-mail.
- Exportação Excel.
- Active Storage funcional.
- Upload de documentos.
- Integração com WhatsApp.
- API de negócio.
- JavaScript personalizado.
- Turbo Streams personalizados.
- WebSockets.
- Instalação do Nginx.
- Configuração de domínio.
- Certificados HTTPS.
- Implantação na VPS.
- Migração de dados da aplicação anterior.

Não antecipar funcionalidades dos próximos requisitos.

---

## 28. Entrega

Registrar somente uma ADR objetiva em `docs/adr/`, criando ou atualizando
uma ADR pertinente ao requisito, com contexto, decisão e consequências relevantes.
Não criar relatório de implementação, registro paralelo do RF, inventário de arquivos
ou reprodução dos critérios de aceite em outro documento.

Na resposta final, informar brevemente o que mudou, os testes executados
e eventuais impedimentos reais. Não inventar resultados nem declarar
concluída uma validação que não foi executada.

---

## 29. Regra de parada

Ao finalizar o RF001, PARE.

Não implementar o RF002.

Não iniciar funcionalidades de negócio.

Não iniciar o desenvolvimento da interface definitiva.

Deixar o ambiente de desenvolvimento operacional
para homologação.

Aguardar novas instruções.