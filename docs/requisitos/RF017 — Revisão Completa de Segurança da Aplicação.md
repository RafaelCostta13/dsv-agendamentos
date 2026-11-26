# RF017 — Revisão Completa de Segurança da Aplicação

## 1. Objetivo

Realizar uma revisão abrangente de segurança da aplicação
DSV Doca Agenda antes da implantação em produção.

Assumir o papel de engenheiro de segurança de aplicações,
com experiência em Ruby on Rails, PostgreSQL, segurança
web, Docker e infraestrutura Linux.

O objetivo deste requisito não é somente executar
ferramentas automatizadas de análise.

É necessário:

- Inspecionar o código-fonte.
- Identificar vulnerabilidades.
- Identificar configurações inseguras.
- Identificar falhas de autorização.
- Identificar riscos de exposição de dados.
- Identificar falhas nas regras de negócio.
- Avaliar mecanismos de concorrência.
- Corrigir os problemas identificados.
- Criar testes de segurança e regressão.
- Documentar as evidências.
- Preparar a aplicação para produção.

Preservar todas as funcionalidades implementadas.

Requisitos implementados:

    RF001 até RF012
    RF015
    RF016

Requisitos suspensos:

    RF013 — Upload e armazenamento de documentos.
    RF014 — Notificações por e-mail via Power Automate.

Não implementar RF013 ou RF014.

Não realizar implantação em produção.

O RF018 será responsável pela implantação na VPS.

---

## 2. Regras obrigatórias de execução

Antes de iniciar:

- Consultar AGENTS.md.
- Consultar README.md.
- Consultar .agents/skills/.
- Consultar docs/adr/.
- Consultar docs/database/.
- Consultar docs/requisitos/.
- Consultar docs/referencias/.

Utilizar especialmente as orientações da skill
de segurança existente no repositório.

Trabalhar exclusivamente dentro do repositório atual.

Não acessar outros projetos.

Não realizar testes contra servidores externos.

Não realizar testes contra infraestrutura corporativa.

Não utilizar dados reais de colaboradores,
transportadoras ou clientes durante os testes.

Utilizar exclusivamente ambientes controlados,
locais e autorizados.

Não realizar ações destrutivas sobre dados existentes.

Não excluir volumes Docker.

Não executar comandos de limpeza indiscriminada.

Não desabilitar proteções para fazer testes passarem.

Não alterar regras de negócio homologadas sem
justificativa técnica e documentação.

Não declarar uma vulnerabilidade corrigida
sem evidências suficientes.

---

## 3. Metodologia

Utilizar como referências:

- OWASP Top 10.
- OWASP ASVS.
- OWASP Cheat Sheet Series.
- OWASP Web Security Testing Guide.
- CWE, quando aplicável.
- Guia oficial de segurança do Ruby on Rails.
- Documentação oficial do PostgreSQL.
- Documentação oficial do Docker.

Consultar as versões oficiais aplicáveis
no momento da execução.

Utilizar os controles relevantes do OWASP ASVS
nível 2 como referência de avaliação.

Não declarar certificação ou conformidade integral
com ASVS sem verificar todos os controles aplicáveis.

Dividir o trabalho em cinco etapas:

    Etapa 1 — Inventário e análise de riscos.

    Etapa 2 — Identificação de vulnerabilidades.

    Etapa 3 — Correção das vulnerabilidades.

    Etapa 4 — Testes e validação.

    Etapa 5 — Relatório final de segurança.

Registrar evidências em todas as etapas.

---

## 4. Inventário da aplicação

Identificar os componentes existentes:

- Versão do Ruby.
- Versão do Rails.
- Versão do PostgreSQL.
- Versão do Puma.
- Versão do Docker.
- Bibliotecas Ruby instaladas.
- Bibliotecas JavaScript.
- Sistema de assets.
- Processamento em segundo plano.
- Rotas públicas.
- Rotas administrativas.
- Models.
- Controllers.
- Services.
- Jobs.
- Migrations.
- Configurações de ambiente.
- Variáveis de ambiente.
- Volumes persistentes.

Identificar componentes descontinuados
ou sem suporte de segurança.

Verificar quais versões estão efetivamente
instaladas e em execução.

Não utilizar somente as versões declaradas
na documentação.

Não atualizar indiscriminadamente toda
a aplicação para versões mais recentes.

---

## 5. Modelagem de ameaças

Elaborar uma análise simplificada de ameaças.

Identificar:

- Ativos que precisam ser protegidos.
- Pontos de entrada.
- Fronteiras de confiança.
- Dados pessoais.
- Dados operacionais.
- Credenciais.
- Sessões.
- Processos automáticos.
- Dependências externas.
- Possíveis agentes de ameaça.

Considerar os seguintes cenários:

- Participante público mal-intencionado.
- Bot automatizado.
- Usuário autenticado com perfil Consulta.
- Operador tentando exceder suas permissões.
- Conta administrativa comprometida.
- Sessão roubada.
- Requisições concorrentes.
- Falha de infraestrutura.
- Dependência vulnerável.

Avaliar os impactos sobre:

- Confidencialidade.
- Integridade.
- Disponibilidade.
- Rastreabilidade.

Documentar os riscos identificados.

---

## 6. Mapeamento de endpoints

Executar o comando equivalente a:

    bin/rails routes

Utilizar o ambiente Docker existente.

Criar um inventário de todas as rotas.

Para cada rota, registrar:

- Método HTTP.
- Caminho.
- Controller.
- Action.
- Necessidade de autenticação.
- Perfis autorizados.
- Parâmetros aceitos.
- Dados retornados.
- Possíveis alterações no banco.
- Proteção CSRF.
- Rate limiting, quando aplicável.

Identificar:

- Rotas não utilizadas.
- Rotas duplicadas.
- Rotas administrativas desprotegidas.
- Rotas de diagnóstico expostas.
- Rotas de desenvolvimento.
- Endpoints de teste.
- Endpoints que expõem informações sensíveis.

Não remover rotas funcionais sem verificar
suas dependências e testes.

---

## 7. Revisão da área pública

Analisar todas as rotas utilizadas pelo
formulário público.

Principalmente:

    /agendar

E seus endpoints auxiliares.

Verificar:

- Validação dos campos.
- Validação de datas.
- Validação de docas.
- Validação de janelas.
- Validação do tipo de operação.
- Validação de nota fiscal.
- Validação de placa.
- Validação de disponibilidade.
- Idempotência.
- Proteção CSRF.
- Proteção contra abuso.
- Proteção contra exposição de dados.

Garantir que o formulário público
não consiga modificar atributos administrativos.

Exemplos de atributos protegidos:

    status
    protocol
    checkin_at
    released_at
    release_remark
    change_reason
    actor_user_id
    lock_version

Não confiar nos valores enviados
pelo navegador.

Toda regra de negócio deverá ser
validada novamente no backend.

---

## 8. Proteção contra abuso do formulário

O formulário público estará acessível
através da internet.

Avaliar a possibilidade de:

- Criação automatizada de reservas.
- Esgotamento artificial das posições disponíveis.
- Envio repetitivo de formulários.
- Requisições excessivas de disponibilidade.
- Consumo excessivo de CPU.
- Consumo excessivo de memória.
- Crescimento excessivo do banco.
- Preenchimento com dados fictícios.

Avaliar os controles existentes.

Implementar rate limiting no backend
para os endpoints públicos quando necessário.

Diferenciar:

- Consulta de disponibilidade.
- Abertura do formulário.
- Tentativa de criação.
- Criação efetivamente confirmada.

Não contabilizar atualizações idempotentes
como novas reservas confirmadas.

Não utilizar somente controles em JavaScript.

Não depender exclusivamente do Cloudflare.

Não introduzir Redis exclusivamente
para rate limiting.

Utilizar os mecanismos compartilhados
existentes ou uma solução compatível
com PostgreSQL.

Definir limites iniciais fundamentados
no fluxo operacional.

Considerar transportadoras que realizam
múltiplas reservas legítimas.

Considerar usuários que compartilham
o mesmo endereço IP.

Não aplicar restrições excessivamente
agressivas sem evidências.

Documentar os limites e riscos residuais.

Avaliar CAPTCHA ou Cloudflare Turnstile
como proteção complementar futura.

Não introduzir dependência externa de CAPTCHA
sem aprovação específica.

---

