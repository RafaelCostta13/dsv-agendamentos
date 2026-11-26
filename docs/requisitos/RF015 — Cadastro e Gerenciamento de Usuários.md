# RF015 — Cadastro e Gerenciamento de Usuários

## 1. Objetivo

Implementar a estrutura de cadastro e gerenciamento
de usuários da aplicação DSV Doca Agenda.

Preparar a aplicação para a futura implementação
de autenticação e autorização.

Implementar:

- Estrutura de usuários no PostgreSQL.
- Cadastro de usuários.
- Edição de usuários.
- Consulta de usuários.
- Pesquisa por nome e e-mail.
- Definição de perfis de acesso.
- Ativação de usuários.
- Desativação de usuários.
- Definição segura de senhas.
- Redefinição administrativa de senhas.
- Proteção de credenciais.
- Criação segura do primeiro administrador.
- Auditoria das alterações cadastrais.

Preservar todas as funcionalidades implementadas
nos RF001 até RF012.

IMPORTANTE:

O RF013 permanece suspenso para definição
dos tipos e quantidades de documentos.

O RF014 permanece suspenso para definição
da integração com Microsoft Power Automate.

Não implementar funcionalidades relacionadas
a esses dois requisitos.

O RF016 será responsável pela implementação
definitiva de autenticação e autorização.

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

Analisar a implementação atual da aplicação.

Identificar:

- Versão do Ruby.
- Versão do Rails.
- Estrutura do PostgreSQL.
- Configuração do Docker.
- Estratégia de auditoria.
- Restrições das rotas administrativas.
- Componentes visuais existentes.
- Dependências de segurança existentes.
- Convenções de nomenclatura.

Não assumir que os exemplos dos requisitos anteriores
correspondem exatamente à implementação existente.

Trabalhar exclusivamente dentro do repositório atual.

Preservar a arquitetura monolítica Ruby on Rails.

---

## 3. Arquitetura

Utilizar:

- Ruby on Rails.
- Active Record.
- PostgreSQL.
- Controllers.
- Models.
- Services, quando necessários.
- Views ERB.
- Helpers.
- CSS.
- Recursos nativos de segurança do Rails.

Não criar uma aplicação frontend independente.

Não introduzir:

- React.
- Vue.
- Angular.
- SPA.
- Node.js.
- Microsserviços.
- Redis.
- Serviços externos de identidade.
- APIs REST desnecessárias.

Não implementar um sistema complexo
de gerenciamento de permissões.

---

## 4. Escopo dos usuários

Os usuários cadastrados serão responsáveis
pelo acesso futuro ao painel administrativo.

Exemplos:

- Administradores.
- Operadores logísticos.
- Supervisores.
- Gestores.
- Colaboradores com acesso de consulta.

As transportadoras que utilizam o formulário
público não precisarão possuir uma conta.

Preservar o acesso público à rota:

    /agendar

Não criar cadastro público de usuários.

Não permitir que participantes do formulário
público criem contas administrativas.

---

## 5. Estrutura do banco de dados

Criar a tabela:

    users

Estrutura proposta:

    id
        bigint
        primary key

    name
        varchar(100)
        not null

    email
        varchar(254)
        not null

    password_digest
        string
        not null

    role
        varchar(30)
        not null

    active
        boolean
        not null
        default true

    must_change_password
        boolean
        not null
        default true

    password_changed_at
        timestamp
        nullable

    deactivated_at
        timestamp
        nullable

    lock_version
        integer
        not null
        default 0

    created_at
        timestamp
        not null

    updated_at
        timestamp
        not null

Adaptar os tipos às convenções utilizadas
no restante da aplicação.

Não armazenar senhas em texto simples.

Não criar uma coluna password.

Não criar uma coluna password_confirmation.

Esses atributos serão utilizados somente
durante a validação em memória.

---

## 6. Índices e constraints

Implementar proteções no PostgreSQL.

### E-mail

Garantir unicidade sem distinção
entre letras maiúsculas e minúsculas.

Exemplo:

    usuario@empresa.com.br

    Usuario@Empresa.com.br

Os valores acima deverão ser considerados
o mesmo endereço.

Utilizar normalização consistente no Rails
e um índice único funcional sobre lower(email)
ou mecanismo equivalente no PostgreSQL.

Não depender exclusivamente
da validação de unicidade do Active Record.

### Perfil

Permitir exclusivamente:

    admin
    operator
    viewer

Adicionar CHECK constraint correspondente.

### Estado

Garantir que active não aceite valores nulos.

Manter consistência entre:

    active
    deactivated_at

Usuários ativos não deverão possuir
uma data de desativação atual.

Usuários inativos deverão possuir
a data efetiva da desativação.

### Concorrência

Garantir:

    lock_version >= 0

Adicionar as constraints necessárias.

Não modificar migrations anteriormente aplicadas.

---

## 7. Model User

Criar o model:

    User

Responsabilidades:

- Normalização dos dados.
- Validação do nome.
- Validação do e-mail.
- Validação do perfil.
- Validação do estado.
- Validação de senha.
- Geração segura do password_digest.
- Controle de optimistic locking.

Utilizar os recursos nativos
do Active Record.

Não implementar diretamente
algoritmos criptográficos próprios.

Não criar regras de autenticação
complexas neste requisito.

---

## 8. Perfis de acesso

Implementar três perfis fixos.

### Administrador

Valor técnico:

    admin

Descrição:

    Acesso completo ao sistema e gerenciamento
    das configurações e dos usuários.

### Operador

Valor técnico:

    operator

Descrição:

    Gerenciamento operacional dos agendamentos,
    check-ins, liberações, cancelamentos,
    reagendamentos e bloqueios.

### Consulta

Valor técnico:

    viewer

Descrição:

    Consulta de informações operacionais,
    histórico e exportação de agendamentos.

Utilizar valores técnicos em inglês
e apresentar os nomes em português.

Não criar tabelas adicionais para:

- Roles.
- Permissions.
- UserRoles.
- RolePermissions.

Não implementar múltiplos perfis
para um mesmo usuário.

