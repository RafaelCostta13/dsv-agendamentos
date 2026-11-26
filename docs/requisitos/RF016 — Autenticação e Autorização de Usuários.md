# RF016 — Autenticação e Autorização de Usuários

## 1. Objetivo

Implementar a autenticação e a autorização definitivas
da aplicação DSV Doca Agenda.

Utilizar a estrutura de usuários implementada no RF015.

Implementar:

- Tela de login.
- Autenticação por e-mail e senha.
- Sessões autenticadas.
- Logout.
- Expiração de sessões.
- Controle de acesso por perfil.
- Proteção das rotas administrativas.
- Identificação do usuário autenticado.
- Alteração da própria senha.
- Troca obrigatória de senha no primeiro acesso.
- Troca obrigatória após redefinição administrativa.
- Invalidação de sessões.
- Proteção contra tentativas excessivas de login.
- Identificação dos operadores na auditoria.
- Registro de eventos de segurança.

Preservar todas as funcionalidades implementadas
nos RF001 até RF012 e RF015.

IMPORTANTE:

    RF013 permanece suspenso.

    RF014 permanece suspenso.

Não implementar upload de documentos.

Não implementar notificações por e-mail.

Não integrar Microsoft Power Automate.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/database/
- docs/requisitos/
- docs/referencias/

Consultar especialmente o RF015.

Analisar:

- Model User.
- Estrutura da tabela users.
- Implementação de has_secure_password.
- Configuração do bcrypt.
- Perfis de acesso.
- Mecanismo de bootstrap.
- Redefinição administrativa de senha.
- Proteção do último administrador.
- Auditoria.
- Rotas administrativas.
- Content Security Policy.
- Proteção CSRF.
- Configurações de cookies.
- Configurações de sessão.
- Docker Compose.
- Processamento em segundo plano do RF008.

Não assumir que todos os exemplos dos requisitos
correspondem exatamente ao código implementado.

Adaptar este requisito à estrutura existente.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Arquitetura

Preservar a arquitetura monolítica Ruby on Rails.

Utilizar:

- Ruby on Rails.
- Active Record.
- PostgreSQL.
- Controllers.
- Models.
- Services, quando necessários.
- Views ERB.
- Cookies seguros.
- Recursos nativos de autenticação do Rails.

Reutilizar o model User existente.

Não substituir a estrutura de usuários
implementada no RF015.

Priorizar os mecanismos nativos disponíveis
na versão instalada do Rails.

Caso exista um gerador nativo de autenticação,
avaliar sua implementação antes de utilizá-lo.

Não executar geradores que sobrescrevam
models, migrations, controllers ou configurações
existentes sem análise.

Não introduzir:

- React.
- Vue.
- SPA.
- Redis.
- JWT para sessões administrativas.
- Microsserviços.
- Servidores externos de identidade.
- OAuth.
- SSO.
- Active Directory.
- Microsoft Entra ID.
- Autenticação por serviços externos.

Não implementar algoritmos criptográficos próprios.

---

## 4. Separação entre área pública e administrativa

A aplicação possui dois contextos distintos.

### Área pública

    /agendar

Responsável pelo agendamento de coletas e entregas.

Deverá continuar acessível sem autenticação.

Os participantes não precisarão:

- Criar contas.
- Realizar login.
- Informar senhas.
- Possuir usuários cadastrados.

Preservar o formulário público e sua confirmação.

Preservar o comprovante e o QR Code do RF010.

### Área administrativa

    /admin

Deverá exigir autenticação válida.

Todas as funcionalidades administrativas
deverão respeitar as permissões do usuário.

Não proteger apenas a página inicial.

Proteger todas as rotas administrativas.

---

## 5. Estrutura de usuários

Reutilizar a tabela:

    users

Preservar os atributos implementados no RF015:

    id
    name
    email
    password_digest
    role
    active
    must_change_password
    password_changed_at
    deactivated_at
    lock_version
    created_at
    updated_at

Verificar a estrutura efetivamente existente.

Não criar uma segunda tabela de usuários.

Não duplicar credenciais.

Não alterar password_digest desnecessariamente.

Preservar os usuários existentes.

Preservar as senhas já cadastradas.

---

## 6. Estrutura de sessões

Implementar sessões persistidas no PostgreSQL.

Criar uma tabela:

    sessions

Estrutura conceitual:

    id
        bigint
        primary key

    user_id
        bigint
        not null
        foreign key

    token_digest
        string
        not null
        unique

    created_at
        timestamp
        not null

    last_seen_at
        timestamp
        not null

    expires_at
        timestamp
        not null

    revoked_at
        timestamp
        nullable

    user_agent
        string
        nullable

A estrutura poderá ser adaptada à abordagem
nativa de autenticação do Rails.

Garantir capacidade de:

- Identificar a sessão.
- Identificar o usuário.
- Verificar validade.
- Verificar expiração.
- Revogar sessões individualmente.
- Revogar todas as sessões de um usuário.

Não armazenar tokens de autenticação
em texto simples no PostgreSQL.

Não incluir senhas na tabela de sessões.

Não utilizar identificadores previsíveis
como credenciais de autenticação.

---

## 7. Índices e integridade

Criar os índices necessários para:

- Identificação da sessão.
- Consulta de sessões por usuário.
- Consulta de sessões expiradas.
- Consulta de sessões revogadas.

Criar foreign key entre:

    sessions.user_id

e:

    users.id

Preservar a integridade referencial.

Não excluir usuários automaticamente.

Não modificar migrations anteriormente aplicadas.

Criar novas migrations para as alterações necessárias.

---

## 8. Tela de login

Criar uma página de autenticação.

Título:

    Acesso administrativo

Apresentar:

- Logo oficial DSV.
- Identificação Doca Agenda.
- Campo de e-mail.
- Campo de senha.
- Botão Entrar no sistema.
- Opção de mostrar ou ocultar a senha.
- Mensagens de erro.
- Orientação de suporte.

Mensagem de suporte:

    Problemas de acesso?
    Entre em contato com o administrador do sistema.

Não criar links de recuperação de senha
por e-mail neste requisito.

Não criar opção de cadastro público.

Não apresentar informações operacionais
antes da autenticação.

---

## 9. Identidade visual do login

Utilizar a identidade visual existente.

Preservar:

- Azul institucional.
- Fundo branco ou cinza claro.
- Logo oficial.
- Tipografia existente.
- Bordas discretas.
- Espaçamento adequado.

Estrutura sugerida:

    +--------------------------------------+
    |                                      |
    |          DSV | Doca Agenda           |
    |                                      |
    |         Acesso administrativo        |
    |                                      |
    | E-mail                               |
    | [________________________________]   |
    |                                      |
    | Senha                                |
    | [____________________________] [O]  |
    |                                      |
    |      [ Entrar no sistema ]           |
    |                                      |
    | Problemas de acesso?                 |
    | Contate o administrador do sistema.  |
    |                                      |
    +--------------------------------------+

Centralizar o formulário.

Priorizar simplicidade.

Não utilizar imagens decorativas externas.

Não redesenhar o painel administrativo.

---

## 10. Rotas de autenticação

Estrutura sugerida:

    GET /login

    POST /login

    DELETE /logout

    GET /admin/profile

    GET /admin/password/edit

    PATCH /admin/password

Adaptar às convenções existentes.

Utilizar GET exclusivamente para consulta
e apresentação de formulários.

Utilizar POST para autenticação.

Utilizar DELETE ou POST protegido por CSRF
para logout.

Utilizar PATCH para alteração de senha.