## 9. Proteção contra SQL Injection

Revisar todo o código Ruby relacionado
a consultas SQL e Active Record.

Pesquisar especialmente:

- find_by_sql.
- execute.
- exec_query.
- Arel.sql.
- where com interpolação de strings.
- order com parâmetros não confiáveis.
- joins construídos dinamicamente.
- select com valores externos.
- group com parâmetros externos.

Verificar consultas utilizadas em:

- Agendamentos.
- Disponibilidade.
- Dashboard.
- Bloqueios.
- Histórico.
- Exportação Excel.
- Usuários.
- Autenticação.
- Sessões.
- Rate limiting.

Utilizar consultas parametrizadas.

Utilizar listas explícitas para:

- Ordenação.
- Campos pesquisáveis.
- Tipos de entidades.
- Estados.
- Perfis.

Não confiar em escaping manual
como única proteção.

Criar testes demonstrando que entradas
manipuladas não alteram o significado
das consultas SQL.

Executar os testes exclusivamente
contra o banco local de teste.

---

## 10. Proteção contra XSS

Revisar todas as views ERB.

Pesquisar utilizações de:

    raw
    html_safe
    safe_concat
    conteúdo HTML construído manualmente

Verificar a apresentação de:

- Nome do responsável.
- Empresa.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Motivos de alteração.
- Observações de liberação.
- Motivos de bloqueio.
- Nomes de usuários.
- E-mails.
- Eventos de auditoria.
- Mensagens de erro.
- Parâmetros de pesquisa.

Garantir que conteúdo não confiável
seja tratado como texto.

Avaliar:

- Stored XSS.
- Reflected XSS.
- DOM-based XSS.

Revisar também:

- Data attributes.
- Conteúdo JSON inserido em HTML.
- Atributos de links.
- Atributos de imagens.
- Conteúdo SVG.
- Turbo Frames.
- Componentes Stimulus.

Não remover caracteres legítimos
dos dados apenas para evitar XSS.

Priorizar escaping e tratamento
correto no contexto de saída.

---

## 11. Revisão completa do JavaScript

Inspecionar todos os arquivos JavaScript
da aplicação.

Considerar especialmente:

- Formulário público.
- Seleção de datas.
- Seleção de docas.
- Seleção de horários.
- Consulta de disponibilidade.
- Atualização automática do Dashboard.
- Menu do usuário.
- Visualização de senha.
- Tratamento da sessão expirada.

Pesquisar:

    eval
    new Function
    document.write
    innerHTML
    outerHTML
    insertAdjacentHTML
    handlers inline

Verificar se dados não confiáveis
alcançam operações inseguras de DOM.

Substituir construções inseguras
por mecanismos apropriados.

Priorizar:

    textContent
    createElement
    atributos controlados
    renderização ERB
    mecanismos seguros do Turbo e Stimulus

Não introduzir bibliotecas frontend
desnecessárias.

Não mover regras de segurança
do backend para o JavaScript.

Não considerar validação no navegador
uma proteção suficiente.

---

## 12. Content Security Policy

Revisar a CSP existente.

Avaliar as diretivas aplicáveis:

    default-src
    script-src
    style-src
    img-src
    font-src
    connect-src
    object-src
    base-uri
    form-action
    frame-ancestors

Priorizar origens estritamente necessárias.

Avaliar a adoção de:

    default-src 'self'

    object-src 'none'

    base-uri 'self'

    form-action 'self'

    frame-ancestors 'none'

Adaptar à arquitetura efetivamente utilizada.

Verificar compatibilidade com:

- Assets do Rails.
- Turbo.
- Stimulus.
- QR Code.
- Formulários.
- Dashboard.
- Login.

Não introduzir unsafe-eval.

Não permitir scripts inline arbitrários.

Caso sejam necessários nonces,
utilizar os mecanismos apropriados do Rails.

Não ampliar indiscriminadamente
as origens permitidas.

Verificar a política efetivamente retornada
nas respostas HTTP.

Não manter somente uma política
Report-Only como proteção definitiva.

---

## 13. Proteção CSRF

Revisar todas as operações de escrita.

Incluindo:

- Criação de agendamentos.
- Login.
- Logout.
- Alteração de senha.
- Cadastro de usuários.
- Edição de usuários.
- Ativação.
- Desativação.
- Redefinição de senha.
- Check-in.
- Liberação.
- Cancelamento.
- Alteração.
- Reagendamento.
- Bloqueio.
- Desbloqueio.

Pesquisar desativações de proteção:

    skip_forgery_protection

    skip_before_action

    protect_from_forgery

Verificar a necessidade de cada exceção.

Não permitir alterações de estado
através de requisições GET.

Testar requisições:

- Sem token CSRF.
- Com token incorreto.
- Com token de outro contexto.
- Com método HTTP inesperado.

Realizar testes com a proteção CSRF
efetivamente habilitada.

Não considerar suficiente um teste
executado em ambiente onde a proteção
esteja automaticamente desabilitada.

---

## 14. Mass Assignment

Revisar os Strong Parameters
de todos os controllers.

Garantir listas explícitas
de atributos permitidos.

Pesquisar:

    permit!

    parâmetros convertidos diretamente em Hash

    atribuição de todos os atributos recebidos

    serialização integral de models

Impedir alteração indevida de:

    id
    status
    protocol
    request_id
    password_digest
    role
    active
    must_change_password
    actor_user_id
    created_at
    updated_at
    revoked_at
    expires_at

Considerar que determinados atributos
são legítimos apenas em operações
administrativas específicas.

Exemplo:

    role pode ser alterado por administrador
    através do fluxo autorizado de usuários.

    role não pode ser alterado pelo próprio
    usuário através da página Meu perfil.

Criar testes de manipulação de parâmetros.

---

## 15. Autenticação

Revisar integralmente o RF016.

Verificar:

- Normalização de e-mail.
- Verificação de senha.
- Rejeição de usuários inativos.
- Tratamento de credenciais incorretas.
- Proteção contra enumeração de contas.
- Geração de sessões.
- Renovação de sessão após login.
- Expiração.
- Revogação.
- Logout.
- Primeiro acesso.
- Redefinição de senha.
- Alteração da própria senha.

Garantir que nenhuma rota administrativa
possa ser acessada sem autenticação.

Verificar explicitamente:

- Requisições HTML.
- Requisições Turbo.
- Requisições JSON, quando existentes.
- Downloads.
- Exportações.
- Endpoints de atualização automática.

Não permitir autenticação através
de atributos fornecidos pelo navegador.

---

## 16. Segurança das senhas

Revisar o armazenamento de senhas.

Verificar:

- Utilização de has_secure_password.
- Utilização de bcrypt ou mecanismo aprovado.
- Custo de hashing.
- Comprimento mínimo.
- Limite técnico de bytes.
- Tratamento de Unicode.
- Ausência de truncamento silencioso.
- Confirmação de senha.
- Redefinição administrativa.
- Troca obrigatória.

Preservar a política homologada no RF015.

Comparar a política existente
com as recomendações atuais de segurança.

Caso sejam identificadas limitações,
documentar as recomendações.

Não realizar migração criptográfica
complexa ou incompatível sem necessidade.

Não registrar:

- Senhas.
- Confirmações.
- Password digests.
- Credenciais temporárias.

Verificar se existem senhas previsíveis
em seeds, migrations ou scripts operacionais.

Avaliar a necessidade de uma política
contra senhas comuns ou comprometidas.

Não transmitir senhas a serviços externos.

---

## 17. Proteção contra força bruta

Revisar o rate limiting do RF016.

Definições anteriormente previstas:

    Por e-mail:
        5 falhas em 15 minutos.

    Por IP:
        30 tentativas em 15 minutos.

Verificar a configuração efetivamente
implementada.

Testar:

- Múltiplas tentativas.
- E-mails inexistentes.
- Solicitações concorrentes.
- Expiração dos contadores.
- Múltiplos processos.
- Manipulação de cabeçalhos de IP.
- Tentativas distribuídas.
- Crescimento dos registros de controle.

Garantir que as proteções funcionem
antes de operações criptográficas
desnecessariamente custosas.

Verificar o risco de bloqueio temporário
de contas legítimas por terceiros.

Não criar bloqueios permanentes
como resposta automática.

Documentar os riscos residuais.

---

## 18. Segurança das sessões