Cada usuário deverá possuir
um único perfil neste momento.

---

## 9. Matriz de permissões futura

Documentar a seguinte proposta:

Funcionalidade               Admin  Operator  Viewer

Dashboard                     Sim     Sim      Sim
Consultar agendamentos        Sim     Sim      Sim
Visualizar comprovantes       Sim     Sim      Sim
Check-in                      Sim     Sim      Não
Liberação                     Sim     Sim      Não
Cancelar agendamento          Sim     Sim      Não
Alterar agendamento           Sim     Sim      Não
Reagendar                     Sim     Sim      Não
Bloquear posições             Sim     Sim      Não
Desbloquear posições          Sim     Sim      Não
Consultar histórico           Sim     Sim      Sim
Exportar Excel                Sim     Sim      Sim
Gerenciar usuários            Sim     Não      Não
Gerenciar configurações       Sim     Não      Não

A aplicação efetiva dessas permissões
será responsabilidade do RF016.

Não declarar que as permissões
já estão sendo aplicadas.

Não implementar permissões somente
através da ocultação de botões.

Não criar permissões relacionadas
ao RF013 ou RF014 neste momento.

---

## 10. Nome completo

Utilizar:

    users.name

Regras:

- Campo obrigatório.
- Mínimo de 2 caracteres úteis.
- Máximo de 100 caracteres.
- Remover espaços nas extremidades.
- Aceitar caracteres acentuados.
- Aceitar nomes compostos.
- Rejeitar caracteres de controle inadequados.

Não restringir nomes exclusivamente
a caracteres ASCII.

Não utilizar o nome completo
como identificador de autenticação.

---

## 11. E-mail

Utilizar:

    users.email

Regras:

- Campo obrigatório.
- Máximo de 254 caracteres.
- Normalizar espaços nas extremidades.
- Normalizar para letras minúsculas.
- Validar formato.
- Garantir unicidade no PostgreSQL.

Exemplo:

    Usuario@Empresa.com.br

Resultado armazenado:

    usuario@empresa.com.br

O e-mail será utilizado futuramente
como identificador de login.

Não utilizar serviços externos
para verificar a existência da caixa postal.

Não enviar e-mails de confirmação.

Não implementar confirmação por e-mail.

Não restringir o cadastro a um domínio
corporativo sem definição explícita.

---

## 12. Armazenamento seguro de senhas

Utilizar preferencialmente:

    has_secure_password

Em conjunto com a gem:

    bcrypt

Verificar a versão instalada
e a compatibilidade com o Rails.

Caso bcrypt ainda não esteja disponível:

- Avaliar a dependência.
- Verificar vulnerabilidades conhecidas.
- Verificar compatibilidade.
- Adicionar somente o necessário.
- Atualizar Gemfile.lock.

Não utilizar:

- MD5.
- SHA1 isoladamente.
- SHA256 isoladamente como hash de senha.
- Base64.
- Criptografia reversível de senhas.
- Algoritmos criptográficos próprios.

O PostgreSQL deverá armazenar
somente o password_digest.

Não permitir recuperação da senha original.

Avaliar e documentar o custo de processamento
do bcrypt utilizado.

---

## 13. Política de senhas

Definir inicialmente:

    Comprimento mínimo: 12 caracteres

Respeitar o limite técnico de bytes
da biblioteca de hashing utilizada.

Caso bcrypt seja utilizado:

    Limite máximo: 72 bytes

Não truncar senhas silenciosamente.

Validar corretamente senhas Unicode,
considerando a diferença entre
quantidade de caracteres e bytes.

Permitir:

- Letras maiúsculas.
- Letras minúsculas.
- Números.
- Símbolos.
- Espaços, quando tecnicamente apropriado.

Não exigir regras artificiais de composição
sem necessidade demonstrada.

Permitir frases-senha.

Não remover espaços das senhas.

Não modificar automaticamente a senha
fornecida pelo usuário.

Exigir confirmação da senha
durante cadastro e redefinição.

Não aplicar expiração periódica obrigatória
de senhas neste requisito.

---

## 14. Senha inicial

Ao cadastrar um usuário, permitir
definir uma senha inicial.

A conta deverá ser criada com:

    must_change_password = true

O RF016 deverá utilizar essa informação
para exigir a alteração da senha
no primeiro acesso.

Não implementar o fluxo de primeiro
acesso neste requisito.

Não enviar a senha por e-mail.

Não apresentar a senha inicial
novamente após sua persistência.

Não armazenar senhas temporárias
em campos adicionais.

Documentar que a comunicação da senha
inicial deverá ocorrer por meio seguro,
fora da aplicação nesta etapa.

---

## 15. Primeiro administrador

Criar um mecanismo seguro para cadastrar
o primeiro administrador do sistema.

Utilizar preferencialmente uma tarefa
interna do Rails.

Exemplo conceitual:

    bin/rails users:bootstrap_admin

A nomenclatura poderá ser adaptada
às convenções existentes.

Executar a tarefa conforme o ambiente Docker.

A tarefa deverá solicitar:

- Nome.
- E-mail.
- Senha.
- Confirmação da senha.

A entrada da senha deverá ocorrer
sem eco no terminal.

Não receber a senha diretamente
como argumento do comando.

Não registrar a senha no histórico do shell.

Não armazenar senhas em arquivos temporários.

Não utilizar credenciais fixas.

Não criar usuários automaticamente
com senhas previsíveis.

Exemplos proibidos:

    admin@example.com / admin123

    administrador / 123456

Não armazenar credenciais reais
no arquivo db/seeds.rb.

---

## 16. Proteção da criação do primeiro administrador

A tarefa de bootstrap deverá ser utilizada
somente para inicialização da aplicação.

Caso já exista um administrador,
não criar outro automaticamente.

Não alterar a senha de um administrador
existente durante uma nova execução.

Não reativar automaticamente contas.

Não sobrescrever contas existentes.

A tarefa deverá ser segura contra
execuções simultâneas.

Utilizar transações e travamento apropriado
para impedir múltiplas inicializações concorrentes.