Não permitir logout através de GET.

Não criar rotas públicas de cadastro.

---

## 11. Fluxo de autenticação

Ao receber uma solicitação de login:

1. Validar os parâmetros.
2. Aplicar os controles de frequência.
3. Normalizar o e-mail.
4. Localizar o usuário.
5. Verificar a senha.
6. Verificar se o usuário está ativo.
7. Verificar as condições de acesso.
8. Gerar uma nova sessão autenticada.
9. Configurar o cookie de sessão.
10. Verificar must_change_password.
11. Redirecionar para a página apropriada.

Não autenticar usuários inativos.

Não utilizar o perfil recebido pelo navegador.

Obter o perfil exclusivamente
do registro persistido no PostgreSQL.

---

## 12. Validação de credenciais

Utilizar o mecanismo existente:

    has_secure_password

Reutilizar o método de verificação
disponibilizado pelo Rails.

Não comparar diretamente
senhas em texto simples.

Não implementar comparação própria
de hashes criptográficos.

Não registrar a senha durante a autenticação.

Não incluir a senha em mensagens de erro.

Não retornar password_digest.

---

## 13. Mensagem de autenticação inválida

Utilizar uma mensagem genérica:

    E-mail ou senha inválidos.

Apresentar a mesma mensagem para:

- E-mail inexistente.
- Senha incorreta.
- Usuário inativo.

Não informar publicamente
se determinado e-mail está cadastrado.

Não informar publicamente
se uma conta está desativada.

Evitar diferenças desnecessárias
nos códigos HTTP e tempos de resposta
que facilitem enumeração de contas.

Avaliar a utilização de uma verificação
de hash equivalente para usuários inexistentes.

Não realizar esperas artificiais
que facilitem esgotamento de recursos.

---

## 14. Criação segura da sessão

Após a autenticação bem-sucedida:

- Renovar o contexto de sessão.
- Invalidar identificadores pré-autenticação.
- Gerar uma credencial imprevisível.
- Persistir a sessão.
- Associar a sessão ao usuário.
- Registrar horário de criação.
- Registrar horário da última atividade.
- Definir a expiração.

Utilizar um gerador criptograficamente seguro
disponibilizado pelo Ruby ou Rails.

Quando utilizado token opaco próprio,
gerar pelo menos 256 bits de entropia.

Persistir somente seu digest.

Não utilizar:

- E-mail como token.
- ID do usuário como token.
- Timestamp como token.
- Valores sequenciais.
- Identificadores fornecidos pelo navegador.

Prevenir Session Fixation.

---

## 15. Cookies de autenticação

Utilizar cookies protegidos.

Configurações esperadas em produção:

    HttpOnly: true

    Secure: true

    SameSite: Lax

Utilizar escopo de domínio restrito.

Preferir cookies host-only.

Não compartilhar cookies indiscriminadamente
entre subdomínios.

Não armazenar diretamente no cookie:

- Senha.
- Password digest.
- Perfil de acesso.
- Estado ativo ou inativo.
- Dados cadastrais completos.

O cookie deverá conter somente a credencial
ou referência segura necessária à sessão.

Validar a sessão no backend.

Em desenvolvimento local HTTP,
adaptar somente o atributo Secure quando necessário.

Não enfraquecer as configurações de produção.

---

## 16. Expiração das sessões

Definir inicialmente:

    Tempo máximo de inatividade:
        30 minutos

    Duração máxima absoluta:
        12 horas

Centralizar as configurações.

A expiração deverá ser validada no backend.

Não confiar no relógio do navegador.

### Expiração por inatividade

Caso o usuário permaneça sem atividade
relevante por 30 minutos,
invalidar a sessão.

### Expiração absoluta

Após 12 horas desde a autenticação,
a sessão deverá expirar independentemente
da atividade realizada.

Não implementar sessões permanentes.

Não implementar Remember Me.

---

## 17. Integração com o polling do RF009

IMPORTANTE:

O Dashboard realiza consultas automáticas
aproximadamente a cada cinco segundos.

Essas consultas não deverão renovar
automaticamente a inatividade da sessão.

Caso contrário, um computador abandonado
com o Dashboard aberto poderia permanecer
autenticado indefinidamente até a expiração absoluta.

Diferenciar:

- Solicitação automática de polling.
- Navegação administrativa explícita.
- Atualização manual.
- Operações administrativas iniciadas pelo usuário.

Consultas automáticas não deverão atualizar:

    last_seen_at

Não confiar exclusivamente em um parâmetro
enviado pelo navegador para identificar
o polling.

Preferir distinguir os fluxos por rotas
e responsabilidades no servidor.

Caso seja utilizada a mesma rota,
avaliar a separação necessária entre
atualização automática e interação explícita.

O polling deverá continuar verificando
a validade da sessão em cada requisição.

---

## 18. Sessão expirada durante o polling

Considerar:

    Operador mantém o Dashboard aberto.

    A sessão expira por inatividade.

    Uma solicitação automática é realizada.

Resultado esperado:

- O backend rejeita a solicitação.
- A atualização automática é interrompida.
- Os temporizadores são encerrados.
- O conteúdo administrativo deixa de ficar visível.
- O usuário é encaminhado ao login.

Apresentar:

    Sua sessão expirou.
    Entre novamente para continuar.

Não substituir a matriz administrativa
por uma página de login dentro de um Turbo Frame.

Tratar respostas de autenticação expirada
de maneira apropriada.

Não realizar tentativas infinitas
de atualização após HTTP 401.

Não exibir dados administrativos
restaurados pelo cache do Turbo.

Preservar o tratamento de falhas de rede
implementado no RF009 para situações
que não sejam relacionadas à autenticação.

---

## 19. Controle de acesso centralizado

Criar uma estrutura centralizada
para autenticação administrativa.

Exemplo conceitual:

    ApplicationController

        |

    Admin::BaseController

        |

    Controllers administrativos

O controller administrativo base deverá
verificar a autenticação antes de executar
as ações protegidas.

Reutilizar a estrutura existente,
quando disponível.

Evitar duplicação de verificações
em todos os controllers.

Adotar comportamento de negação por padrão.

Uma nova rota administrativa não deverá
ficar pública apenas porque o desenvolvedor
esqueceu de adicionar uma verificação.

---

## 20. Usuário autenticado

Disponibilizar uma referência centralizada
ao usuário autenticado na requisição.

Exemplo:

    current_user

Ou:

    Current.user

Utilizar a abordagem compatível
com a versão do Rails e com o projeto.

O usuário autenticado deverá ser obtido
a partir da sessão validada.

Não aceitar como identidade autenticada:

- user_id recebido em parâmetros.
- actor_id enviado pelo navegador.
- E-mail informado em campos hidden.
- Perfil recebido através de JavaScript.
- Dados arbitrários armazenados em cookies.

Limpar o contexto da requisição
adequadamente após seu encerramento.

Não compartilhar o usuário autenticado
entre requisições concorrentes.

---

## 21. Validação contínua do usuário

A cada requisição administrativa,
verificar:

- Existência da sessão.
- Validade da credencial.
- Ausência de revogação.
- Expiração absoluta.
- Expiração por inatividade.
- Existência do usuário.
- Estado ativo do usuário.
- Perfil atual.
- Obrigatoriedade de alteração de senha.

Não confiar exclusivamente nas informações
existentes no momento do login.

Uma alteração administrativa de perfil
ou estado deverá produzir efeito
nas próximas requisições.

---

## 22. Autorização por perfil

Reutilizar os perfis existentes:

    admin

    operator

    viewer