Revisar a implementação de sessões.

Verificar:

- Entropia dos tokens.
- Armazenamento seguro.
- Ausência de tokens em texto simples
  no banco de dados.
- Expiração absoluta.
- Expiração por inatividade.
- Revogação.
- Session Fixation.
- Reutilização de sessões antigas.
- Múltiplas sessões.
- Concorrência.

Preservar as definições do RF016:

    Inatividade máxima: 30 minutos.

    Expiração absoluta: 12 horas.

Verificar se a revogação ocorre
após:

- Alteração de senha.
- Redefinição administrativa.
- Desativação.
- Alteração de perfil.
- Alteração de e-mail.

Testar login concorrente com
redefinição de senha.

Garantir que credenciais antigas
não possam criar sessões válidas
após a conclusão da redefinição.

---

## 19. Segurança dos cookies

Verificar cookies administrativos
e demais cookies relevantes.

Em produção, avaliar:

    HttpOnly

    Secure

    SameSite

    Path

    Domain

    Expiração

Preferir cookies host-only.

Evitar compartilhamento desnecessário
entre subdomínios.

Não armazenar senhas, perfis ou estados
de autorização diretamente em cookies.

Garantir que cookies adulterados
não produzam autenticação válida.

Verificar a interação entre:

- Cookie de autenticação.
- Sessão do Rails.
- Proteção CSRF.
- Formulário público.
- Comprovante.

Não enfraquecer a configuração
de produção para facilitar testes locais.

---

## 20. Autorização

Revisar a matriz de permissões
implementada no RF016.

Perfis:

    admin
    operator
    viewer

Verificar todas as rotas
com cada perfil.

Garantir:

- Negação por padrão.
- Autorização centralizada.
- Validação no backend.
- Revalidação após mudanças de perfil.
- Ausência de privilégios herdados
  indevidamente.

Não considerar a ocultação de botões
uma proteção suficiente.

Verificar também endpoints auxiliares,
rotas de confirmação e downloads.

---

## 21. Broken Access Control

Testar acessos indevidos
através de requisições diretas.

Considerar:

- Operador acessando gerenciamento de usuários.
- Consulta tentando realizar check-in.
- Consulta tentando cancelar reservas.
- Consulta tentando criar bloqueios.
- Operador tentando redefinir senhas.
- Operador tentando alterar o próprio perfil.
- Usuário inativo reutilizando sessões.
- Usuário em troca obrigatória de senha
  tentando acessar o Dashboard.
- Usuário não autenticado tentando exportar Excel.

Verificar os códigos HTTP retornados.

Garantir que nenhuma operação indevida
produza alterações no banco.

Garantir que nenhuma auditoria de sucesso
seja criada para operações rejeitadas.

---

## 22. IDOR e BOLA

Avaliar referências diretas
a objetos internos.

Especialmente:

    /admin/bookings/:id

    /admin/users/:id

    /admin/audit_events/:id

    /admin/bookings/:id/receipt

Verificar:

- Manipulação de identificadores.
- Acesso a eventos restritos.
- Acesso a contas de terceiros.
- Acesso público a comprovantes.
- Acesso a recursos inexistentes.

Considerar as permissões operacionais
homologadas.

Usuários autorizados a consultar todos
os agendamentos poderão continuar
consultando essas reservas.

Não introduzir restrições por proprietário
que contrariem a matriz de permissões.

Impedir acesso a objetos fora do
escopo autorizado de cada perfil.

---

## 23. Proteção do último administrador

Revisar a garantia implementada
no RF015.

Garantir que o último administrador ativo
não possa ser:

- Desativado.
- Rebaixado para Operador.
- Rebaixado para Consulta.

Testar solicitações concorrentes.

Utilizar conexões independentes
ao PostgreSQL.

Verificar:

- Ordem das travas.
- Rollback.
- Proteção transacional.
- Optimistic locking.
- Auditoria.

Não depender exclusivamente
de uma contagem realizada antes
da transação.

---

## 24. Bootstrap e credenciais iniciais

Revisar o mecanismo de criação
do primeiro administrador.

Garantir:

- Ausência de senha padrão.
- Entrada segura de senha.
- Ausência de senha em argumentos.
- Ausência de senha nos logs.
- Ausência de sobrescrita de contas.
- Proteção contra execução concorrente.
- Auditoria apropriada.

Não manter rotas HTTP para bootstrap
publicamente acessíveis.

Não criar mecanismos ocultos
de acesso administrativo.

Não implementar contas de emergência
com credenciais fixas.

---

## 25. Segurança do Dashboard

Revisar a implementação do RF009.

Verificar:

- Autenticação do polling.
- Autorização em cada atualização.
- Ausência de renovação automática
  da inatividade.
- Controle de temporizadores.
- Cancelamento de requisições antigas.
- Tratamento de HTTP 401.
- Tratamento de HTTP 403.
- Tratamento de falhas de rede.
- Ausência de informações antigas
  apresentadas como atuais.

Garantir que a expiração ou revogação
da sessão interrompa a atualização.

Não restaurar conteúdo administrativo
indevidamente através do cache do Turbo.

Avaliar consumo de recursos provocado
por múltiplos Dashboards abertos.

Preservar a atualização operacional
implementada anteriormente.

---

## 26. Segurança do comprovante e QR Code

Revisar o RF010.

Garantir que:

- O protocolo não funcione como credencial.
- O QR Code não funcione como autenticação.
- O QR Code não contenha dados pessoais.
- O QR Code não contenha tokens.
- O QR Code não contenha IDs internos.
- Comprovantes não sejam enumeráveis publicamente.
- O acesso público esteja restrito
  ao contexto legítimo da confirmação.

Verificar a estratégia de geração
de SVG ou PNG.

Garantir ausência de:

- Scripts.
- Handlers de eventos.
- Referências externas inseguras.
- Conteúdo arbitrário incorporado.

Não permitir que um comprovante antigo
autorize automaticamente uma operação.

O PostgreSQL deverá continuar sendo
a fonte de verdade do estado atual.

---

## 27. Concorrência nas reservas

Revisar os RF003 e RF006.

Garantir que duas requisições simultâneas
não consigam reservar a mesma posição.

Revisar:

- Índices únicos parciais.
- Transações.
- Advisory locks.
- Optimistic locking.
- Tratamento de conflitos.
- Idempotência.

Testar:

- Duas reservas simultâneas.
- Reserva concorrente com reagendamento.
- Reserva concorrente com bloqueio.
- Alterações concorrentes.
- Reenvio da mesma solicitação.
- Reutilização de request_id
  com conteúdo diferente.

Garantir que a idempotência continue
funcionando após alterações administrativas.

Não permitir duplicação de reservas.

Não permitir duplicação indevida
de eventos de auditoria.

---

## 28. Concorrência na operação física

Revisar os RF005, RF006, RF007 e RF008.

Garantir que uma mesma doca
não possua simultaneamente
dois veículos em operação.

Considerar:

- Reservas de datas diferentes.
- Operações após meia-noite.
- Check-ins simultâneos.
- Check-in concorrente com cancelamento.
- Check-in concorrente com reagendamento.
- Check-in concorrente com no-show.
- Liberação concorrente.
- Alterações simultâneas.
- Bloqueios em lote.

Verificar a proteção no PostgreSQL
e nos services.

Não depender exclusivamente
de validações no model.

Preservar todas as regras operacionais.

---

## 29. Segurança das regras de negócio

Avaliar possíveis formas de contornar:

- Horizonte de agendamento.
- Horários permitidos.
- Disponibilidade das posições.
- Limite de check-in.
- Ocupação física das docas.
- Estados permitidos.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- Desbloqueios.

Preservar:

    8 docas físicas.

    10 janelas de horários.

    Horário operacional:
        08:00 até 17:48.

    Check-in:
        antes de 17:30.

Preservar o fuso:

    America/Sao_Paulo

Não alterar regras homologadas.

Corrigir somente possibilidades
de contorno ou inconsistências.

---

## 30. Segurança do processamento automático

Revisar o mecanismo de no-show
implementado no RF008.

Garantir:

- Execução independente do navegador.
- Execução independente da autenticação.
- Revalidação das condições.
- Proteção contra duplicidade.
- Idempotência.
- Tratamento de falhas.
- Recuperação após reinicialização.
- Auditoria transacional.