Apresentar mensagens claras.

Exemplo:

    Administrador inicial criado com sucesso.

Ou:

    A inicialização já foi realizada.

Registrar a criação na auditoria,
sem incluir credenciais.

Documentar o procedimento de bootstrap.

---

## 17. Menu administrativo

Adicionar à Sidebar existente:

    Usuários

Estrutura esperada:

    Dashboard
    Agendamentos
    Bloqueios
    Histórico
    Usuários

Preservar os menus existentes.

Não adicionar um menu Configurações
exclusivamente para o RF014.

O RF014 permanece suspenso.

Preservar:

- Header.
- Logo DSV.
- Sidebar.
- Paleta de cores.
- Tipografia.
- Espaçamentos.
- Responsividade.
- Identificação do menu ativo.

---

## 18. Página de gerenciamento

Criar a página:

    Usuários

Descrição:

    Gerencie as contas e os perfis
    de acesso ao sistema.

Disponibilizar:

- Indicadores cadastrais.
- Botão Novo usuário.
- Campo de pesquisa.
- Filtro por perfil.
- Filtro por status.
- Lista de usuários.
- Paginação.
- Ações de edição.
- Ações de ativação e desativação.

Utilizar o layout administrativo existente.

Não reconstruir o painel.

---

## 19. Indicadores de usuários

Apresentar três indicadores
na página de gerenciamento:

    Total de usuários

    Usuários ativos

    Usuários inativos

Os indicadores deverão considerar
o conjunto geral de usuários cadastrados.

Não alterar os indicadores
do Dashboard operacional.

Não adicionar polling para esses indicadores.

Atualizar os valores após operações
cadastrais bem-sucedidas.

Utilizar consultas agrupadas,
quando apropriado.

---

## 20. Lista de usuários

Apresentar as seguintes colunas:

- Nome completo.
- E-mail.
- Perfil.
- Status.
- Data de cadastro.
- Ações.

Exemplo:

    Carlos Almeida
    carlos@example.com
    Administrador
    Ativo

    Mariana Santos
    mariana@example.com
    Operador
    Ativo

    Lucas Oliveira
    lucas@example.com
    Consulta
    Inativo

Nunca apresentar:

- Password digest.
- Senha.
- Confirmação de senha.
- Informações criptográficas.
- Credenciais.

Não incluir uma coluna de último acesso,
pois o login ainda não foi implementado.

---

## 21. Pesquisa de usuários

Permitir pesquisar por:

- Nome completo.
- E-mail.

A pesquisa deverá aceitar
correspondências parciais.

Não diferenciar letras maiúsculas
e minúsculas na pesquisa.

Utilizar consultas Active Record
parametrizadas.

Caso seja utilizado LIKE ou ILIKE,
tratar corretamente os caracteres
especiais de busca.

Não concatenar valores não confiáveis
diretamente em SQL.

Não pesquisar campos de credenciais.

Limitar o tamanho do termo pesquisado.

---

## 22. Filtros

Disponibilizar filtro por perfil:

    Todos
    Administrador
    Operador
    Consulta

Disponibilizar filtro por status:

    Todos
    Ativos
    Inativos

Permitir combinar os filtros.

Utilizar requisições GET.

Preservar os filtros durante a paginação.

Disponibilizar:

    Limpar filtros

Validar todos os parâmetros no backend.

---

## 23. Paginação e ordenação

Reutilizar a estratégia de paginação
implementada nos requisitos anteriores.

Utilizar inicialmente:

    25 usuários por página

Ordenar por:

    name ASC
    id ASC

Garantir ordenação determinística.

Não carregar todos os usuários
para realizar filtragem no navegador.

Não criar uma biblioteca adicional
de paginação sem necessidade.

---

## 24. Cadastro de usuários

Disponibilizar o botão:

    Novo usuário

O formulário deverá conter:

- Nome completo.
- E-mail.
- Perfil de acesso.
- Senha inicial.
- Confirmação da senha.
- Status ativo ou inativo.

Apresentar uma descrição
do perfil selecionado.

Utilizar os componentes visuais existentes.

Utilizar labels acessíveis.

Apresentar mensagens de validação
em português.

Não criar a conta caso exista
qualquer erro de validação.

---

## 25. Persistência do cadastro

Ao cadastrar um usuário válido:

- Normalizar os dados.
- Validar o e-mail.
- Validar o perfil.
- Validar a senha.
- Gerar password_digest.
- Definir must_change_password.
- Definir o estado inicial.
- Persistir o registro.
- Criar o evento de auditoria.

A criação do usuário e sua auditoria
deverão ocorrer na mesma transação.

Caso a auditoria falhe:

- Reverter a criação.
- Não apresentar mensagem de sucesso.
- Registrar a falha tecnicamente.

Não enviar notificações.

Não criar sessões automaticamente.

Não realizar login automático.

---

## 26. Edição de usuários

Permitir editar:

- Nome completo.
- E-mail.
- Perfil.

Não apresentar campos de senha
no formulário comum de edição.

A alteração de senha deverá possuir
um fluxo específico.

Preservar:

- ID interno.
- Data de criação.
- Histórico.
- Eventos de auditoria.

Atualizar updated_at.

Utilizar optimistic locking.

Não aceitar parâmetros internos
não previstos no formulário.

---

## 27. Alteração de perfil

Permitir alterar o perfil de um usuário.

Exemplos:

    Operador -> Administrador

    Administrador -> Consulta

    Consulta -> Operador

Apresentar uma confirmação
quando houver mudança de perfil.

Exibir:

- Nome do usuário.
- Perfil atual.
- Novo perfil.

Não permitir a alteração caso ela
elimine o último administrador ativo.

Registrar os valores anteriores
e posteriores na auditoria.

A aplicação das permissões correspondentes
acontecerá no RF016.

---

## 28. Ativação de usuários

Permitir reativar uma conta inativa.

Ao confirmar:

    active = true

    deactivated_at = null

Preservar:

- ID.
- Nome.
- E-mail.
- Perfil.
- Password digest.
- Histórico.

Registrar a reativação na auditoria.