Implementar autorização no backend.

Centralizar a matriz de permissões
em uma estrutura simples.

Não criar tabelas dinâmicas de permissões.

Não criar permissões individuais
personalizadas neste requisito.

Não utilizar condições diferentes
e inconsistentes entre controllers.

Aplicar negação por padrão
para funcionalidades não autorizadas.

---

## 23. Perfil Administrador

O perfil admin deverá possuir acesso a:

- Dashboard.
- Consulta de agendamentos.
- Comprovantes.
- Check-in.
- Liberação.
- Cancelamento.
- Alteração.
- Reagendamento.
- Bloqueio.
- Desbloqueio.
- Histórico operacional.
- Histórico de gerenciamento de usuários.
- Exportação Excel.
- Cadastro de usuários.
- Edição de usuários.
- Alteração de perfis.
- Ativação.
- Desativação.
- Redefinição administrativa de senha.
- Configurações futuras.

O administrador também deverá
poder alterar a própria senha.

Não implementar configurações
relacionadas ao RF013 ou RF014.

---

## 24. Perfil Operador

O perfil operator deverá possuir acesso a:

- Dashboard.
- Consulta de agendamentos.
- Comprovantes.
- Check-in.
- Liberação.
- Cancelamento.
- Alteração.
- Reagendamento.
- Bloqueio.
- Desbloqueio.
- Histórico operacional.
- Exportação Excel.
- Consulta do próprio perfil.
- Alteração da própria senha.

Não permitir:

- Gerenciar usuários.
- Alterar perfis.
- Ativar contas.
- Desativar contas.
- Redefinir senhas de terceiros.
- Consultar auditoria de usuários.
- Consultar eventos restritos de segurança.
- Gerenciar configurações administrativas.

---

## 25. Perfil Consulta

O perfil viewer deverá possuir acesso a:

- Dashboard.
- Consulta de agendamentos.
- Comprovantes.
- Consulta de bloqueios.
- Histórico operacional.
- Exportação Excel.
- Consulta do próprio perfil.
- Alteração da própria senha.

Não permitir:

- Check-in.
- Liberação.
- Cancelamento.
- Alteração de reservas.
- Reagendamento.
- Criação de bloqueios.
- Desbloqueios.
- Gerenciamento de usuários.
- Alteração de perfis.
- Redefinição de senhas de terceiros.
- Auditoria de usuários.
- Eventos restritos de segurança.
- Configurações administrativas.

O perfil Consulta será somente leitura
em relação aos dados operacionais.

A alteração da própria senha
será uma exceção necessária.

---

## 26. Matriz centralizada

Implementar a matriz abaixo.

Funcionalidade                 Admin  Operator  Viewer

Dashboard                       Sim     Sim      Sim
Consultar agendamentos          Sim     Sim      Sim
Visualizar comprovantes         Sim     Sim      Sim
Consultar bloqueios             Sim     Sim      Sim
Check-in                        Sim     Sim      Não
Liberação                       Sim     Sim      Não
Cancelamento                    Sim     Sim      Não
Alteração                       Sim     Sim      Não
Reagendamento                   Sim     Sim      Não
Bloqueio                        Sim     Sim      Não
Desbloqueio                     Sim     Sim      Não
Histórico operacional           Sim     Sim      Sim
Exportação Excel                Sim     Sim      Sim
Gerenciamento de usuários       Sim     Não      Não
Auditoria de usuários           Sim     Não      Não
Eventos restritos de segurança  Sim     Não      Não
Configurações administrativas   Sim     Não      Não
Consultar próprio perfil        Sim     Sim      Sim
Alterar própria senha           Sim     Sim      Sim

Não utilizar essa matriz apenas
como documentação.

As permissões deverão ser efetivamente
aplicadas em todas as rotas existentes.

---

## 27. Proteção contra acesso direto

Considerar:

    Usuário com perfil Consulta.

    Botão Check-in não apresentado.

    Usuário envia manualmente uma solicitação
    PATCH para a rota de check-in.

Resultado esperado:

    HTTP 403 Forbidden.

Nenhuma operação deverá ser realizada.

Nenhuma reserva deverá ser modificada.

Nenhuma auditoria de sucesso deverá ser criada.

Aplicar a mesma proteção para:

- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- Desbloqueios.
- Gerenciamento de usuários.
- Redefinição de senha.
- Outras operações restritas.

Não confiar exclusivamente na interface.

---

## 28. Respostas de acesso não autorizado

Distinguir:

### Usuário não autenticado

Para navegação HTML normal:

    Redirecionar para /login.

Para solicitações dinâmicas de polling:

    HTTP 401 Unauthorized.

### Usuário autenticado sem permissão

    HTTP 403 Forbidden.

Apresentar uma página adequada:

    Acesso não autorizado

    Você não possui permissão para
    acessar esta funcionalidade.

Disponibilizar uma opção para retornar
ao Dashboard.

Não redirecionar continuamente
entre páginas incompatíveis.

Não apresentar detalhes técnicos
da política de autorização.

---

## 29. Redirecionamento após login

Após autenticação válida:

    /admin

Caso exista uma página anteriormente solicitada,
permitir retornar somente para uma rota
administrativa interna válida e autorizada.

Não permitir redirecionamento arbitrário
para endereços externos.

Proteger contra Open Redirect.

Não aceitar URLs absolutas não confiáveis.

Não utilizar valores de redirecionamento
fornecidos pelo navegador sem validação.

Caso a troca de senha seja obrigatória,
ela terá prioridade sobre o Dashboard.

---

## 30. Identificação no Header

Adicionar ao Header administrativo:

- Nome do usuário autenticado.
- Perfil apresentado em português.
- Avatar simples com iniciais, quando adequado.
- Menu de ações da conta.

Exemplo:

    Carlos Almeida

    Administrador

Preservar o Header existente.

Preservar:

- Logo.
- Identidade visual.
- Sidebar.
- Responsividade.

Não reconstruir o layout administrativo.

Não apresentar dados técnicos da sessão.

---

## 31. Menu do usuário

Disponibilizar:

    Meu perfil

    Alterar senha

    Sair do sistema

Utilizar o padrão visual existente.

O menu deverá funcionar
com navegação por teclado.

Não adicionar bibliotecas externas
exclusivamente para implementar o menu.

Utilizar recursos nativos de HTML
ou Stimulus, quando necessário.

---

## 32. Sidebar por perfil

Apresentar os menus conforme as permissões.

### Administrador

    Dashboard
    Agendamentos
    Bloqueios
    Histórico
    Usuários

### Operador

    Dashboard
    Agendamentos
    Bloqueios
    Histórico

### Consulta

    Dashboard
    Agendamentos
    Bloqueios
    Histórico

O perfil Consulta poderá visualizar bloqueios,
mas não poderá criá-los ou removê-los.

Ocultar ações incompatíveis
com o perfil autenticado.

Preservar a autorização no backend.

Não adicionar menus do RF013 ou RF014.

---

## 33. Meu perfil

Criar uma página simples
para consulta da própria conta.

Apresentar:

- Nome completo.
- E-mail.
- Perfil de acesso.
- Estado da conta.
- Data de cadastro.
- Data da última alteração de senha,
  quando disponível.

Disponibilizar:

    Alterar senha

Não permitir que o usuário altere
o próprio perfil de acesso.

Não permitir que altere diretamente:

- active.
- role.
- must_change_password.
- password_digest.

Neste requisito, alterações de nome e e-mail
continuarão sendo realizadas pelo administrador.

---

## 34. Alteração da própria senha

Criar um formulário contendo:

- Senha atual.
- Nova senha.
- Confirmação da nova senha.

Validar a senha atual.

Aplicar a política implementada no RF015.

Preservar:

- Comprimento mínimo.
- Limite técnico do bcrypt.
- Validação de confirmação.
- Suporte a caracteres Unicode.
- Proteção contra truncamento silencioso.

Não aceitar uma nova senha idêntica
à senha atual.

Não solicitar envio de e-mail.

Não implementar recuperação externa.

---

## 35. Persistência da alteração de senha

Ao alterar a própria senha:

- Verificar novamente a sessão.
- Verificar a senha atual.
- Validar a nova senha.
- Gerar novo password_digest.
- Atualizar password_changed_at.
- Definir must_change_password = false.
- Atualizar lock_version.
- Registrar a auditoria.
- Revogar as sessões anteriores.

Executar as alterações críticas
na mesma transação.

Não registrar senhas ou hashes.

Após confirmação:

- Encerrar a sessão anterior.
- Encaminhar o usuário ao login.
- Solicitar autenticação com a nova senha.

Não manter outras sessões autenticadas
utilizando credenciais anteriores.

---

## 36. Primeiro acesso

Utilizar o atributo existente:

    must_change_password

Quando estiver definido como true:

- Permitir a autenticação inicial.
- Criar uma sessão restrita.
- Redirecionar para a alteração obrigatória
  de senha.
- Impedir acesso às funcionalidades
  administrativas normais.

Até a conclusão da alteração,
permitir exclusivamente:

- Formulário de alteração de senha.
- Confirmação da alteração de senha.
- Logout.

Não permitir que o usuário ignore
a alteração obrigatória acessando
diretamente uma rota administrativa.

---

## 37. Tela de alteração obrigatória

Apresentar:

    Alteração de senha obrigatória

Mensagem:

    Por segurança, é necessário definir
    uma nova senha antes de continuar.

Campos:

- Senha atual.
- Nova senha.
- Confirmação da nova senha.

Botões:

    Alterar senha

    Sair

Não apresentar a Sidebar operacional
como se o acesso estivesse liberado.

Após a alteração bem-sucedida,
encerrar a sessão restrita.

Redirecionar ao login.

O usuário deverá autenticar-se
com a nova senha.

---

## 38. Redefinição administrativa de senha

Reutilizar a funcionalidade do RF015.

Após um administrador redefinir
a senha de outro usuário:

- Atualizar password_digest.
- Atualizar password_changed_at.
- Definir must_change_password = true.
- Revogar todas as sessões existentes.
- Registrar a auditoria.

Na próxima tentativa de acesso,
o usuário deverá utilizar a senha redefinida.

Exigir a alteração obrigatória
no primeiro login após a redefinição.

Não permitir que sessões anteriores
continuem funcionando.

Não enviar credenciais por e-mail.

---

## 39. Desativação de usuários

Integrar a desativação do RF015
ao mecanismo de sessões.

Ao desativar uma conta:

- Atualizar active.
- Atualizar deactivated_at.
- Revogar todas as sessões existentes.
- Registrar o motivo.
- Registrar o operador responsável.

Executar a desativação e a revogação
de maneira transacional.

Após a confirmação:

- O usuário não poderá realizar login.
- Sessões anteriores serão rejeitadas.
- Solicitações de polling serão rejeitadas.
- Novas operações administrativas serão impedidas.

Preservar a proteção do último
administrador ativo.

---

## 40. Reativação de usuários

Ao reativar uma conta:

- Preservar o usuário original.
- Preservar seu histórico.
- Permitir novas autenticações válidas.

Não restaurar sessões revogadas.

Não reativar cookies anteriores.

Não criar sessões automaticamente.

O usuário deverá realizar um novo login.

Preservar as regras de alteração
obrigatória de senha existentes.

---

## 41. Alteração de perfil

Ao alterar o perfil de um usuário:

- Registrar o perfil anterior.
- Registrar o novo perfil.
- Revogar suas sessões existentes.
- Registrar a auditoria.

O usuário deverá autenticar-se novamente.

Não manter permissões antigas
em cookies ou sessões.

Preservar a proteção do último administrador.

Tratar alterações de perfil realizadas
durante requisições concorrentes.

---

## 42. Alteração do e-mail de login

Quando um administrador alterar
o e-mail de um usuário:

- Preservar o ID interno.
- Aplicar normalização.
- Validar unicidade.
- Revogar sessões existentes.
- Registrar a alteração.

O usuário deverá utilizar o novo e-mail
nas próximas autenticações.

Não enviar mensagens de confirmação.

Não depender do RF014.

---

## 43. Logout

Disponibilizar:

    Sair do sistema

Ao realizar logout:

- Revogar a sessão atual.
- Remover o cookie de autenticação.
- Limpar os dados de sessão necessários.
- Encerrar o contexto autenticado.
- Redirecionar para /login.

Não utilizar GET para logout.

Preservar a proteção CSRF.

O logout não deverá necessariamente
revogar outras sessões do mesmo usuário.

Uma sessão encerrada não poderá
ser reutilizada posteriormente.

---

## 44. Proteção contra cache após logout

Configurar as respostas administrativas
com cabeçalhos apropriados.

Priorizar:

    Cache-Control: no-store

Avaliar o cache de navegação do Turbo.

Impedir que o botão Voltar do navegador
restaure uma página administrativa
como se ainda estivesse autenticada.

Desabilitar snapshots administrativos
quando necessário.

Tratar restauração pelo back-forward cache
do navegador.

Verificar a validade da sessão
quando necessário antes de reapresentar
conteúdo administrativo.

Não afirmar que cabeçalhos HTTP conseguem
apagar capturas de tela ou conteúdo
já copiado pelo usuário.

---

## 45. Proteção contra tentativas excessivas de login

Implementar rate limiting
para a rota de autenticação.

Definição inicial proposta:

    Por e-mail normalizado:
        5 tentativas malsucedidas
        em uma janela de 15 minutos.

    Por endereço IP:
        30 tentativas de autenticação
        em uma janela de 15 minutos.

Centralizar os limites.

Aplicar os controles também
a contas inexistentes.

Não depender exclusivamente
de estado armazenado em memória
de um processo Puma.

A proteção deverá funcionar
com múltiplos processos da aplicação.

Reutilizar mecanismos compartilhados
já existentes, quando disponíveis.

Caso necessário, utilizar PostgreSQL
para persistir contadores temporários.

Não introduzir Redis.

Não criar bloqueios permanentes
de contas por tentativas malsucedidas.

---

## 46. Tratamento do limite de tentativas

Ao atingir o limite aplicável:

- Rejeitar temporariamente novas tentativas.
- Retornar HTTP 429 Too Many Requests.
- Apresentar mensagem genérica.

Exemplo:

    Muitas tentativas de acesso.
    Aguarde alguns minutos e tente novamente.

Não revelar:

- Existência do usuário.
- Quantidade exata de tentativas restantes.
- Estado interno da conta.
- Informações de outros usuários.

Utilizar Retry-After quando apropriado.

Garantir expiração dos contadores.

Não permitir crescimento ilimitado
da estrutura de controle.

Avaliar o risco de bloqueio temporário
provocado deliberadamente por terceiros.

Documentar essa limitação.

---

## 47. Endereço IP e proxies

Não confiar diretamente
em cabeçalhos arbitrários:

    X-Forwarded-For

    X-Real-IP

Utilizar a configuração apropriada
de proxies confiáveis do Rails.