Verificar que jobs automáticos
não herdem o contexto de um usuário
autenticado de outra requisição.

Não atribuir operações automáticas
a operadores fictícios.

Avaliar a exposição de interfaces
de gerenciamento de jobs.

Não disponibilizar consoles ou painéis
de filas sem autorização apropriada.

---

## 31. Integridade da auditoria

Revisar os RF011, RF015 e RF016.

Garantir:

- Eventos append-only.
- Preservação dos registros anteriores.
- Identificação correta dos operadores.
- Nome histórico do operador.
- Perfil histórico.
- Origem.
- Valores anteriores.
- Valores posteriores.
- Motivos.

Verificar se a proteção contra
UPDATE e DELETE está efetiva.

Avaliar também:

- TRUNCATE.
- Alterações por SQL direto.
- Privilégios do usuário da aplicação.
- Capacidade de desativar triggers.

Não afirmar imutabilidade absoluta
quando o administrador do banco
possuir privilégios superiores.

Garantir proteção adequada
para o usuário operacional normal.

Não modificar auditorias antigas.

---

## 32. Segurança dos dados de auditoria

Verificar que não sejam armazenados:

- Senhas.
- Password digests.
- Cookies.
- Tokens.
- Credenciais.
- Chaves privadas.
- Informações de sessão.
- Segredos de infraestrutura.

Revisar a serialização
dos models utilizados.

Não registrar automaticamente
todos os atributos de um objeto.

Garantir listas explícitas
de atributos auditáveis.

Verificar a restrição de consulta:

    Administrador:
        auditoria operacional e administrativa.

    Operador:
        auditoria operacional autorizada.

    Consulta:
        auditoria operacional autorizada.

Impedir exposição de eventos restritos
através de filtros, detalhes,
contagens ou paginação.

---

## 33. Segurança da exportação Excel

Revisar o RF012.

Verificar:

- Autenticação.
- Autorização.
- Filtros.
- Limite de registros.
- Consumo de memória.
- Consumo de CPU.
- Dados exportados.
- Arquivos temporários.
- Cabeçalhos HTTP.
- Auditoria da geração.

Revisar a proteção contra Formula Injection.

Garantir que entradas textuais
não sejam interpretadas como fórmulas.

Considerar caracteres iniciais:

    =
    +
    -
    @

Considerar também espaços,
tabulações e quebras de linha.

Inspecionar a estrutura interna
dos arquivos XLSX de teste.

Garantir ausência de:

- Fórmulas originadas de entradas não confiáveis.
- Hyperlinks maliciosos gerados automaticamente.
- Referências externas não autorizadas.
- Credenciais.
- Tokens.
- Identificadores técnicos desnecessários.

Preservar as 26 colunas do RF012.

---

## 34. Segurança do PostgreSQL

Revisar a configuração do banco.

Verificar:

- Usuário utilizado pela aplicação.
- Usuário utilizado pelo worker.
- Permissões.
- Autenticação.
- Exposição de portas.
- Constraints.
- Foreign keys.
- Índices.
- Transações.
- Configuração de conexão.
- Limites de conexões.

Garantir que o usuário operacional
da aplicação não seja superuser.

Avaliar a separação entre:

    Usuário de migrations.

    Usuário operacional da aplicação.

Aplicar privilégios mínimos necessários,
considerando a arquitetura existente.

O usuário operacional deverá possuir
somente as permissões exigidas
pelas funcionalidades da aplicação.

Não conceder privilégios administrativos
desnecessários.

Não enfraquecer a auditoria append-only.

Documentar as permissões finais.

---

## 35. Exposição do PostgreSQL

Verificar o Docker Compose.

Garantir que o PostgreSQL
não seja publicado diretamente
para a internet.

A comunicação deverá ocorrer
através da rede interna do Docker.

Não adicionar:

    0.0.0.0:5432

como publicação de porta do banco.

Não introduzir portas externas
desnecessárias.

Caso seja indispensável um acesso local
para desenvolvimento, restringir
explicitamente ao contexto apropriado.

Não disponibilizar interfaces públicas
de gerenciamento do banco.

---

## 36. Segurança do Dockerfile

Revisar integralmente o Dockerfile.

Verificar:

- Imagem base.
- Versão da imagem.
- Suporte de segurança.
- Dependências do sistema operacional.
- Usuário de execução.
- Permissões.
- Processo de inicialização.
- Arquivos copiados.
- Build context.
- Segredos.
- Camadas da imagem.

Garantir que a aplicação
execute como usuário não root.

Avaliar builds multi-stage,
quando já utilizados ou necessários.

Não incluir ferramentas de desenvolvimento
desnecessárias na imagem de produção.

Não incluir credenciais
em argumentos ou camadas de build.

Não utilizar imagens desconhecidas
sem justificativa.

---

## 37. Segurança do Docker Compose

Revisar:

- Serviço web.
- Serviço PostgreSQL.
- Worker.
- Redes.
- Volumes.
- Portas.
- Healthchecks.
- Variáveis de ambiente.
- Política de reinicialização.
- Privilégios.

Garantir que não sejam utilizados
desnecessariamente:

    privileged: true

    network_mode: host

    pid: host

    cap_add com privilégios amplos

    montagem do Docker socket

    montagem indiscriminada do host

Avaliar:

    security_opt:
        no-new-privileges:true

    cap_drop

    limites de recursos

Aplicar somente configurações
compatíveis com os serviços.

Não quebrar o funcionamento
do PostgreSQL ou do worker.

Não utilizar chmod 777
como solução de permissões.

---

## 38. Exposição do Rails e Puma

Preservar a arquitetura aprovada.

Dentro do container:

    Puma escuta em 0.0.0.0.

No host de produção:

    Porta publicada apenas em 127.0.0.1.

Referência:

    127.0.0.1:3000:3000

O Nginx executará diretamente
no sistema operacional da VPS.

Não instalar Nginx dentro do Docker.

Não publicar o Puma diretamente
para a internet em produção.

Não alterar a arquitetura
para microsserviços.

Documentar as configurações necessárias
para o RF018.

---

## 39. Gestão de segredos

Revisar todo o repositório
quanto à presença de segredos.

Pesquisar:

- Senhas.
- Tokens.
- Chaves de API.
- Chaves privadas.
- Credenciais de banco.
- SECRET_KEY_BASE.
- Rails master key.
- URLs contendo credenciais.
- Credenciais em scripts.
- Credenciais em documentação.

Verificar especialmente:

    .env

    .env.production

    config/master.key

    config/credentials/

    Dockerfile

    compose.yaml

    README.md

    scripts/

    db/seeds.rb

Não imprimir valores sensíveis
encontrados durante a revisão.

Apresentar somente:

- Tipo de segredo.
- Arquivo.
- Linha.
- Identificação redigida.
- Risco.
- Correção recomendada.

Caso um segredo real tenha sido
versionado, recomendar sua rotação.

Excluir o segredo de um arquivo
não é suficiente para invalidar
uma credencial anteriormente exposta.

---

## 40. Revisão do histórico Git

Verificar se segredos foram
adicionados em commits anteriores.

Avaliar a utilização de:

    Gitleaks

Ou ferramenta equivalente confiável.

Verificar:

- Arquivos rastreados.
- Arquivos ignorados.
- Histórico disponível.
- Configurações.
- Arquivos removidos em commits posteriores.

Não transmitir o repositório
para serviços externos.

Não reescrever o histórico Git.

Não executar force push.

Não remover commits automaticamente.

Caso sejam encontrados segredos:

- Informar a localização sem expor o valor.
- Recomendar revogação ou rotação.
- Corrigir a configuração atual.
- Documentar a necessidade de tratamento
  do histórico, quando aplicável.

---

## 41. Revisão do .gitignore

Verificar a proteção dos arquivos locais.

Considerar:

    .env
    .env.*
    config/master.key
    arquivos temporários
    logs
    dumps de banco
    arquivos de backup
    dados de teste sensíveis

Preservar os arquivos de exemplo:

    .env.example

    .env.production.example

Não incluir valores reais
nos arquivos de exemplo.

Verificar se arquivos anteriormente
rastreados continuam versionados
apesar do .gitignore.

Não assumir que adicionar um arquivo
ao .gitignore remove seu conteúdo
do histórico do Git.

---

## 42. Revisão do .dockerignore