Não criar uma nova conta.

Não gerar automaticamente
uma nova senha.

Não criar uma sessão autenticada.

---

## 29. Desativação de usuários

Permitir desativar contas existentes.

Ao confirmar:

    active = false

    deactivated_at = horário do servidor

Exigir confirmação.

Exigir motivo obrigatório.

Validação do motivo:

- Mínimo de 3 caracteres úteis.
- Máximo de 500 caracteres.
- Remover espaços nas extremidades.

Exemplo:

    Colaborador não pertence mais à operação.

Preservar todos os dados cadastrais.

Preservar a auditoria.

Não excluir o usuário.

A desativação deverá impedir
futuros acessos quando o RF016
estiver implementado.

Não implementar encerramento de sessões
neste requisito, pois elas ainda não existem.

---

## 30. Proteção do último administrador

Garantir que, após a inicialização
da aplicação, exista pelo menos
um administrador ativo.

Não permitir:

- Desativar o último administrador ativo.
- Alterar o perfil do último administrador
  ativo para Operador.
- Alterar o perfil do último administrador
  ativo para Consulta.

Exemplo:

    Administradores ativos: 1

    Operação solicitada:
        Desativar administrador.

Resultado:

    Operação rejeitada.

Mensagem:

    O sistema precisa possuir pelo menos
    um administrador ativo.

Essa regra deverá ser validada
no backend e dentro de uma transação.

Não depender exclusivamente
da interface visual.

---

## 31. Concorrência na proteção de administradores

Considerar:

    Administrador A: ativo
    Administrador B: ativo

Duas solicitações simultâneas tentam
desativar os dois administradores.

Resultado esperado:

    Somente uma das operações poderá
    ser confirmada.

Deverá permanecer pelo menos
um administrador ativo.

Implementar travamento compartilhado
e determinístico para operações
que afetem a quantidade de administradores.

Avaliar mecanismos transacionais
compatíveis com o PostgreSQL.

Exemplo:

    Advisory transaction lock específico
    para gerenciamento de administradores.

Reutilizar as convenções de concorrência
já estabelecidas no projeto.

Não utilizar mutex Ruby como única proteção.

Documentar os limites da garantia
em alterações realizadas diretamente por SQL.

---

## 32. Exclusão de usuários

Não implementar exclusão definitiva
de usuários neste requisito.

A alternativa operacional será:

    Desativar usuário

Motivos:

- Preservação do histórico.
- Preservação da auditoria.
- Rastreabilidade futura.
- Integridade de relacionamentos posteriores.

Não criar botão Excluir usuário.

Não criar rota DELETE para usuários.

Não remover usuários inativos
automaticamente.

Não permitir reutilizar o mesmo e-mail
para criar uma segunda conta.

Quando necessário, reativar
a conta existente.

Uma futura política de eliminação
ou anonimização de dados deverá ser
tratada separadamente.

---

## 33. Redefinição administrativa de senha

Na página de detalhes ou edição,
disponibilizar uma ação específica:

    Redefinir senha

Apresentar:

- Identificação do usuário.
- Nova senha.
- Confirmação da nova senha.
- Motivo da redefinição.

Exigir confirmação.

Utilizar a política de senha existente.

Não exibir a senha anterior.

Não exibir o password_digest.

Não solicitar a senha anterior do usuário,
pois se trata de uma redefinição administrativa.

O acesso a essa funcionalidade deverá ser
restrito a administradores no RF016.

Até lá, manter toda a interface de usuários
indisponível em produção.

---

## 34. Persistência da redefinição

Ao redefinir uma senha:

- Validar a nova senha.
- Validar a confirmação.
- Validar o motivo.
- Gerar novo password_digest.
- Atualizar password_changed_at.
- Definir must_change_password = true.
- Atualizar lock_version.
- Registrar auditoria.

Não registrar a senha antiga.

Não registrar a senha nova.

Não registrar os respectivos hashes.

A alteração e a auditoria deverão
ocorrer na mesma transação.

Não enviar a senha por e-mail.

Não implementar recuperação de senha
através de links externos.

Documentar que a invalidação das sessões
existentes deverá ser implementada
no RF016.

---

## 35. Auditoria de usuários

Reutilizar a tabela:

    audit_events

Adicionar suporte à entidade:

    User

Verificar se existem constraints
ou validações que limitem os tipos
de entidade atualmente aceitos.

Caso necessário, criar uma migration
para incluir User.

Preservar os tipos existentes:

    Booking

    SlotBlock

Não modificar migrations anteriores.

Não criar uma tabela separada
de auditoria de usuários.

Preservar a proteção append-only
implementada no RF011.

---

## 36. Tipos de eventos de usuários

Adicionar os seguintes eventos conceituais:

    user_created

        Usuário cadastrado.

    user_updated

        Dados cadastrais alterados.

    user_role_changed

        Perfil de acesso alterado.

    user_activated

        Usuário ativado.

    user_deactivated

        Usuário desativado.

    user_password_reset

        Senha redefinida.

Adaptar a nomenclatura às convenções
efetivamente utilizadas no projeto.

Não gerar eventos de login ou logout
neste requisito.

Não criar eventos de autenticação fictícios.

Evitar auditorias duplicadas
para a mesma alteração.

---

## 37. Conteúdo da auditoria

Registrar somente informações
necessárias à rastreabilidade.

Exemplo:

    entity_type: User

    entity_id: ID do usuário afetado

    action: user_role_changed

    previous_values:
        role: operator

    new_values:
        role: admin

    reason:
        quando aplicável

    created_at:
        horário do servidor

Para criação e edição, utilizar
uma lista explícita dos campos
cadastrais auditáveis.

Não serializar automaticamente
todos os atributos do User.

Não utilizar o resultado integral
de User.attributes na auditoria.

---

## 38. Proteção de credenciais na auditoria

Nunca armazenar em audit_events:

- password.
- password_confirmation.
- password_digest.
- Senhas temporárias.
- Tokens.
- Chaves de sessão.
- Credenciais.
- Informações criptográficas.