Considerar a arquitetura futura:

    Cliente
        |
    Cloudflare, quando utilizado
        |
    Nginx no host
        |
    Puma no container

Não realizar a implantação
neste requisito.

Documentar as configurações necessárias
para que a identificação do IP seja confiável
quando o sistema estiver em produção.

Não permitir que o participante
burle o rate limiting simplesmente
alterando cabeçalhos HTTP.

---

## 48. Auditoria dos operadores

Estender a tabela existente:

    audit_events

Adicionar um relacionamento opcional
com o usuário responsável pela operação.

Campo conceitual:

    actor_user_id
        bigint
        nullable
        foreign key para users.id

Adicionar índice apropriado.

Preservar os registros anteriores.

Não modificar eventos históricos
para atribuí-los a usuários atuais.

Eventos anteriores ao RF016
continuarão sem identificação individual.

Não atribuir operações antigas
ao administrador inicial.

---

## 49. Origem dos eventos

Distinguir:

    public_form

    authenticated_user

    system

    bootstrap

    unknown

A nomenclatura poderá ser adaptada
às convenções existentes.

Caso seja necessário adicionar
um atributo de origem na auditoria,
utilizar uma nova migration.

Não atualizar indiscriminadamente
os registros históricos.

Não enfraquecer a proteção append-only
para preencher dados que não existiam.

Preservar a interpretação histórica
implementada no RF011.

---

## 50. Identificação histórica do operador

Ao registrar uma nova operação
realizada por um usuário autenticado,
preservar:

- ID do usuário responsável.
- Nome do operador no momento do evento.
- Perfil no momento do evento.
- Origem da operação.

Avaliar a utilização de campos
ou snapshots específicos e limitados.

Não serializar todos os atributos
do usuário.

Não armazenar:

- Password digest.
- Senha.
- Token de sessão.
- Cookie.
- Credenciais.

Preservar o nome histórico do operador
mesmo que seu nome seja alterado futuramente.

Não depender exclusivamente
dos dados cadastrais atuais para representar
uma operação realizada no passado.

---

## 51. Auditoria de check-in

Ao realizar check-in:

- Preservar as informações anteriores.
- Preservar as informações posteriores.
- Registrar o usuário autenticado.

Exemplo conceitual:

    entity_type: Booking

    entity_id: 123

    action: checkin

    actor_user_id: 8

    actor_name: Carlos Almeida

    actor_role: operator

    origin: authenticated_user

    created_at: horário real do evento

Não aceitar actor_user_id
proveniente do formulário.

Obter o responsável exclusivamente
do contexto autenticado.

---

## 52. Auditoria das demais operações

Aplicar a identificação do responsável
a todas as operações administrativas:

- Check-in.
- Liberação.
- Cancelamento.
- Alteração.
- Reagendamento.
- Bloqueio.
- Desbloqueio.
- Cadastro de usuários.
- Edição de usuários.
- Alteração de perfil.
- Ativação.
- Desativação.
- Redefinição administrativa de senha.
- Alteração da própria senha.

Preservar a auditoria transacional.

Não registrar sucesso para operações
rejeitadas ou revertidas.

---

## 53. Auditoria do formulário público

A criação de uma reserva pública
deverá continuar sem usuário autenticado
como responsável.

Exemplo:

    actor_user_id: null

    origin: public_form

Mesmo que um administrador esteja
autenticado no mesmo navegador
e acesse o formulário público,
não atribuir automaticamente a reserva
pública a esse usuário administrativo.

Preservar a separação entre os contextos.

---

## 54. Auditoria do no-show

Preservar o processamento do RF008.

Eventos de no-show deverão possuir:

    actor_user_id: null

    origin: system

Não atribuir a tarefa automática
a um usuário fictício.

Não exigir sessão autenticada
para o worker.

Não depender do usuário conectado
ao Dashboard.

Preservar o funcionamento automático
independentemente das sessões existentes.

---

## 55. Auditoria do bootstrap

Preservar a tarefa de criação
do primeiro administrador.

Novos eventos realizados por essa tarefa
deverão possuir origem apropriada:

    bootstrap

Não atribuir um responsável autenticado
quando não existir autenticação.

Não criar uma sessão fictícia.

Não registrar credenciais.

---

## 56. Eventos de autenticação

Registrar eventos relevantes de segurança.

Exemplos:

    login_success

    login_failed

    logout

    password_changed

    session_revoked

    login_rate_limited

Avaliar a utilização da auditoria existente
para eventos bem-sucedidos associados
a usuários identificáveis.

Para falhas de login e rate limiting,
preferir registros técnicos estruturados,
limitados e protegidos.

Não inventar um usuário para tentativas
envolvendo e-mails inexistentes.

Não gerar quantidade ilimitada de eventos
append-only a partir de solicitações públicas.

Não registrar um evento de auditoria
a cada consulta do Dashboard.

---

## 57. Proteção das informações de segurança

Nunca registrar:

- Senha atual.
- Senha nova.
- Confirmação de senha.
- Password digest.
- Token de sessão.
- Cookie de autenticação.
- Credenciais de infraestrutura.

Minimizar informações pessoais
nos logs de tentativas malsucedidas.

Não apresentar identificadores sensíveis
nas mensagens de erro.

Definir uma política técnica limitada
de retenção dos logs de autenticação.

Não alterar a política de preservação
da auditoria operacional do RF011.

---

## 58. Integração com o histórico

Atualizar o histórico existente.

Nos eventos administrativos,
apresentar:

    Realizado por: Carlos Almeida

    Perfil: Operador

    Origem: Painel administrativo

Nos eventos automáticos:

    Realizado por: Sistema automático

Nos eventos públicos:

    Origem: Formulário público

Nos eventos anteriores ao RF016:

    Responsável não registrado

Não inventar informações históricas.

Preservar os filtros existentes.

Adicionar filtro por operador,
quando compatível com a estrutura atual.

Utilizar o relacionamento persistido.

Não pesquisar usuários por credenciais.

---

## 59. Restrição da auditoria por perfil

O administrador poderá consultar
todos os eventos autorizados.

Operadores e usuários de consulta
poderão consultar somente
a auditoria operacional.

Restringir os eventos relacionados a:

- Gerenciamento de usuários.
- Alterações de perfis.
- Desativação de contas.
- Redefinição de senhas.
- Autenticação.
- Eventos restritos de segurança.

Aplicar a restrição nas consultas
e nos detalhes de cada evento.

Não permitir acesso por URL direta.

Não revelar registros restritos
através de filtros manipulados,
contagens ou paginação.

---

## 60. Auditoria de exportação Excel

Integrar a exportação do RF012
à identificação dos operadores.

Registrar um evento administrativo
por exportação efetivamente gerada.

Registrar:

- Usuário responsável.
- Data e horário.
- Quantidade de registros.
- Filtros operacionais utilizados.

Não registrar:

- Conteúdo integral da planilha.
- Dados cadastrais de cada linha.
- Notas fiscais.
- Placas.
- Credenciais.
- Caminhos temporários.

Não criar uma auditoria por linha exportada.

Distinguir geração do arquivo
de download efetivamente concluído
pelo navegador.

Não afirmar que o destinatário recebeu
o arquivo apenas porque o servidor o gerou.

Preservar as 26 colunas do RF012.

---

## 61. Concorrência e revogação

Considerar:

    Usuário autenticado inicia uma operação.

    Administrador desativa esse usuário.

    A operação ainda está sendo processada.

Implementar uma estratégia que preserve
a consistência das operações sensíveis.

Para alterações administrativas,
revalidar o estado e as permissões
dentro da unidade crítica apropriada.