Verificar se informações desnecessárias
estão sendo enviadas ao build context.

Excluir quando apropriado:

- .git.
- Arquivos .env reais.
- Chaves privadas.
- Logs.
- Dumps.
- Backups.
- Arquivos temporários.
- Dados locais desnecessários.

Não excluir arquivos necessários
para o funcionamento do build.

Garantir que segredos não sejam
incorporados à imagem Docker.

---

## 43. Dependências Ruby

Executar análise das dependências.

Utilizar:

    Bundler Audit

Atualizar a base de avisos
de segurança quando possível.

Executar o equivalente a:

    bundle exec bundler-audit check --update

Adaptar o comando ao ambiente existente.

Analisar:

- Gemfile.
- Gemfile.lock.
- Dependências diretas.
- Dependências transitivas.
- Vulnerabilidades conhecidas.
- Bibliotecas sem manutenção.

Corrigir dependências vulneráveis
com atualizações compatíveis.

Priorizar a menor alteração necessária.

Não atualizar indiscriminadamente
todas as gems.

Não ignorar uma vulnerabilidade
sem justificativa documentada.

Caso uma atualização exija mudanças
incompatíveis, apresentar a limitação.

---

## 44. Dependências JavaScript

Identificar como os assets JavaScript
são gerenciados.

Considerar:

- Importmap.
- Gems com assets.
- Arquivos vendorizados.
- Gerenciadores de pacotes,
  caso existam.

Verificar versões e origem.

Avaliar vulnerabilidades conhecidas.

Caso exista importmap-rails,
utilizar os mecanismos de auditoria
compatíveis com a versão instalada.

Não introduzir Node.js ou npm
somente para auditar um projeto
que não utiliza essas ferramentas.

Não adicionar dependências externas
desnecessárias.

---

## 45. Brakeman

Executar análise estática
utilizando Brakeman.

Comando de referência:

    bundle exec brakeman

Gerar relatório estruturado.

Exemplo:

    bundle exec brakeman \
        -f json \
        -o tmp/brakeman-report.json

Adaptar ao ambiente Docker existente.

Analisar individualmente os resultados.

Para cada ocorrência:

- Verificar se é reproduzível.
- Identificar o código relacionado.
- Avaliar o impacto.
- Classificar a severidade.
- Corrigir quando aplicável.
- Criar teste de regressão.

Não adicionar ocorrências ao arquivo
de exclusões somente para eliminar alertas.

Falsos positivos deverão possuir
justificativa técnica verificável.

Não apresentar a ausência de alertas
como garantia de ausência de vulnerabilidades.

---

## 46. Análise das imagens Docker

Avaliar a utilização de uma ferramenta
de análise de vulnerabilidades de imagens.

Sugestão:

    Trivy

Ou ferramenta equivalente.

Inspecionar as imagens utilizadas por:

- Aplicação Rails.
- Worker.
- PostgreSQL.

Avaliar:

- Vulnerabilidades de pacotes do sistema.
- Vulnerabilidades das imagens base.
- Dependências incorporadas.
- Configurações inseguras.
- Segredos incorporados.

Não instalar ferramentas desconhecidas
ou executar scripts remotos
sem verificar sua procedência.

Caso a ferramenta não esteja disponível,
documentar a limitação.

Não declarar que a imagem foi auditada
se a análise não foi executada.

---

## 47. Análise dinâmica de segurança

Avaliar a utilização do OWASP ZAP
em ambiente local e isolado.

Priorizar inicialmente:

- Análise passiva.
- Baseline scan.
- Inspeção de cabeçalhos.
- Inspeção de cookies.
- Identificação de recursos expostos.

Caso seja realizada análise ativa,
utilizar exclusivamente:

- Aplicação local autorizada.
- Banco de teste descartável.
- Dados fictícios.
- Limites controlados de requisições.

Não executar scanners contra:

- VPS de produção.
- Domínios corporativos.
- Serviços de terceiros.
- Sistemas não autorizados.

Analisar os resultados individualmente.

Não classificar automaticamente
todo alerta como vulnerabilidade confirmada.

Não declarar análise dinâmica concluída
sem efetivamente executá-la.

---

## 48. Cabeçalhos HTTP

Verificar os cabeçalhos efetivamente
retornados pela aplicação.

Avaliar:

    Content-Security-Policy

    X-Content-Type-Options

    Referrer-Policy

    X-Frame-Options

    Permissions-Policy

    Cache-Control

    Strict-Transport-Security

Aplicar somente configurações adequadas
ao contexto de cada resposta.

Priorizar:

    X-Content-Type-Options: nosniff

Avaliar proteção contra clickjacking.

Utilizar frame-ancestors na CSP.

Manter cabeçalhos compatíveis
com os navegadores suportados.

Não habilitar HSTS indiscriminadamente
em desenvolvimento HTTP.

A configuração definitiva de HSTS
dependerá da publicação HTTPS
no RF018.

---

## 49. Segurança de cache

Revisar o cache das respostas.

Considerar especialmente:

- Login.
- Meu perfil.
- Gerenciamento de usuários.
- Dashboard.
- Agendamentos.
- Histórico.
- Comprovantes.
- Exportação Excel.
- Alteração de senha.

Garantir tratamento apropriado:

    Cache-Control: no-store

quando existirem dados sensíveis.

Avaliar o cache do Turbo.

Avaliar restauração de páginas
pelo navegador após logout.

Garantir que requisições autenticadas
não sejam armazenadas em caches públicos.

Documentar as futuras restrições
de cache do Cloudflare e Nginx.

---

## 50. CORS

Revisar a configuração de CORS,
caso exista.

A aplicação utiliza uma arquitetura
monolítica Rails com frontend integrado.

Não existe necessidade geral
de liberar acessos cross-origin.

Não permitir indiscriminadamente:

    Access-Control-Allow-Origin: *

em endpoints administrativos.

Não combinar origens arbitrárias
com credenciais.

Remover configurações de CORS
desnecessárias, preservando
integrações legítimas existentes.

Não criar APIs públicas adicionais.

---

## 51. Redirecionamentos e Host Authorization

Verificar:

- Redirecionamento após login.
- Redirecionamento após logout.
- Redirecionamento após confirmação.
- Parâmetros return_to.
- Parâmetros redirect.
- URLs de comprovantes.

Impedir Open Redirect.

Revisar a autorização de hosts
do Rails em produção.

Não aceitar hosts arbitrários
sem necessidade.

Preparar a configuração futura
do domínio oficial através de
variáveis de ambiente.

Considerar a proteção contra
Host Header Injection.

Não gerar URLs sensíveis
a partir de hosts não validados.

---

## 52. IPs e proxies confiáveis

Revisar a utilização de:

    request.remote_ip

E cabeçalhos:

    X-Forwarded-For

    X-Real-IP

    X-Forwarded-Proto

Considerar a futura arquitetura:

    Internet

        |

    Cloudflare, se aprovado

        |

    Nginx no host

        |

    Puma no Docker

Não confiar em cabeçalhos de proxy
enviados diretamente pelo cliente.

Documentar os proxies confiáveis.

Garantir que a configuração futura
não permita contornar rate limiting
ou proteções HTTPS.

Não confiar indiscriminadamente
em todas as redes privadas.

A configuração definitiva deverá
ser validada no RF018.

---

## 53. Proteção contra exposição de informações

Revisar as respostas de erro.

Considerar:

- HTTP 400.
- HTTP 401.
- HTTP 403.
- HTTP 404.
- HTTP 422.
- HTTP 429.
- HTTP 500.
- HTTP 503.

Não apresentar publicamente:

- Stack traces.
- Consultas SQL.
- Caminhos físicos.
- Variáveis de ambiente.
- Credenciais.
- Informações detalhadas de dependências.
- Configuração de banco.
- Informações internas da infraestrutura.

Verificar a configuração Rails
de produção.

Garantir que páginas detalhadas
de desenvolvimento não sejam
habilitadas em produção.

Preservar mensagens úteis
para o participante e operador.

---

## 54. Segurança dos endpoints de healthcheck

Revisar as rotas existentes.

Exemplos:

    /up

    /ready

Preservar a finalidade:

    Liveness.

    Readiness.

Não expor publicamente:

- Credenciais.
- Endereço interno do PostgreSQL.
- Nomes de usuários do banco.
- Consultas SQL.
- Versões detalhadas.
- Variáveis de ambiente.
- Configurações de infraestrutura.