Exemplo de redefinição segura:

    action: user_password_reset

    previous_values:
        must_change_password: false

    new_values:
        must_change_password: true

    reason:
        Solicitação administrativa.

O evento deverá indicar que houve
uma redefinição, sem revelar informações
sobre a senha utilizada.

---

## 39. Identificação de operadores

A aplicação ainda não possui
autenticação implementada.

Portanto, não será possível identificar
com segurança qual operador realizou
cada alteração administrativa.

Não criar um usuário fictício
para representar o responsável.

Não aceitar actor_id enviado
diretamente pelo navegador.

Não atribuir os eventos históricos
existentes ao primeiro administrador.

Não reescrever auditorias anteriores.

Documentar essa limitação.

A identificação dos responsáveis
pelas ações deverá ser implementada
no RF016.

---

## 40. Integração com o histórico

Atualizar a interface de auditoria
implementada no RF011.

Adicionar a entidade:

    Usuários

Adicionar os tipos de eventos
relacionados ao gerenciamento de contas.

Permitir consultar:

- Cadastro.
- Alteração cadastral.
- Alteração de perfil.
- Ativação.
- Desativação.
- Redefinição de senha.

Não apresentar dados criptográficos.

Não permitir alterações nos eventos.

Preservar a auditoria histórica.

Documentar que o RF016 deverá definir
as restrições de consulta dos eventos
de gerenciamento de usuários.

---

## 41. Controle de concorrência

Utilizar o atributo:

    lock_version

Considerar:

- Dois operadores editando a mesma conta.
- Alteração simultânea do mesmo e-mail.
- Desativação concorrente.
- Alteração concorrente de perfil.
- Redefinição concorrente de senha.
- Criação concorrente com e-mails iguais.

Revalidar o estado atual do registro
nas operações críticas.

Tratar conflitos de optimistic locking.

Não sobrescrever silenciosamente
alterações realizadas por outra solicitação.

Apresentar:

    O usuário foi atualizado por outra operação.
    Consulte os dados atualizados antes de continuar.

Preservar a integridade da auditoria.

---

## 42. Rotas administrativas

Criar as rotas necessárias dentro
do namespace administrativo.

Estrutura sugerida:

    GET /admin/users

    GET /admin/users/new

    POST /admin/users

    GET /admin/users/:id

    GET /admin/users/:id/edit

    PATCH /admin/users/:id

    PATCH /admin/users/:id/activate

    PATCH /admin/users/:id/deactivate

    GET /admin/users/:id/password_reset

    PATCH /admin/users/:id/password_reset

Criar rotas GET adicionais somente
quando necessárias para confirmação
de operações.

Adaptar a nomenclatura às convenções
existentes.

Não criar rotas públicas.

Não executar alterações através de GET.

Não criar rotas de exclusão definitiva.

---

## 43. Restrições de ambiente

IMPORTANTE:

A autenticação ainda não está implementada.

Todas as rotas administrativas,
incluindo as novas rotas de usuários,
deverão continuar disponíveis exclusivamente
nos ambientes:

    development

    test

Não permitir acesso ao gerenciamento
de usuários em produção.

Não criar exceções para:

- Cadastro.
- Edição.
- Ativação.
- Desativação.
- Redefinição de senha.
- Consulta de usuários.

Não disponibilizar um login provisório.

Não utilizar Basic Auth como substituto
temporário da autenticação definitiva.

Não criar uma credencial compartilhada.

Manter as proteções existentes
nas rotas administrativas.

---

## 44. Strong Parameters

Utilizar listas explícitas
de atributos permitidos.

Exemplo para cadastro:

    name
    email
    role
    password
    password_confirmation
    active

Exemplo para edição:

    name
    email
    role
    lock_version

Exemplo para redefinição:

    password
    password_confirmation
    reason
    lock_version

Não permitir atribuição direta de:

    password_digest

    must_change_password

    password_changed_at

    deactivated_at

    created_at

    updated_at

    id

Os atributos internos deverão ser
controlados pelo backend.

Validar active e role explicitamente.

Não confiar nos valores disponíveis
nos campos HTML.

---

## 45. Proteção dos logs

Verificar a configuração:

    config.filter_parameters

Garantir que sejam filtrados:

- password.
- password_confirmation.
- password_digest.
- Tokens.
- Credenciais.
- Dados de autenticação futuros.

Verificar também a filtragem
de parâmetros aninhados.

Não registrar objetos completos
do usuário nos logs.

Não registrar credenciais
em mensagens de erro.

Não registrar parâmetros sensíveis
durante falhas de validação.

Verificar a filtragem efetivamente,
através de testes.

---

## 46. Proteção das respostas HTTP

Não retornar o password_digest
em nenhuma resposta HTTP.

Não incluir informações de senha em:

- HTML.
- JSON.
- Data attributes.
- Campos hidden.
- Comentários HTML.
- Cookies.
- Cabeçalhos HTTP.

Configurar:

    Cache-Control: no-store

nas páginas administrativas que
contenham informações cadastrais
ou formulários de senha.

Não armazenar dados de usuários
no localStorage ou sessionStorage.

Não repopular campos de senha
após erros de validação.

---

## 47. Segurança dos formulários

Preservar:

- Proteção CSRF.
- Content Security Policy.
- Escaping padrão do ERB.
- Strong Parameters.
- Consultas parametrizadas.
- Validação no backend.

Utilizar campos do tipo:

    password

para senhas.

Utilizar atributos autocomplete
apropriados para novas senhas.

Permitir utilização de gerenciadores
de senhas.

Não impedir a colagem de senhas.

Não utilizar raw ou html_safe
para apresentar dados cadastrais.

Não introduzir scripts inseguros.

---

## 48. Tratamento de erros

Apresentar mensagens claras
em português.

### Nome inválido

    Informe um nome válido.

### E-mail inválido

    Informe um endereço de e-mail válido.

### E-mail duplicado

    Este endereço de e-mail já está cadastrado.

### Perfil inválido

    Selecione um perfil de acesso válido.

### Senha curta

    A senha deve possuir pelo menos
    12 caracteres.