Coordenar as travas com as estratégias
existentes dos RF003 até RF008 e RF015.

Documentar a ordem de aquisição
das travas para evitar deadlocks.

Não permitir que uma operação iniciada
após a revogação utilize permissões antigas.

Definir claramente o comportamento
de operações já confirmadas ou em andamento
no momento da revogação.

Não prometer cancelamento retroativo
de transações já confirmadas.

---

## 62. Proteção CSRF

Preservar a proteção CSRF do Rails.

Aplicar às operações:

- Login.
- Logout.
- Alteração de senha.
- Cadastro de usuários.
- Edição de usuários.
- Redefinição de senha.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- Desbloqueios.

Não utilizar skip_forgery_protection
como solução genérica.

Não desabilitar CSRF para facilitar
a integração com Turbo ou Stimulus.

Testar explicitamente a proteção,
inclusive no fluxo de login.

---

## 63. Content Security Policy

Preservar a política existente.

Não introduzir:

- unsafe-eval.
- Scripts inline não autorizados.
- Scripts externos desnecessários.
- Handlers JavaScript inline.
- CDNs sem necessidade.

Não desabilitar a CSP
para implementar a autenticação.

Preservar o escaping padrão do ERB.

Não utilizar raw ou html_safe
para apresentar dados de usuários.

---

## 64. Strong Parameters

Utilizar listas explícitas de atributos.

### Login

    email
    password

### Alteração da própria senha

    current_password
    password
    password_confirmation

Não aceitar atributos internos como:

    role
    active
    actor_user_id
    password_digest
    must_change_password
    session_id
    expires_at
    revoked_at

A identidade autenticada deverá
ser determinada pelo servidor.

Não permitir elevação de privilégios
através de parâmetros manipulados.

---

## 65. Filtragem de logs

Verificar config.filter_parameters.

Garantir filtragem de:

- password.
- current_password.
- password_confirmation.
- password_digest.
- token.
- token_digest.
- session_token.
- Credenciais.
- Outros atributos sensíveis existentes.

Validar parâmetros aninhados.

Não registrar cookies completos.

Não registrar objetos User ou Session
integralmente em logs de depuração.

Não expor dados sensíveis
em mensagens de exceção.

---

## 66. Limpeza das sessões

Implementar uma estratégia controlada
de limpeza de sessões expiradas e revogadas.

Referência inicial:

    Preservar registros de sessão
    por até 30 dias após sua expiração
    ou revogação.

Após esse período, permitir remoção
dos registros técnicos desnecessários.

Reutilizar o mecanismo de tarefas
existente do RF008, quando apropriado.

Preferir uma tarefa diária.

Não excluir usuários.

Não excluir eventos de auditoria.

Não remover sessões válidas.

A limpeza das sessões não deverá
interferir na preservação do histórico
operacional ou de gerenciamento de contas.

Documentar a estratégia adotada.

---

## 67. Proteções por ambiente

IMPORTANTE:

Nos requisitos anteriores,
as rotas administrativas estavam restritas
a development e test porque ainda não existia
autenticação definitiva.

Neste requisito, substituir a dependência
exclusiva dessas restrições por autenticação
e autorização centralizadas.

Entretanto, não liberar automaticamente
a aplicação administrativa em produção.

Manter uma proteção explícita de publicação
em produção até RF017 e RF018.

Exemplo conceitual:

    ADMIN_ACCESS_ENABLED

O comportamento padrão em produção
deverá ser restritivo.

A eventual habilitação deverá exigir:

- Configuração explícita.
- Autenticação obrigatória.
- Autorização obrigatória.
- Sessões seguras.
- Configuração de HTTPS.
- Homologação de segurança.

Nenhuma configuração deverá permitir
ignorar autenticação em produção.

Realizar testes de produção com as proteções
ativas em ambiente isolado.

Não implantar na VPS neste requisito.

---

## 68. Configurações de produção

Preparar e documentar:

- Cookies Secure.
- HTTPS obrigatório.
- Configuração de proxies confiáveis.
- Secret key base.
- Variáveis de ambiente.
- Configuração de sessão.
- Proteções de cache.
- Rate limiting.
- HSTS, quando apropriado.

Não incluir valores reais de segredos
no repositório.

Atualizar .env.example somente
com valores ilustrativos seguros.

Não modificar diretamente configurações
do servidor de produção.

Não realizar deploy.

A publicação efetiva será responsabilidade
do RF018, após a revisão do RF017.

---

## 69. Infraestrutura

Preservar o Docker Compose existente.

Não adicionar containers exclusivamente
para autenticação.

Preservar:

- Rails.
- Puma.
- PostgreSQL.
- Worker existente.
- Volumes.
- Configurações de rede.

Não adicionar Redis.

Não adicionar servidores externos
de identidade.

Não alterar a publicação de portas.

Não adicionar Nginx dentro do Docker.

Não executar operações destrutivas
em bancos ou volumes.

---

## 70. Organização do backend

Estrutura conceitual:

    app/
    ├── models/
    │   ├── user.rb
    │   ├── session.rb
    │   └── current.rb
    │
    ├── controllers/
    │   ├── sessions_controller.rb
    │   ├── passwords_controller.rb
    │   └── admin/
    │       ├── base_controller.rb
    │       └── profiles_controller.rb
    │
    ├── services/
    │   ├── authentication/
    │   └── authorization/
    │
    └── views/
        ├── sessions/
        │   └── new.html.erb
        │
        ├── passwords/
        │   └── edit.html.erb
        │
        └── admin/
            └── profiles/
                └── show.html.erb

A estrutura é somente uma sugestão.

Adaptar às convenções existentes.

Não criar arquivos ou abstrações
sem necessidade.

Centralizar responsabilidades.

Não duplicar regras de autorização.

Não executar consultas diretamente nas views.

---

## 71. JavaScript

Utilizar somente quando necessário
para melhorar a experiência visual.

Responsabilidades permitidas:

- Mostrar ou ocultar senha.
- Controlar o menu do usuário.
- Tratar expiração durante o polling.
- Encerrar temporizadores.
- Melhorar mensagens visuais.

Não utilizar JavaScript para:

- Autenticar definitivamente usuários.
- Definir permissões.
- Gerar password_digest.
- Armazenar tokens de sessão.
- Consultar diretamente o banco.
- Proteger exclusivamente as rotas.

Não armazenar credenciais em:

- localStorage.
- sessionStorage.
- IndexedDB.

Não expor tokens em atributos HTML.

---

## 72. Responsividade e acessibilidade

Garantir:

- Login funcional em dispositivos móveis.
- Campos adequados para preenchimento.
- Labels associados aos inputs.
- Navegação por teclado.
- Estados de foco visíveis.
- Contraste adequado.
- Mensagens de erro compreensíveis.
- Compatibilidade com gerenciadores de senhas.

Utilizar autocomplete apropriado:

    username

    current-password

    new-password

Não impedir a colagem de senhas.

Não desabilitar o zoom do navegador.

Preservar a responsividade administrativa.

---

## 73. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 73.1 Autenticação

Validar:

- Login válido.
- E-mail inexistente.
- Senha incorreta.
- Usuário inativo.
- Normalização de e-mail.
- Mensagens genéricas.
- Ausência de enumeração direta.
- Criação da sessão.

### 73.2 Sessões

Validar:

- Credencial imprevisível.
- Digest persistido.
- Cookie protegido.
- Renovação após login.
- Prevenção de Session Fixation.
- Sessão inexistente.
- Sessão revogada.
- Sessão expirada.
- Expiração por inatividade.
- Expiração absoluta.
- Reutilização de cookie inválido.