Avaliar quais endpoints precisam
estar disponíveis externamente.

Restringir os endpoints de diagnóstico
interno quando necessário.

Não comprometer os healthchecks
do Docker.

---

## 55. Serialização e manipulação de tipos

Pesquisar utilizações de:

    Marshal.load

    YAML.load

    constantize

    safe_constantize

    send

    public_send

    métodos dinâmicos

Verificar se entradas externas
controlam classes ou métodos
executados pelo backend.

Não desserializar objetos
não confiáveis.

Utilizar formatos e parsers seguros.

Utilizar listas explícitas
de valores permitidos.

Verificar também parâmetros
com tipos inesperados:

- Arrays.
- Hashes.
- Strings.
- Valores nulos.
- Estruturas aninhadas.

Garantir tratamento adequado
sem erros internos desnecessários.

---

## 56. Execução de comandos e acesso a arquivos

Pesquisar:

    system

    exec

    spawn

    Open3

    comandos executados através de backticks

    File.open

    File.read

    File.write

    send_file

Verificar se dados externos
influenciam comandos ou caminhos.

Impedir:

- Command Injection.
- Path Traversal.
- Leitura arbitrária de arquivos.
- Escrita arbitrária de arquivos.
- Acesso indevido a credenciais.

Utilizar mecanismos seguros
e caminhos controlados.

O RF013 permanece suspenso.

Não criar funcionalidades
de upload neste requisito.

---

## 57. SSRF e requisições externas

Identificar chamadas HTTP externas
existentes no backend.

Verificar se entradas do participante
podem determinar:

- URL.
- Host.
- Porta.
- Protocolo.
- Redirecionamento.

Impedir acessos arbitrários
a serviços internos.

Não adicionar integrações externas
sem necessidade.

O RF014 permanece suspenso.

Não implementar comunicação
com Power Automate.

Não criar webhooks para este requisito.

---

## 58. Logs da aplicação

Revisar:

    config.filter_parameters

Verificar filtros relacionados a:

- password.
- password_confirmation.
- current_password.
- password_digest.
- token.
- token_digest.
- session_token.
- authorization.
- cookies.
- secret.
- credenciais.

Verificar parâmetros aninhados.

Avaliar a exposição de:

- Nomes.
- E-mails.
- Notas fiscais.
- Placas.
- Empresas.
- Motivos e observações.

Minimizar dados pessoais nos logs.

Não prejudicar a capacidade
de diagnosticar falhas operacionais.

Garantir proteção contra Log Injection.

Não registrar conteúdo não confiável
de maneira que permita falsificar
estruturas de logs.

---

## 59. Retenção e privacidade

Identificar os dados pessoais
armazenados pela aplicação.

Considerar:

- Nome do responsável.
- Nome de usuários.
- E-mail.
- Placa.
- Informações operacionais.
- Eventos de auditoria.
- Endereços IP, quando armazenados.

Avaliar a necessidade
de cada informação coletada.

Não adicionar novos dados pessoais
sem necessidade.

Não excluir dados operacionais
automaticamente neste requisito.

Preservar a auditoria.

Documentar:

- Finalidade dos dados.
- Locais de armazenamento.
- Perfis com acesso.
- Locais de exportação.
- Necessidades futuras de retenção.
- Necessidades futuras de anonimização.

Não declarar conformidade integral
com a LGPD somente a partir
desta revisão técnica.

---

## 60. Limites de requisições

Avaliar os limites aplicáveis a:

- Tamanho dos parâmetros.
- Quantidade de parâmetros.
- Profundidade de estruturas aninhadas.
- Tamanho do corpo HTTP.
- Tempo de processamento.
- Tempo de conexão.
- Quantidade de requisições.

Considerar que o RF013
não está implementado.

Não permitir requisições públicas
com dezenas de megabytes
sem necessidade operacional.

Avaliar limites adequados
nas camadas existentes.

Documentar os limites adicionais
necessários no Nginx durante RF018.

Evitar consumo excessivo
de recursos antes da validação
dos campos do formulário.

---

## 61. Disponibilidade e consumo de recursos

Avaliar possíveis gargalos em:

- Consultas de disponibilidade.
- Dashboard.
- Polling.
- Histórico.
- Exportação Excel.
- Autenticação.
- Hashing de senhas.
- Rate limiting.
- Processamento de no-show.

Verificar:

- Consultas N+1.
- Consultas sem limite.
- Paginação.
- Índices.
- Timeouts.
- Pool de conexões.
- Memória.
- CPU.
- Crescimento do banco.

Não transformar a revisão
em uma reescrita completa
da aplicação.

Corrigir problemas comprovados.

Realizar testes de carga controlados
em ambiente isolado.

Não realizar ataques de negação
de serviço contra infraestrutura externa.

---

## 62. Configuração de produção do Rails

Revisar:

    config/environments/production.rb

Verificar:

- Tratamento de exceções.
- Configuração de logs.
- HTTPS.
- Cookies.
- Hosts autorizados.
- Cache.
- Assets.
- Secret key base.
- Configuração de banco.
- Active Job.
- Configuração de sessão.

Garantir que configurações inseguras
de desenvolvimento não sejam
herdadas em produção.

Não utilizar credenciais padrão.

Não configurar autenticação
em modo opcional.

Não permitir bypass administrativo
por variável de ambiente.

A variável de habilitação administrativa,
caso existente, deverá somente
controlar a publicação.

Nunca deverá desativar
a autenticação ou autorização.

---

## 63. Configuração de variáveis de ambiente

Revisar:

    .env.example

    .env.production.example

Identificar configurações obrigatórias.

Exemplos conceituais:

    RAILS_ENV

    DATABASE_URL

    SECRET_KEY_BASE

    APP_HOST

    ADMIN_ACCESS_ENABLED

Adaptar às variáveis realmente utilizadas.

Não criar configurações duplicadas
com responsabilidades equivalentes.

Validar variáveis obrigatórias
na inicialização de produção.

Caso uma configuração crítica
esteja ausente ou inválida,
falhar de maneira segura.

Não utilizar fallback inseguro.

Não incluir valores reais
na documentação.

---

## 64. Preparação do Nginx

Não instalar nem configurar
o Nginx na VPS neste requisito.

Elaborar as recomendações necessárias
para o RF018.

Considerar:

- Proxy reverso.
- HTTPS.
- Certificados TLS.
- Redirecionamento HTTP para HTTPS.
- Limites de tamanho de requisição.
- Rate limiting complementar.
- Timeouts.
- Cabeçalhos de proxy.
- Hosts permitidos.
- Proteção de endpoints internos.
- Cache.
- Logs.
- Proteção contra acesso direto ao Puma.

Preservar:

    Nginx executado no host.

    Puma acessível por loopback.

    PostgreSQL em rede privada.

Não duplicar cabeçalhos de segurança
de maneira contraditória entre
Rails e Nginx.

---

## 65. Preparação do firewall

Documentar a política de rede
necessária para o RF018.

Considerar exposição pública
somente dos serviços necessários.

Referência:

    80/TCP:
        HTTP, quando necessário.

    443/TCP:
        HTTPS.

    SSH:
        acesso administrativo restrito.

    3000/TCP:
        não expor publicamente.

    5432/TCP:
        não expor publicamente.

Avaliar as interações entre
firewall do host e publicação
de portas do Docker.

Não assumir que uma regra UFW
protege automaticamente todas
as portas publicadas pelo Docker.

Não realizar mudanças reais
de firewall neste requisito.

---

## 66. Preparação do Cloudflare

Caso Cloudflare seja utilizado
na implantação futura, documentar:

- Configuração DNS.
- Proxy reverso.
- TLS entre cliente e Cloudflare.
- TLS entre Cloudflare e servidor.
- Modo Full (strict).
- Proteções contra bots.
- WAF.
- Rate limiting.
- Restrições de cache.
- Proteção da origem.
- IPs confiáveis.

Não depender exclusivamente
do Cloudflare para segurança.

Não desabilitar proteções
da aplicação porque existe WAF.

Avaliar possíveis falsos positivos
contra o formulário público.

Não criar regras reais no Cloudflare
neste requisito.

Não acessar a conta Cloudflare.

A implementação da infraestrutura
será realizada no RF018.

---

## 67. Backup e recuperação