### Senha acima do limite técnico

    A senha ultrapassa o tamanho permitido.

### Senhas diferentes

    As senhas informadas não são iguais.

### Último administrador

    O sistema precisa possuir pelo menos
    um administrador ativo.

### Cadastro concluído

    Usuário cadastrado com sucesso.

### Edição concluída

    Usuário atualizado com sucesso.

### Desativação concluída

    Usuário desativado com sucesso.

### Redefinição concluída

    Senha redefinida com sucesso.

Não apresentar:

- Stack traces.
- Mensagens SQL.
- Password digest.
- Caminhos internos.
- Informações de infraestrutura.

---

## 49. Organização do backend

Manter os controllers pequenos.

Estrutura sugerida:

    app/
    ├── models/
    │   └── user.rb
    │
    ├── controllers/
    │   └── admin/
    │       └── users_controller.rb
    │
    ├── services/
    │   └── users/
    │       ├── create.rb
    │       ├── update.rb
    │       ├── activate.rb
    │       ├── deactivate.rb
    │       └── reset_password.rb
    │
    └── views/
        └── admin/
            └── users/
                ├── index.html.erb
                ├── new.html.erb
                ├── edit.html.erb
                ├── show.html.erb
                └── _form.html.erb

A estrutura é conceitual.

Adaptar às convenções existentes.

Não criar services separados
quando isso não agregar organização
ou proteção transacional.

Não criar abstrações genéricas
desnecessárias.

Não implementar regras de negócio
diretamente nas views.

---

## 50. JavaScript

Utilizar o mínimo necessário.

JavaScript poderá ser utilizado para:

- Alternar visibilidade da senha.
- Apresentar a descrição do perfil.
- Melhorar a experiência dos formulários.
- Exibir confirmações.

Não utilizar JavaScript para:

- Gerar password_digest.
- Persistir senhas.
- Definir permissões definitivas.
- Validar exclusivamente o perfil.
- Executar regras de segurança.
- Consultar diretamente o banco.
- Proteger rotas administrativas.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Handlers inline.
- Scripts de CDNs.

Preservar a Content Security Policy.

---

## 51. Responsividade e acessibilidade

Preservar a identidade visual
do painel administrativo.

Garantir:

- Formulários organizados.
- Labels associados aos campos.
- Mensagens de erro próximas aos campos.
- Navegação por teclado.
- Estados de foco visíveis.
- Contraste adequado.
- Botões com áreas de interação adequadas.
- Tabela legível.
- Paginação funcional.

Apresentar estados ativo e inativo
através de texto e cor.

Não depender exclusivamente da cor.

Em dispositivos menores, permitir
scroll horizontal somente na tabela,
quando necessário.

Não provocar scroll horizontal
em toda a página.

---

## 52. Infraestrutura

Preservar o Docker Compose existente.

Não adicionar novos containers
exclusivamente para cadastro de usuários.

Preservar:

- Rails.
- Puma.
- PostgreSQL.
- Worker existente do RF008.
- Volumes.
- Configurações de rede.
- Configurações de segurança.

Não adicionar Redis.

Não adicionar servidores de identidade.

Não alterar as portas existentes.

Não modificar Nginx neste requisito.

Executar as migrations necessárias
sem excluir dados existentes.

Não executar comandos destrutivos
sobre volumes ou bancos de dados.

---

## 53. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 53.1 Model User

Validar:

- Criação de usuário válido.
- Nome obrigatório.
- E-mail obrigatório.
- E-mail inválido.
- Normalização de e-mail.
- Nome acima do limite.
- Perfil inválido.
- Estado inválido.
- Password digest obrigatório.
- Optimistic locking.

### 53.2 Unicidade

Validar:

- E-mail duplicado.
- E-mail duplicado com letras maiúsculas.
- E-mail duplicado após normalização.
- Criação concorrente com o mesmo e-mail.
- Proteção efetiva no PostgreSQL.

### 53.3 Senhas

Validar:

- Senha válida.
- Senha abaixo de 12 caracteres.
- Senha acima do limite técnico.
- Senhas diferentes.
- Senhas com Unicode.
- Senhas com espaços.
- Senhas com símbolos.
- Ausência de truncamento silencioso.
- Geração de password_digest.
- Ausência de senha em texto simples.
- Verificação segura da senha pelo mecanismo
  nativo utilizado.

Testar o mecanismo criptográfico
sem implementar uma rota de login.

### 53.4 Cadastro

Validar:

- Criação de administrador.
- Criação de operador.
- Criação de usuário de consulta.
- Criação de usuário ativo.
- Criação de usuário inativo.
- Flag must_change_password.
- Criação da auditoria.
- Rollback quando a auditoria falhar.

### 53.5 Edição

Validar:

- Alteração do nome.
- Alteração do e-mail.
- Alteração de perfil.
- Preservação do ID.
- Preservação da senha.
- Atualização de lock_version.
- Conflitos de edição.
- Auditoria dos valores modificados.

### 53.6 Ativação e desativação

Validar:

- Desativação de usuário.
- Motivo obrigatório.
- Data de desativação.
- Reativação de usuário.
- Limpeza de deactivated_at.
- Preservação dos dados.
- Preservação do password_digest.
- Preservação da auditoria.

Não criar auditorias de alteração
para operações que não alterem
efetivamente o estado.

### 53.7 Último administrador

Validar:

- Desativação de administrador permitida
  quando existir outro administrador ativo.
- Desativação do último administrador rejeitada.
- Alteração do perfil do último administrador
  rejeitada.
- Existência de pelo menos um administrador
  ativo após operações válidas.
- Concorrência entre duas desativações.
- Concorrência entre duas alterações de perfil.
- Concorrência entre desativação e mudança
  de perfil.

Utilizar conexões independentes
com PostgreSQL.

Não simular concorrência somente
através de operações sequenciais.

### 53.8 Redefinição de senha

Validar:

- Redefinição válida.
- Rejeição de senha inválida.
- Rejeição de confirmação incorreta.
- Motivo obrigatório.
- Atualização do password_digest.
- Atualização de password_changed_at.
- Flag must_change_password ativada.
- Ausência da senha antiga e nova na auditoria.
- Rollback em caso de falha da auditoria.

### 53.9 Bootstrap

Validar:

- Criação do primeiro administrador.
- Rejeição de credenciais inválidas.
- Entrada segura da senha.
- Execução repetida.
- Ausência de sobrescrita.
- Ausência de credenciais fixas.
- Concorrência entre inicializações.
- Auditoria de criação.

### 53.10 Listagem

Validar:

- Exibição dos usuários.
- Pesquisa por nome.
- Pesquisa por e-mail.
- Filtro por perfil.
- Filtro por status.
- Combinação de filtros.
- Paginação.
- Ordenação.
- Indicadores cadastrais.
- Estado vazio.

### 53.11 Segurança

Validar:

- Proteção CSRF.
- Proteção contra XSS.
- Proteção contra SQL Injection.
- Manipulação de perfil.
- Manipulação de parâmetros internos.
- Tentativa de atribuir password_digest.
- Ausência de senhas nas respostas HTTP.
- Ausência de password_digest no HTML.
- Filtragem de senhas nos logs.
- Ausência de rotas públicas de cadastro.
- Ausência de rotas de exclusão.
- Rotas administrativas indisponíveis
  em produção.
- Preservação da Content Security Policy.

### 53.12 Auditoria

Validar:

- Evento de cadastro.
- Evento de edição.
- Evento de mudança de perfil.
- Evento de ativação.
- Evento de desativação.
- Evento de redefinição de senha.
- Preservação de valores anteriores.
- Ausência de credenciais.
- Proteção append-only preservada.
- Ausência de eventos duplicados.
- Rollback em caso de falha.

### 53.13 Regressão

Executar todos os testes existentes
dos RF001 até RF012.

Preservar:

- Formulário público.
- Disponibilidade.
- Criação de reservas.
- Idempotência.
- Dashboard.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- No-show.
- Polling.
- Comprovante.
- QR Code.
- Histórico.
- Exportação Excel.

Não implementar testes de funcionalidades
do RF013 e RF014 que ainda não existem.

Não remover ou enfraquecer testes anteriores.

---

## 54. Validação manual

### Cenário 01 — Primeiro administrador

1. Inicializar o ambiente de desenvolvimento.
2. Executar a tarefa de bootstrap.
3. Informar nome e e-mail.
4. Informar uma senha segura.
5. Confirmar a senha.
6. Verificar a criação da conta.
7. Verificar a auditoria.
8. Executar novamente a tarefa.
9. Confirmar que nenhuma conta foi duplicada.

### Cenário 02 — Cadastro

1. Acessar o menu Usuários.
2. Selecionar Novo usuário.
3. Informar nome e e-mail.
4. Selecionar o perfil Operador.
5. Informar senha e confirmação.
6. Confirmar o cadastro.
7. Verificar a listagem.
8. Verificar os indicadores.
9. Verificar a auditoria.

### Cenário 03 — Alteração de perfil

1. Selecionar um operador.
2. Alterar o perfil para Administrador.
3. Confirmar a operação.
4. Verificar o novo perfil.
5. Verificar o histórico da alteração.

### Cenário 04 — Desativação

1. Selecionar um usuário ativo.
2. Solicitar a desativação.
3. Informar o motivo.
4. Confirmar a operação.
5. Verificar o status Inativo.
6. Consultar a auditoria.
7. Reativar a conta.
8. Verificar o status Ativo.

### Cenário 05 — Último administrador

1. Preparar um ambiente isolado
   com apenas um administrador ativo.
2. Tentar desativar essa conta.
3. Confirmar que a operação é rejeitada.
4. Tentar alterar seu perfil para Operador.
5. Confirmar que a operação é rejeitada.
6. Verificar que a conta permanece ativa.

### Cenário 06 — Redefinição de senha

1. Selecionar um usuário.
2. Acessar Redefinir senha.
3. Informar uma nova senha.
4. Confirmar a nova senha.
5. Informar o motivo.
6. Confirmar a operação.
7. Verificar a auditoria.
8. Confirmar a ausência de credenciais
   nos logs e eventos.

### Cenário 07 — Segurança

1. Tentar acessar rotas públicas inexistentes
   de cadastro de usuários.
2. Tentar manipular atributos internos.
3. Verificar as restrições de produção.
4. Verificar os formulários.
5. Verificar os cabeçalhos HTTP.
6. Verificar a filtragem de parâmetros.

Utilizar dados de teste.

Não utilizar senhas corporativas reais.

Não realizar testes destrutivos
sobre dados existentes.

---

## 55. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Verificar também:

- Execução das migrations.
- Constraints do PostgreSQL.
- Índices únicos.
- Dependência bcrypt, quando utilizada.
- Configuração de filtragem de parâmetros.
- Console do navegador.
- Carregamento dos assets.
- Responsividade.
- Ausência de violações inesperadas de CSP.

Não desabilitar ferramentas de segurança
para obter resultados positivos.

Não declarar testes aprovados
sem efetivamente executá-los.

---

## 56. Documentação

Registrar este requisito em:

    docs/requisitos/RF015.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação do banco de dados.
- Documentação operacional.

Documentar:

- Estrutura da tabela users.
- Campos e tipos de dados.
- Índices.
- Constraints.
- Perfis fixos.
- Matriz de permissões proposta.
- Política de senhas.
- Estratégia de hashing.
- Cadastro.
- Edição.
- Ativação.
- Desativação.
- Redefinição administrativa de senha.
- Bootstrap do primeiro administrador.
- Proteção do último administrador.
- Estratégia de concorrência.
- Auditoria.
- Proteção de credenciais.
- Restrições das rotas administrativas.
- Funcionalidades pendentes do RF016.

Registrar expressamente:

    RF013: suspenso.

    RF014: suspenso.

Não implementar funcionalidades
desses requisitos.

Criar ADR somente quando houver
uma decisão arquitetural relevante.

---

## 57. Critérios de aceite

### Banco de dados