### 73.3 Polling

Validar:

- Atualização automática autenticada.
- Polling não renova inatividade.
- Sessão expirada durante atualização.
- HTTP 401 tratado corretamente.
- Encerramento de temporizadores.
- Redirecionamento ao login.
- Ausência de conteúdo administrativo
  restaurado indevidamente.

### 73.4 Autorização

Validar toda a matriz de permissões.

Testar os três perfis.

Verificar todas as rotas administrativas.

Testar requisições diretas para operações
não permitidas.

Não testar somente a presença
ou ausência de botões.

### 73.5 Perfil Administrador

Validar:

- Acesso às funcionalidades operacionais.
- Gerenciamento de usuários.
- Consulta da auditoria de usuários.
- Redefinição de senha.
- Exportação Excel.

### 73.6 Perfil Operador

Validar:

- Acesso ao Dashboard.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- Desbloqueios.
- Exportação Excel.
- Rejeição do gerenciamento de usuários.
- Rejeição da auditoria restrita.

### 73.7 Perfil Consulta

Validar:

- Consulta ao Dashboard.
- Consulta de agendamentos.
- Consulta de bloqueios.
- Consulta de histórico operacional.
- Exportação Excel.
- Rejeição de check-in.
- Rejeição de liberação.
- Rejeição de cancelamento.
- Rejeição de reagendamento.
- Rejeição de bloqueios.
- Rejeição de desbloqueios.
- Rejeição de gerenciamento de usuários.

### 73.8 Primeiro acesso

Validar:

- Usuário com must_change_password.
- Redirecionamento obrigatório.
- Sessão restrita.
- Bloqueio de rotas administrativas.
- Alteração válida.
- Rejeição de senha incorreta.
- Nova autenticação após alteração.

### 73.9 Redefinição administrativa

Validar:

- Redefinição bem-sucedida.
- Invalidação de sessões anteriores.
- Senha antiga rejeitada.
- Nova senha aceita.
- Troca obrigatória ativada.
- Auditoria registrada.

### 73.10 Desativação e reativação

Validar:

- Revogação das sessões.
- Login rejeitado após desativação.
- Polling rejeitado.
- Operações administrativas rejeitadas.
- Reativação sem restaurar sessões.
- Proteção do último administrador.

### 73.11 Alteração de perfil e e-mail

Validar:

- Revogação das sessões.
- Permissões antigas invalidadas.
- Novo perfil aplicado.
- Novo e-mail aplicado.
- Preservação da auditoria.

### 73.12 Logout

Validar:

- Revogação da sessão atual.
- Remoção do cookie.
- Reutilização da sessão rejeitada.
- Logout por GET não permitido.
- Proteção CSRF.
- Ausência de acesso indevido pelo cache.

### 73.13 Rate limiting

Validar:

- Limite por conta.
- Limite por IP.
- Contas inexistentes.
- Expiração dos contadores.
- HTTP 429.
- Concorrência.
- Múltiplos processos ou conexões.
- Ausência de bloqueio permanente.
- Proteção contra manipulação de cabeçalhos.

### 73.14 Auditoria

Validar:

- Identificação do operador.
- ID correto.
- Nome histórico.
- Perfil histórico.
- Origem pública.
- Origem automática.
- Origem bootstrap.
- Histórico anterior preservado.
- Ausência de credenciais.
- Proteção append-only preservada.

### 73.15 Concorrência

Validar com conexões independentes:

- Operação concorrente com desativação.
- Operação concorrente com mudança de perfil.
- Login concorrente com redefinição de senha.
- Alteração de senha concorrente.
- Revogação concorrente.
- Preservação das regras do RF015.

### 73.16 Segurança

Validar:

- CSRF.
- XSS.
- SQL Injection.
- Session Fixation.
- Reutilização de sessão revogada.
- Open Redirect.
- Manipulação de perfil.
- Manipulação de actor_user_id.
- Manipulação de identificadores.
- Ausência de tokens nas respostas.
- Ausência de senhas nos logs.
- Cabeçalhos de cache.
- Cookies de produção.
- Restrições de publicação em produção.

### 73.17 Formulário público

Validar:

- Acesso sem autenticação.
- Criação de agendamentos.
- Disponibilidade.
- Idempotência.
- Comprovante.
- QR Code.
- Auditoria pública.
- Ausência de exigência de conta.

### 73.18 Regressão

Executar os testes existentes dos:

- RF001 até RF012.
- RF015.

Preservar todas as regras de negócio.

Atualizar a preparação dos testes administrativos
para utilizar usuários autenticados.

Não desabilitar autenticação genericamente
para fazer os testes anteriores passarem.

Não remover testes de segurança.

---

## 74. Validação manual

### Cenário 01 — Primeiro administrador

1. Executar o bootstrap em ambiente isolado.
2. Acessar /login.
3. Informar as credenciais.
4. Verificar a troca obrigatória de senha.
5. Definir uma nova senha.
6. Autenticar novamente.
7. Verificar o acesso ao Dashboard.

### Cenário 02 — Operador

1. Cadastrar um operador.
2. Realizar login.
3. Alterar a senha inicial.
4. Registrar check-in.
5. Registrar liberação.
6. Consultar o histórico.
7. Confirmar a identificação do operador.
8. Tentar acessar o gerenciamento de usuários.
9. Confirmar a rejeição.

### Cenário 03 — Consulta

1. Cadastrar um usuário Consulta.
2. Realizar login.
3. Consultar os agendamentos.
4. Exportar uma planilha.
5. Confirmar a ausência de ações de escrita.
6. Tentar acessar diretamente uma operação restrita.
7. Confirmar a rejeição pelo backend.

### Cenário 04 — Desativação

1. Autenticar um usuário.
2. Abrir o Dashboard.
3. Utilizar outra sessão administrativa.
4. Desativar o usuário.
5. Confirmar que a sessão anterior
   deixa de funcionar.

### Cenário 05 — Redefinição de senha

1. Autenticar um operador.
2. Redefinir sua senha administrativamente.
3. Confirmar a revogação da sessão.
4. Realizar login com a nova senha.
5. Confirmar a troca obrigatória.

### Cenário 06 — Inatividade

1. Abrir o Dashboard autenticado.
2. Simular expiração por tempo controlado.
3. Confirmar que o polling não prolonga
   a validade por inatividade.
4. Verificar o redirecionamento ao login.

### Cenário 07 — Logout

1. Autenticar um usuário.
2. Acessar páginas administrativas.
3. Realizar logout.
4. Utilizar o botão Voltar do navegador.
5. Tentar acessar diretamente /admin.
6. Confirmar ausência de acesso indevido.

### Cenário 08 — Formulário público

1. Abrir uma janela anônima.
2. Acessar /agendar.
3. Criar uma reserva.
4. Consultar o comprovante.
5. Confirmar que nenhum login foi exigido.

Utilizar dados de teste.

Não utilizar credenciais corporativas reais.

Não alterar o relógio do sistema operacional.

---

## 75. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Verificar também:

- Execução das migrations.
- Integridade das foreign keys.
- Funcionamento do Docker.
- Funcionamento do worker.
- Console do navegador.
- Configuração dos cookies.
- Cabeçalhos HTTP.
- Content Security Policy.
- Cache do Turbo.
- Proteção das rotas.
- Logs de autenticação.

Não desabilitar ferramentas de segurança.

Não declarar testes aprovados
sem efetivamente executá-los.