Documentar uma estratégia de backup
para a futura implantação.

Considerar:

- PostgreSQL.
- Configurações necessárias.
- Segredos gerenciados separadamente.
- Migrations.
- Dados persistentes.

Documentar:

- Frequência sugerida.
- Retenção.
- Criptografia.
- Armazenamento protegido.
- Cópia externa.
- Procedimento de restauração.
- Testes periódicos de recuperação.

O RF013 permanece suspenso.

Não implementar volumes adicionais
de documentos neste requisito.

Quando RF013 for implementado,
a estratégia deverá incluir
o armazenamento dos anexos.

Não utilizar dados reais
em testes destrutivos.

Não enviar backups a serviços externos
sem aprovação.

---

## 68. Autenticação multifator

Avaliar a ausência de MFA
no sistema administrativo.

Considerar especialmente
o perfil Administrador.

Documentar:

- Riscos de comprometimento de senha.
- Benefícios da autenticação multifator.
- Alternativas compatíveis com Rails.
- Dependência de serviços externos.
- Possibilidade de proteção adicional
  através da infraestrutura.

Não implementar MFA automaticamente
neste requisito.

Não exigir integração corporativa
que não esteja disponível.

Classificar a ausência de MFA
como risco residual a ser homologado.

Caso seja considerado indispensável
para publicação segura,
registrar explicitamente como pendência.

---

## 69. Funcionalidades suspensas

Verificar que o RF013 e RF014
não tenham sido parcialmente expostos.

Garantir ausência de:

- Endpoints públicos de upload.
- Gerenciamento de documentos.
- Downloads de documentos privados.
- Webhooks de e-mail.
- Credenciais SMTP.
- Tokens do Power Automate.
- Integrações não autorizadas.

Caso existam estruturas técnicas
previamente instaladas pelo Rails,
avaliar sua exposição.

Não remover componentes necessários
à arquitetura sem justificativa.

Documentar que qualquer implementação
futura de RF013 ou RF014 exigirá
uma nova avaliação de segurança.

---

## 70. Classificação das vulnerabilidades

Classificar as ocorrências em:

    Crítica

    Alta

    Média

    Baixa

    Informativa

Considerar:

- Impacto.
- Probabilidade.
- Exposição à internet.
- Necessidade de autenticação.
- Privilégios necessários.
- Dados afetados.
- Facilidade de exploração.
- Impacto operacional.

Utilizar CWE e referência OWASP,
quando aplicáveis.

Utilizar CVSS quando houver
informações suficientes.

Não inventar pontuações de CVSS.

Distinguir:

- Vulnerabilidade confirmada.
- Configuração insegura.
- Risco potencial.
- Falso positivo.
- Recomendação de melhoria.
- Controle não avaliado.

---

## 71. Registro das vulnerabilidades

Criar uma identificação única
para cada ocorrência.

Exemplo:

    SEC-001

    SEC-002

    SEC-003

Registrar:

- Identificador.
- Título.
- Severidade.
- Categoria.
- Descrição.
- Arquivo.
- Linha.
- Funcionalidade afetada.
- Impacto.
- Evidência.
- Correção recomendada.
- Correção implementada.
- Teste de validação.
- Estado final.

Estados previstos:

    Identificada

    Confirmada

    Corrigida

    Mitigada

    Falso positivo

    Pendente

    Não avaliada

Não incluir credenciais
ou dados pessoais reais
nas evidências.

Não registrar vulnerabilidades
fictícias para preencher o relatório.

---

## 72. Estratégia de correção

Corrigir as vulnerabilidades
efetivamente identificadas.

Prioridade:

    1. Críticas.

    2. Altas.

    3. Médias.

    4. Baixas.

    5. Melhorias informativas.

Preservar a arquitetura
e as funcionalidades homologadas.

Para cada correção:

1. Identificar a causa.
2. Implementar a menor alteração segura.
3. Criar ou atualizar testes.
4. Executar testes relacionados.
5. Verificar regressões.
6. Registrar evidências.

Não corrigir somente
o sintoma visual.

Não ocultar mensagens de erro
como substituto da correção.

Não enfraquecer outros controles
para resolver uma vulnerabilidade.

Caso uma correção exija
mudança relevante de regra de negócio,
documentar a necessidade de homologação.

---

## 73. Testes de segurança

Criar ou complementar testes
automatizados de segurança.

Utilizar Minitest e PostgreSQL.

Organizar os testes conforme
as convenções do repositório.

Cobrir:

- SQL Injection.
- XSS.
- CSRF.
- Mass Assignment.
- Broken Access Control.
- IDOR.
- Elevação de privilégios.
- Session Fixation.
- Sessões revogadas.
- Expiração de sessão.
- Força bruta.
- Enumeração de contas.
- Open Redirect.
- Host Header Injection.
- Manipulação de parâmetros.
- Formula Injection.
- Exposição de dados.
- Concorrência.
- Idempotência.
- Integridade da auditoria.

Utilizar requisições reais
quando apropriado.

Não limitar os testes
a validações isoladas de models.

---

## 74. Testes da matriz de autorização

Criar uma cobertura sistemática
das rotas administrativas.

Para cada funcionalidade, verificar:

    Usuário não autenticado.

    Administrador.

    Operador.

    Consulta.

    Usuário inativo.

    Usuário com sessão revogada.

    Usuário com sessão expirada.

    Usuário com troca obrigatória de senha.

Verificar:

- Código HTTP.
- Conteúdo retornado.
- Alterações no banco.
- Eventos de auditoria.
- Redirecionamentos.
- Ausência de informações restritas.

Garantir que novas rotas
não fiquem desprotegidas.

---

## 75. Testes de concorrência

Executar testes reais utilizando
conexões independentes ao PostgreSQL.

Cobrir:

- Reserva simultânea.
- Reserva e bloqueio.
- Alteração simultânea.
- Check-in simultâneo.
- Check-in e no-show.
- Check-in e cancelamento.
- Liberação simultânea.
- Desativação de administradores.
- Alteração simultânea de perfis.
- Revogação de sessão.
- Login concorrente com redefinição de senha.

Não representar concorrência
somente através de operações sequenciais.

Documentar os resultados observados.

---

## 76. Testes em configuração de produção

Preparar um ambiente local isolado
utilizando configurações representativas
de produção.

Não utilizar a VPS real.

Verificar:

- RAILS_ENV=production.
- Assets compilados.
- Páginas de erro.
- Content Security Policy.
- Cookies.
- Hosts autorizados.
- Configurações de sessão.
- Filtragem de logs.
- Healthchecks.
- Proteção das rotas.
- Restrição administrativa de publicação.

Quando necessário, utilizar HTTPS
em ambiente local de teste.

Não declarar cookies Secure
validados em HTTPS apenas porque
o atributo está configurado no código.

Documentar o que foi efetivamente
testado em execução.

Não liberar o painel real
para acesso público.

---

## 77. Testes de regressão

Executar integralmente
os testes existentes dos requisitos:

    RF001
    RF002
    RF003
    RF004
    RF005
    RF006
    RF007
    RF008
    RF009
    RF010
    RF011
    RF012
    RF015
    RF016

Preservar todas as regras de negócio.

Preservar:

- Formulário público.
- Layout público.
- Painel administrativo.
- Dashboard.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- No-show.
- Atualização automática.
- Comprovante.
- QR Code.
- Histórico.
- Exportação Excel.
- Usuários.
- Autenticação.
- Autorização.

Não remover testes anteriores.

Não enfraquecer assertions.

Não ignorar testes de segurança
para obter aprovação da suíte.

---

## 78. Ferramentas de qualidade

Executar:

    Minitest

    RuboCop

    Brakeman

    Bundler Audit

Avaliar também a execução de:

    Gitleaks

    Trivy

    OWASP ZAP

Quando compatíveis com o ambiente.

Registrar para cada ferramenta:

- Nome.
- Versão.
- Comando executado.
- Data da execução.
- Escopo analisado.
- Resultado.
- Alertas.
- Vulnerabilidades confirmadas.
- Limitações.

Não declarar execução
de ferramentas indisponíveis.

Caso não exista acesso à internet
para atualizar bases de vulnerabilidades,
informar a data da base disponível.

---

## 79. Documentação de segurança

Criar ou atualizar:

    docs/security/