- [ ] Tabela users criada.
- [ ] Campos obrigatórios definidos.
- [ ] E-mail único no PostgreSQL.
- [ ] Unicidade case-insensitive.
- [ ] Constraint de perfil.
- [ ] Consistência entre estado e desativação.
- [ ] Optimistic locking.
- [ ] Nenhuma senha armazenada em texto simples.
- [ ] Migrations anteriores preservadas.

### Gerenciamento

- [ ] Menu Usuários implementado.
- [ ] Página de listagem implementada.
- [ ] Indicadores cadastrais.
- [ ] Cadastro funcional.
- [ ] Edição funcional.
- [ ] Pesquisa por nome.
- [ ] Pesquisa por e-mail.
- [ ] Filtro por perfil.
- [ ] Filtro por status.
- [ ] Paginação.
- [ ] Ativação funcional.
- [ ] Desativação funcional.
- [ ] Motivo de desativação obrigatório.
- [ ] Redefinição de senha funcional.
- [ ] Ausência de exclusão definitiva.

### Perfis

- [ ] Administrador.
- [ ] Operador.
- [ ] Consulta.
- [ ] Perfil único por usuário.
- [ ] Alteração de perfil funcional.
- [ ] Matriz futura documentada.
- [ ] Aplicação definitiva de permissões
      reservada ao RF016.

### Senhas

- [ ] Hash seguro.
- [ ] Política de comprimento implementada.
- [ ] Limite técnico respeitado.
- [ ] Confirmação de senha.
- [ ] Flag de troca obrigatória.
- [ ] Senhas não expostas nas respostas.
- [ ] Senhas não registradas nos logs.
- [ ] Hashes não registrados na auditoria.
- [ ] Nenhuma credencial padrão.

### Administradores

- [ ] Bootstrap seguro.
- [ ] Bootstrap protegido contra duplicação.
- [ ] Proteção do último administrador.
- [ ] Proteção contra desativações concorrentes.
- [ ] Proteção contra mudanças de perfil concorrentes.

### Auditoria

- [ ] Entidade User suportada.
- [ ] Cadastro auditado.
- [ ] Alteração cadastral auditada.
- [ ] Mudança de perfil auditada.
- [ ] Ativação auditada.
- [ ] Desativação auditada.
- [ ] Redefinição auditada.
- [ ] Auditoria transacional.
- [ ] Proteção append-only preservada.
- [ ] Nenhuma credencial armazenada.
- [ ] Nenhum responsável fictício atribuído.

### Segurança

- [ ] Strong Parameters utilizado.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Escaping padrão preservado.
- [ ] Proteção contra SQL Injection.
- [ ] Campos internos protegidos.
- [ ] Cache administrativo tratado.
- [ ] Rotas indisponíveis em produção.
- [ ] Nenhum cadastro público.
- [ ] Nenhum login provisório.
- [ ] Nenhuma autorização provisória.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de segurança executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 58. Fora do escopo

Não implementar neste requisito:

- Tela de login.
- Logout.
- Sessões autenticadas.
- Remember me.
- Autenticação definitiva.
- Autorização definitiva.
- Aplicação efetiva da matriz de permissões.
- Troca de senha no primeiro acesso.
- Alteração de senha pelo próprio usuário.
- Recuperação de senha por e-mail.
- Tokens de recuperação.
- Autenticação de dois fatores.
- Passkeys.
- OAuth.
- SSO.
- Microsoft Entra ID.
- Active Directory.
- Login com Google.
- Login com Microsoft.
- Tabelas dinâmicas de perfis.
- Permissões individuais personalizadas.
- Cadastro público de contas.
- Exclusão definitiva de usuários.
- Exportação de usuários.
- Envio de credenciais por e-mail.
- Identificação individual dos operadores
  nos eventos existentes.
- Upload de documentos do RF013.
- Notificações do RF014.
- Integração com Power Automate.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente a estrutura
e o gerenciamento de usuários.

---

## 59. Entrega

Ao concluir o RF015, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.
- Limitações identificadas.

### Interface

- Screenshot da página de usuários.
- Screenshot do formulário de cadastro.
- Screenshot da edição.
- Screenshot dos filtros.
- Screenshot da desativação.
- Screenshot da redefinição de senha.

Não incluir senhas reais ou hashes
nas capturas de tela.

### Banco de dados

- Migration criada.
- Estrutura final da tabela users.
- Índices.
- Constraints.
- Alterações na entidade de auditoria.

### Backend

- Models criados.
- Controllers criados.
- Services criados ou reutilizados.
- Rotas adicionadas.
- Estratégia de validação.
- Estratégia de concorrência.

### Segurança

- Biblioteca de hashing.
- Versão utilizada.
- Configuração de custo.
- Política de senhas.
- Proteção do último administrador.
- Filtragem de parâmetros.
- Proteção das rotas administrativas.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Riscos identificados.

### Bootstrap

- Comando para criar o primeiro administrador.
- Procedimento seguro de execução.
- Comportamento em execuções repetidas.

Não incluir credenciais reais.

### Auditoria

- Eventos adicionados.
- Campos auditados.
- Campos protegidos.
- Estratégia transacional.

### Testes

- Comandos executados.
- Quantidade de testes.
- Quantidade de assertions.
- Falhas.
- Erros.
- Testes ignorados.
- Testes de concorrência.
- Testes de segurança.
- Resultado do RuboCop.
- Testes não executados e respectivos motivos.

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

Informar qualquer risco, limitação
ou decisão que necessite de homologação.

Listar as dependências necessárias
para o RF016.

---

## 60. Regra de parada

Ao concluir o RF015, PARE.

Não implementar o RF016.

Não implementar login.

Não implementar logout.

Não implementar sessões.

Não implementar autenticação definitiva.

Não implementar autorização definitiva.

Não implementar o RF013.

Não implementar o RF014.

Não integrar Power Automate.

Não realizar implantação em produção.

Preservar o layout administrativo aprovado.

Deixar a aplicação operacional
no ambiente de desenvolvimento
para homologação.

Aguardar novas instruções.