Não considerar o Brakeman e Bundler Audit
como substitutos de uma revisão completa
de segurança.

---

## 76. Documentação

Registrar:

    docs/requisitos/RF016.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação do banco.
- Documentação operacional.
- Documentação de segurança.
- ADRs, quando necessário.

Documentar:

- Arquitetura de autenticação.
- Estrutura das sessões.
- Geração e armazenamento de credenciais.
- Configuração dos cookies.
- Expiração por inatividade.
- Expiração absoluta.
- Rate limiting.
- Matriz de permissões.
- Proteção das rotas.
- Primeiro acesso.
- Alteração de senha.
- Redefinição administrativa.
- Revogação das sessões.
- Identificação dos operadores.
- Auditoria histórica.
- Integração com o polling.
- Restrições de produção.
- Configurações necessárias para a VPS.
- Riscos e limitações existentes.

Registrar que RF013 e RF014
continuam suspensos.

---

## 77. Critérios de aceite

### Autenticação

- [ ] Tela de login implementada.
- [ ] Autenticação por e-mail e senha.
- [ ] Usuários inativos rejeitados.
- [ ] Mensagens genéricas de erro.
- [ ] Sessões persistidas.
- [ ] Cookies protegidos.
- [ ] Logout funcional.
- [ ] Proteção contra Session Fixation.
- [ ] Expiração por inatividade.
- [ ] Expiração absoluta.

### Autorização

- [ ] Perfil Administrador funcional.
- [ ] Perfil Operador funcional.
- [ ] Perfil Consulta funcional.
- [ ] Matriz aplicada no backend.
- [ ] Rotas protegidas por padrão.
- [ ] Acesso direto indevido rejeitado.
- [ ] Sidebar adaptada ao perfil.
- [ ] Ações incompatíveis ocultadas.
- [ ] Auditoria restrita protegida.

### Gerenciamento de conta

- [ ] Identificação do usuário no Header.
- [ ] Menu do usuário funcional.
- [ ] Página Meu perfil.
- [ ] Alteração da própria senha.
- [ ] Troca obrigatória no primeiro acesso.
- [ ] Troca obrigatória após redefinição.
- [ ] Sessões revogadas após troca de senha.
- [ ] Sessões revogadas após desativação.
- [ ] Sessões revogadas após mudança de perfil.
- [ ] Sessões revogadas após mudança de e-mail.
- [ ] Proteção do último administrador preservada.

### Auditoria

- [ ] Identificação do operador.
- [ ] Nome histórico preservado.
- [ ] Perfil histórico preservado.
- [ ] Origem dos eventos identificada.
- [ ] Check-in associado ao operador.
- [ ] Liberação associada ao operador.
- [ ] Alterações associadas ao operador.
- [ ] Bloqueios associados ao operador.
- [ ] Gerenciamento de usuários auditado.
- [ ] Exportações auditadas.
- [ ] Eventos automáticos identificados.
- [ ] Eventos públicos identificados.
- [ ] Histórico anterior preservado.
- [ ] Proteção append-only preservada.
- [ ] Nenhuma credencial na auditoria.

### Segurança

- [ ] Rate limiting funcional.
- [ ] Proteção contra enumeração avaliada.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Proteção contra Open Redirect.
- [ ] Cookies de produção seguros.
- [ ] Proteção contra elevação de privilégios.
- [ ] Credenciais filtradas nos logs.
- [ ] Sessões revogadas não reutilizáveis.
- [ ] Cache administrativo tratado.
- [ ] Nenhuma credencial padrão criada.
- [ ] Publicação em produção bloqueada
      até homologação.

### Integração

- [ ] Formulário público permanece público.
- [ ] Comprovante preservado.
- [ ] QR Code preservado.
- [ ] Dashboard preservado.
- [ ] Polling autenticado.
- [ ] Polling não renova inatividade.
- [ ] Expiração durante polling tratada.
- [ ] No-show independente das sessões.
- [ ] Exportação Excel preservada.
- [ ] RF013 não implementado.
- [ ] RF014 não implementado.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de autorização executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de segurança executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 78. Fora do escopo

Não implementar neste requisito:

- Cadastro público de usuários.
- Recuperação de senha por e-mail.
- Confirmação de e-mail.
- Remember Me.
- Sessões permanentes.
- OAuth.
- SSO.
- Active Directory.
- Microsoft Entra ID.
- Login com Google.
- Login com Microsoft.
- Autenticação de dois fatores.
- Passkeys.
- Permissões individuais dinâmicas.
- Tabelas complexas de autorização.
- Exclusão definitiva de usuários.
- Upload de documentos.
- Active Storage do RF013.
- Notificações por e-mail.
- Power Automate.
- RF014.
- Redis.
- Microsserviços.
- Implantação na VPS.
- Redesign do painel administrativo.
- Revisão completa de segurança do RF017.

Documentar a ausência de autenticação
de dois fatores como risco residual
a ser avaliado antes da produção.

Implementar exclusivamente autenticação,
autorização, sessões e identificação
dos operadores.

---

## 79. Entrega

Ao concluir o RF016, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.
- Limitações identificadas.

### Interface

- Screenshot da tela de login.
- Screenshot da troca obrigatória de senha.
- Screenshot do Header autenticado.
- Screenshot do menu do usuário.
- Screenshot da página Meu perfil.
- Screenshot da página de acesso não autorizado.
- Screenshot do histórico com operador identificado.

Não incluir senhas, hashes ou tokens.

### Banco de dados

- Tabelas criadas.
- Migrations executadas.
- Campos adicionados.
- Índices.
- Foreign keys.
- Estrutura das sessões.
- Alterações na auditoria.

### Autenticação

- Estratégia adotada.
- Mecanismo de sessão.
- Geração de tokens.
- Proteção dos cookies.
- Expiração.
- Revogação.
- Rate limiting.
- Primeiro acesso.
- Logout.

### Autorização

- Matriz efetivamente implementada.
- Rotas protegidas.
- Controllers protegidos.
- Estratégia de negação por padrão.
- Testes de acesso direto.

### Auditoria

- Identificação de operadores.
- Eventos adicionados.
- Preservação do histórico.
- Proteção de credenciais.
- Identificação de eventos automáticos.

### Segurança

- Proteções implementadas.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Riscos residuais.
- Limitações.
- Pendências obrigatórias do RF017.

### Testes

- Comandos executados.
- Quantidade de testes.
- Quantidade de assertions.
- Falhas.
- Erros.
- Testes ignorados.
- Testes de concorrência.
- Testes de autorização.
- Testes de regressão.
- Resultado do RuboCop.
- Testes não executados e motivos.

### Produção

- Configurações necessárias.
- Variáveis de ambiente.
- Proteções de publicação.
- Configurações futuras do Nginx.
- Configurações futuras de HTTPS.
- Restrições que permanecem ativas.

Não realizar implantação.

### Critérios de aceite

Informar individualmente os critérios
atendidos e pendentes.

Não inventar resultados.

Não declarar conclusão caso existam
critérios obrigatórios pendentes.

### Repositório

Apresentar:

    git status --short

### Pendências

Informar qualquer problema,
risco ou decisão que necessite
de homologação.

---

## 80. Regra de parada

Ao concluir o RF016, PARE.

Não implementar o RF017.

Não realizar implantação na VPS.

Não liberar automaticamente
o painel administrativo em produção.

Não implementar RF013.

Não implementar RF014.

Não integrar Power Automate.

Preservar o layout administrativo aprovado.

Deixar a aplicação operacional
no ambiente de desenvolvimento
para homologação.

Aguardar novas instruções.