Organização sugerida:

    docs/security/
        threat-model.md
        endpoint-inventory.md
        security-review.md
        vulnerabilities.md
        production-checklist.md

Adaptar às convenções existentes.

Registrar também:

    docs/requisitos/RF017.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação operacional.
- Documentação de infraestrutura.
- ADRs, quando necessário.

Não incluir dados sensíveis
nos documentos versionados.

Não versionar relatórios brutos
que contenham segredos,
cookies ou dados pessoais.

Preservar somente evidências
sanitizadas.

---

## 80. Relatório executivo

Criar um resumo executivo
da revisão de segurança.

Apresentar:

- Escopo analisado.
- Funcionalidades analisadas.
- Ferramentas utilizadas.
- Quantidade de vulnerabilidades.
- Quantidade de correções.
- Riscos residuais.
- Limitações.
- Pendências de infraestrutura.

Apresentar uma tabela:

    Severidade | Identificadas | Corrigidas | Pendentes

    Crítica
    Alta
    Média
    Baixa
    Informativa

Não utilizar números fictícios.

Distinguir vulnerabilidades
confirmadas de alertas automatizados.

---

## 81. Critérios para aprovação

O RF017 somente poderá ser considerado
tecnicamente aprovado quando:

- Não existirem vulnerabilidades críticas
  confirmadas e pendentes.

- Não existirem vulnerabilidades altas
  confirmadas e pendentes.

- Vulnerabilidades médias tiverem sido
  corrigidas ou possuírem tratamento
  devidamente documentado para homologação.

- As rotas administrativas estiverem
  protegidas.

- A autenticação estiver funcional.

- A autorização estiver funcional.

- A integridade da auditoria estiver
  preservada.

- Os testes obrigatórios tiverem
  sido executados.

- As regressões estiverem controladas.

- Os riscos residuais estiverem
  explicitamente documentados.

A ausência de alertas automatizados
não garante segurança absoluta.

Não declarar o sistema invulnerável.

Não declarar prontidão definitiva
para produção sem a validação
da infraestrutura no RF018.

---

## 82. Checklist de segurança

### Código-fonte

- [ ] SQL Injection avaliado.
- [ ] XSS avaliado.
- [ ] JavaScript revisado.
- [ ] CSRF avaliado.
- [ ] Mass Assignment avaliado.
- [ ] Desserialização avaliada.
- [ ] Execução de comandos avaliada.
- [ ] Acesso a arquivos avaliado.
- [ ] SSRF avaliado.

### Autenticação

- [ ] Hashing de senhas revisado.
- [ ] Sessões revisadas.
- [ ] Cookies revisados.
- [ ] Expiração validada.
- [ ] Revogação validada.
- [ ] Rate limiting validado.
- [ ] Bootstrap revisado.
- [ ] Troca obrigatória validada.

### Autorização

- [ ] Todas as rotas inventariadas.
- [ ] Matriz de permissões testada.
- [ ] Acesso direto testado.
- [ ] Elevação de privilégios testada.
- [ ] IDOR avaliado.
- [ ] Auditoria restrita protegida.

### Formulário público

- [ ] Campos validados no backend.
- [ ] Manipulação de parâmetros testada.
- [ ] Abuso automatizado avaliado.
- [ ] Rate limiting avaliado.
- [ ] Disponibilidade protegida.
- [ ] Idempotência preservada.

### Banco de dados

- [ ] Constraints revisadas.
- [ ] Índices revisados.
- [ ] Concorrência validada.
- [ ] Privilégios revisados.
- [ ] Usuário operacional sem privilégios
      de superuser.
- [ ] Banco não exposto publicamente.
- [ ] Auditoria append-only preservada.

### Infraestrutura

- [ ] Dockerfile revisado.
- [ ] Docker Compose revisado.
- [ ] Execução sem root revisada.
- [ ] Portas revisadas.
- [ ] Redes revisadas.
- [ ] Segredos revisados.
- [ ] .gitignore revisado.
- [ ] .dockerignore revisado.
- [ ] Imagens Docker avaliadas.

### Dependências

- [ ] Gems auditadas.
- [ ] Dependências JavaScript avaliadas.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Alertas analisados.
- [ ] Limitações das ferramentas registradas.

### Produção

- [ ] Configuração Rails revisada.
- [ ] Requisitos HTTPS documentados.
- [ ] Requisitos Nginx documentados.
- [ ] Requisitos de firewall documentados.
- [ ] Configuração de proxies documentada.
- [ ] Backup e recuperação documentados.
- [ ] Riscos residuais documentados.

### Qualidade

- [ ] Testes de segurança executados.
- [ ] Testes de autorização executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de regressão executados.
- [ ] RuboCop executado.
- [ ] Vulnerabilidades críticas tratadas.
- [ ] Vulnerabilidades altas tratadas.
- [ ] Relatório final produzido.

---

## 83. Entrega final

Ao concluir o RF017, apresentar:

### 83.1 Resumo executivo

- Resultado geral da revisão.
- Escopo efetivamente analisado.
- Principais riscos encontrados.
- Principais correções realizadas.

### 83.2 Vulnerabilidades

Apresentar tabela com:

    ID
    Severidade
    Vulnerabilidade
    Arquivo
    Correção
    Evidência
    Estado

### 83.3 Comparação antes e depois

Apresentar:

- Alertas anteriores às correções.
- Alertas posteriores às correções.
- Vulnerabilidades resolvidas.
- Vulnerabilidades pendentes.

Utilizar resultados reais.

### 83.4 Alterações realizadas

Informar:

- Arquivos modificados.
- Controllers modificados.
- Models modificados.
- Services modificados.
- Configurações modificadas.
- Dependências atualizadas.
- Migrations adicionadas.
- Testes criados.

Justificar as alterações relevantes.

### 83.5 Testes

Apresentar:

- Comandos executados.
- Quantidade de testes.
- Quantidade de assertions.
- Falhas.
- Erros.
- Testes ignorados.
- Testes não executados.
- Motivos das limitações.

### 83.6 Ferramentas

Apresentar os resultados de:

- Brakeman.
- Bundler Audit.
- RuboCop.
- Minitest.
- Gitleaks, quando executado.
- Trivy, quando executado.
- OWASP ZAP, quando executado.

### 83.7 Riscos residuais

Informar:

- Riscos ainda existentes.
- Impacto.
- Justificativa.
- Controles compensatórios.
- Necessidade de homologação.

### 83.8 Preparação para RF018

Entregar um checklist de implantação contendo:

- Configuração do Rails.
- Configuração de segredos.
- PostgreSQL.
- Docker.
- Puma.
- Nginx.
- HTTPS.
- Firewall.
- Cloudflare, quando utilizado.
- Backup.
- Healthchecks.
- Validação pós-implantação.

### 83.9 Parecer de segurança

Utilizar uma das classificações:

    APROVADO PARA PREPARAÇÃO DA IMPLANTAÇÃO

    APROVADO COM RESSALVAS

    REPROVADO — CORREÇÕES OBRIGATÓRIAS

Informar a justificativa.

Não confundir aprovação da revisão local
com aprovação definitiva do ambiente
de produção.

### 83.10 Repositório

Apresentar:

    git status --short

Não incluir segredos.

---

## 84. Fora do escopo

Não implementar:

- RF013.
- Upload de documentos.
- RF014.
- Notificações por e-mail.
- Power Automate.
- Novas funcionalidades operacionais.
- Redesign do painel.
- React.
- Vue.
- Microsserviços.
- Redis.
- OAuth.
- SSO.
- MFA sem homologação.
- Serviços externos de identidade.
- Infraestrutura de monitoramento complexa.
- Implantação na VPS.
- Alterações reais no Cloudflare.
- Alterações reais no firewall.
- Configuração real do Nginx.
- Reescrita do histórico Git.

Implementar exclusivamente as correções
de segurança necessárias dentro
do escopo autorizado.

---

## 85. Regra de parada

Ao concluir o RF017, PARE.

Não implementar o RF018.

Não realizar deploy.

Não acessar a VPS.

Não publicar a aplicação.

Não habilitar automaticamente
o acesso administrativo em produção.

Não implementar RF013 ou RF014.

Entregar os relatórios,
as correções e as evidências.

Manter a aplicação funcional
no ambiente de desenvolvimento.

Aguardar homologação da revisão
de segurança e novas instruções.