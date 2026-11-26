# RF006 — Cancelamento, Alteração e Reagendamento de Veículos

## 1. Objetivo

Implementar o gerenciamento dos agendamentos existentes através
do painel administrativo da aplicação DSV Doca Agenda.

Permitir que a equipe operacional realize:

- Cancelamento de agendamentos.
- Alteração da data agendada.
- Alteração da doca.
- Alteração da janela de horário.
- Reagendamento de reservas.
- Consulta de disponibilidade durante alterações.
- Registro do motivo da operação.
- Consulta das informações atualizadas.

Todas as operações deverão preservar a integridade dos dados,
a concorrência e o histórico dos agendamentos.

Preservar o layout administrativo aprovado no RF004 e as
funcionalidades operacionais implementadas no RF005.

---

## 2. Documentação obrigatória

Antes de iniciar a implementação, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/database/
- docs/requisitos/RF001.md
- docs/requisitos/RF002.md
- docs/requisitos/RF003.md
- docs/requisitos/RF004.md
- docs/requisitos/RF005.md
- docs/referencias/

Analisar a implementação existente antes de realizar alterações.

Reutilizar os componentes, models, controllers, services,
helpers e estilos existentes sempre que possível.

Preservar a arquitetura monolítica Ruby on Rails.

Não reconstruir o painel administrativo.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Estados dos agendamentos

Preservar os estados existentes:

    agendado
    em_operacao
    liberado
    cancelado
    reagendamento

Neste requisito, implementar as seguintes transições:

    agendado -> cancelado

    agendado -> agendado
    (Alteração da data, doca ou janela)

    reagendamento -> agendado
    (Reagendamento para uma nova posição)

    reagendamento -> cancelado

Não permitir alterações ou cancelamentos de reservas
nos estados:

- em_operacao
- liberado
- cancelado

Não implementar reativação de reservas canceladas.

Não modificar as transições de check-in e liberação
implementadas no RF005.

O processo automático que altera uma reserva para o estado
reagendamento será implementado em requisito posterior.

---

## 4. Integração com o painel administrativo

Utilizar a página de detalhes do agendamento existente.

Adicionar as ações:

    Alterar agendamento

    Cancelar agendamento

Quando a reserva estiver no estado reagendamento,
apresentar:

    Reagendar

    Cancelar agendamento

### 4.1 Reserva agendada

Apresentar as ações:

- Registrar check-in, conforme regras do RF005.
- Alterar agendamento.
- Cancelar agendamento.

### 4.2 Reserva em operação

Apresentar somente as ações operacionais existentes,
conforme RF005.

Não permitir alteração ou cancelamento.

### 4.3 Reserva liberada

Manter exclusivamente a consulta das informações.

### 4.4 Reserva cancelada

Manter exclusivamente a consulta das informações
e do motivo do cancelamento.

### 4.5 Reserva em reagendamento

Apresentar:

- Reagendar.
- Cancelar agendamento.

A exibição dos botões deverá respeitar os estados
existentes.

Ocultar um botão não substitui a validação no backend.

---

## 5. Cancelamento de agendamento

### 5.1 Objetivo

Permitir que a equipe operacional cancele uma reserva
sem excluir seu registro do banco de dados.

### 5.2 Estados permitidos

Permitir cancelamento somente quando o status for:

    agendado

ou:

    reagendamento

### 5.3 Confirmação

Ao selecionar Cancelar agendamento, apresentar uma
confirmação contendo:

- Protocolo.
- Responsável.
- Empresa / transportadora.
- Placa.
- Tipo de operação.
- Data agendada.
- Doca.
- Horário.
- Motivo do cancelamento.

Exemplo conceitual:

    Cancelar agendamento

    Protocolo: DA-XXXXXXXX
    Empresa: Transportadora ABC
    Placa: ABC1D23
    Operação: Entrega
    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 - 11:00

    Motivo do cancelamento:

    [______________________________________]
    [______________________________________]

    [Voltar] [Confirmar cancelamento]

Utilizar o padrão visual existente no painel.

Utilizar vermelho para identificar a ação de cancelamento.

Não executar o cancelamento antes da confirmação.

Não utilizar requisições GET para cancelar reservas.

---

## 6. Motivo do cancelamento

O motivo do cancelamento deverá ser obrigatório.

Utilizar o atributo existente:

    bookings.change_reason

Regras:

- Mínimo de 3 caracteres úteis.
- Máximo de 500 caracteres.
- Remover espaços desnecessários nas extremidades.
- Não aceitar conteúdo composto somente por espaços.
- Aceitar caracteres acentuados.
- Tratar o conteúdo como texto simples.

Exemplos:

    Transportadora informou que não realizará a coleta.

    Veículo apresentou problema mecânico.

    Entrega cancelada pelo responsável.

Realizar a validação obrigatoriamente no backend.

Preservar o motivo completo na tabela audit_events.

Não criar uma nova coluna exclusivamente para o motivo
do cancelamento neste requisito.

---

## 7. Persistência do cancelamento

Ao confirmar um cancelamento válido, atualizar:

    bookings.status = cancelado

    bookings.change_reason = motivo informado

Preservar:

- ID interno.
- Protocolo.
- Request ID.
- Nome do responsável.
- Empresa.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Operação.
- Data originalmente agendada.
- Doca.
- Janela.
- Data de criação.

Atualizar os atributos updated_at e lock_version
através dos mecanismos nativos do Rails.

Executar a alteração dentro de uma transação.

Registrar o evento de auditoria na mesma transação.

Caso a auditoria falhe, reverter integralmente
o cancelamento.

Não executar DELETE na tabela bookings.

Não excluir registros históricos.

---

## 8. Disponibilidade após o cancelamento

Uma reserva cancelada não deverá consumir capacidade.

A combinação original de:

- Data.
- Doca.
- Janela.

poderá voltar a receber novos agendamentos, desde que
todas as regras de disponibilidade sejam atendidas.

Exemplo:

    Doca: 03
    Data: Amanhã
    Janela: 10:00 - 11:00

    Reserva cancelada.

Resultado:

    A posição volta a ficar disponível.

Entretanto, quando o horário original já tiver passado
ou a posição estiver bloqueada, a janela não deverá
ser disponibilizada para novos agendamentos.

Reutilizar a lógica de disponibilidade implementada
no RF003.

Não duplicar as regras de disponibilidade.

---

## 9. Alteração de agendamento

### 9.1 Objetivo

Permitir alterar a posição de uma reserva existente
sem criar um novo agendamento.

### 9.2 Estados permitidos

Permitir alterações somente para reservas nos estados:

    agendado

    reagendamento

### 9.3 Campos permitidos

Permitir alterar exclusivamente:

- Data do agendamento.
- Número da doca.
- Número da janela.
- Motivo da alteração.

Não permitir neste requisito alterar:

- Nome do responsável.
- Empresa / transportadora.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Tipo de operação.
- Protocolo.
- Request ID.

A alteração dos dados cadastrais poderá ser avaliada
em requisito posterior.

---

## 10. Interface de alteração

Ao selecionar Alterar agendamento, apresentar
uma página ou formulário utilizando o layout
administrativo existente.

Apresentar inicialmente as informações atuais:

    Agendamento atual

    Protocolo: DA-XXXXXXXX
    Empresa: Transportadora ABC
    Placa: ABC1D23
    Operação: Entrega
    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 - 11:00

Abaixo, disponibilizar:

    Novo agendamento

    Data:
    [Hoje] [Amanhã] [Depois de amanhã]

    Doca:
    [01] [02] [03] [04]
    [05] [06] [07] [08]

    Horários disponíveis:
    [08:00 - 09:00] [09:00 - 10:00]
    [10:00 - 11:00] [11:00 - 12:00]
    ...

    Motivo da alteração:
    [______________________________________]

    [Voltar] [Confirmar alteração]

Reutilizar os componentes de seleção implementados
no formulário público, quando apropriado.

Não duplicar desnecessariamente HTML, CSS ou JavaScript.

Não modificar o funcionamento da página /agendar.

---

## 11. Comparação entre agendamento atual e novo

Antes da confirmação, apresentar de maneira clara
a posição atual e a nova posição selecionada.

Exemplo:

    Agendamento atual

    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 - 11:00

    Novo agendamento

    Data: 27/11/2026
    Doca: 05
    Horário: 14:00 - 15:00

Essa comparação deverá auxiliar o operador a evitar
alterações incorretas.

Não exigir uma estrutura complexa de modal.

Priorizar HTML, ERB e recursos nativos do Rails.

---

## 12. Horizonte de alteração e reagendamento

A nova posição deverá respeitar o mesmo horizonte
utilizado pelo formulário público:

- Hoje.
- Amanhã.
- Depois de amanhã.

Utilizar o fuso operacional:

    America/Sao_Paulo

Utilizar o relógio do servidor.

Não permitir selecionar:

- Datas anteriores ao dia atual.
- Datas posteriores ao horizonte permitido.
- Datas inválidas.

O painel administrativo continuará permitindo
a consulta de datas históricas.

Entretanto, uma alteração ou reagendamento deverá
utilizar uma nova data válida dentro do horizonte.

Não criar exceções administrativas de data
neste requisito.

---

## 13. Docas disponíveis

Preservar as oito docas físicas existentes:

    01
    02
    03
    04
    05
    06
    07
    08

Reutilizar as definições fixas existentes no Rails.

Não criar cadastro de docas.

Não criar tabelas adicionais.

Não duplicar as definições em JavaScript.

Preservar a regra de distribuição operacional
atualmente utilizada na aplicação.

Enquanto não existir uma definição definitiva
da distribuição entre recebimento e expedição,
não inventar uma nova classificação para as docas.

Não implementar exceções de tipo de doca ou
permissões especiais neste requisito.

---

## 14. Janelas de horários

Preservar as dez janelas fixas:

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

Reutilizar as definições existentes no backend.

Não criar cadastro de janelas.

Não alterar os horários operacionais.

---

## 15. Disponibilidade durante a alteração

Ao selecionar uma nova data e doca, consultar
a disponibilidade das janelas.

Considerar:

- Reservas existentes.
- Bloqueios existentes.
- Data selecionada.
- Horário atual do servidor.
- Horizonte permitido.
- Estado das reservas.

Estados que consomem capacidade:

    agendado
    em_operacao
    liberado

Estados que não consomem capacidade:

    cancelado
    reagendamento

Não permitir alteração para uma posição ocupada
por outra reserva que consuma capacidade.

Não permitir alteração para uma posição bloqueada.

Reutilizar o motor de disponibilidade existente.

---

## 16. Disponibilidade conforme a data selecionada

Preservar a correção realizada anteriormente
no formulário público.

### 16.1 Dia atual

Bloquear somente as janelas cujo início seja
menor ou igual ao horário atual do servidor.

### 16.2 Datas futuras

Não bloquear uma janela apenas porque seu horário
já passou no dia atual.

Exemplo:

    Horário atual: 14:30

    Hoje:
    08:00 - 09:00 -> Indisponível

    Amanhã:
    08:00 - 09:00 -> Disponível, se livre

    Depois de amanhã:
    08:00 - 09:00 -> Disponível, se livre

A comparação deverá considerar a data selecionada
e o horário inicial da janela.

Não comparar somente a hora do relógio.

Centralizar essa regra no backend.

---

## 17. Tratamento da própria reserva

Durante a consulta de disponibilidade para alteração,
considerar que a reserva em edição já ocupa
uma posição na agenda.

A própria reserva não deverá ser interpretada
como um conflito com outro agendamento.

Entretanto, o horário originalmente agendado
não poderá ser apresentado como livre para
outros participantes.

Caso nenhuma alteração seja realizada na combinação:

- Data.
- Doca.
- Janela.

e a reserva já esteja no estado agendado,
informar:

    Nenhuma alteração foi realizada.

Não gravar uma atualização desnecessária.

Não gerar um evento de auditoria de alteração
quando não houver alteração efetiva.

Uma reserva no estado reagendamento deverá
selecionar uma posição atualmente válida.

Caso a combinação anterior ainda seja elegível
e esteja disponível, permitir sua utilização
para retornar ao estado agendado.

---

## 18. Motivo da alteração

O motivo deverá ser obrigatório para qualquer
alteração ou reagendamento efetivo.

Utilizar:

    bookings.change_reason

Regras:

- Mínimo de 3 caracteres úteis.
- Máximo de 500 caracteres.
- Não aceitar somente espaços.
- Remover espaços desnecessários nas extremidades.
- Tratar o conteúdo como texto simples.

Exemplos:

    Alteração solicitada pela transportadora.

    Veículo será disponibilizado em outro horário.

    Reorganização operacional das docas.

Registrar o motivo na auditoria.

Preservar os motivos anteriores através dos
eventos históricos.

---

## 19. Persistência da alteração

Ao confirmar uma alteração válida, atualizar
o mesmo registro da tabela bookings.

Atributos:

    booking_date
    dock_number
    slot_number
    change_reason

Preservar:

    id
    protocol
    request_id
    operation
    contact_name
    company
    invoice
    plate
    vehicle_model
    created_at

Não criar um novo registro para representar
a alteração de uma reserva existente.

Não cancelar a reserva original para criar
outra automaticamente.

Utilizar o mecanismo nativo de optimistic locking.

Registrar a auditoria dentro da mesma transação.

---

## 20. Reagendamento

Uma reserva com status reagendamento deverá
poder receber uma nova posição válida.

Ao confirmar o reagendamento, atualizar:

    booking_date = nova data

    dock_number = nova doca

    slot_number = nova janela

    status = agendado

    change_reason = motivo informado

Preservar o protocolo original.

Preservar o ID interno.

Preservar o histórico anterior.

Não criar uma nova reserva.

Não modificar o request_id original.

Não implementar o fechamento automático
de no-shows neste requisito.

---

## 21. Preservação da idempotência original

O request_id está associado à tentativa original
de criação do agendamento.

Uma alteração administrativa não deverá modificar
o significado desse identificador.

Verificar a implementação de idempotência do RF003.

Garantir que o reenvio da solicitação original,
após uma alteração ou cancelamento administrativo,
não provoque:

- Criação de outra reserva.
- Reativação de reserva cancelada.
- Restauração da posição originalmente reservada.
- Sobrescrita de alterações administrativas.
- Duplicação de eventos de auditoria.

A comparação idempotente deverá considerar os
dados originais da criação, e não exclusivamente
a posição atual da reserva.

Avaliar se a estrutura de auditoria de criação
já permite preservar essa informação.

Caso seja indispensável uma alteração estrutural,
criar uma migration específica e documentar
a necessidade.

Não reconstruir desnecessariamente o mecanismo
de idempotência existente.

---

## 22. Liberação da posição original

Após uma alteração ou reagendamento bem-sucedido,
a posição original deverá deixar de ser consumida
pela reserva.

Exemplo:

    Posição original:

    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 - 11:00

    Nova posição:

    Data: 27/11/2026
    Doca: 05
    Horário: 14:00 - 15:00

Resultado:

- A nova posição passa a ser reservada.
- A posição original deixa de ser consumida.
- O protocolo permanece o mesmo.
- A alteração fica registrada na auditoria.

A posição original somente deverá voltar a aparecer
como disponível quando atender a todas as regras
de disponibilidade.

Se a nova posição estiver indisponível, nenhuma
alteração deverá ser persistida.

A reserva deverá permanecer na posição anterior.

Não liberar a posição original antes de garantir
a nova posição dentro da transação.

---

## 23. Controle de concorrência

Preservar o atributo:

    lock_version

Utilizar o mecanismo nativo de optimistic locking
do Active Record.

O formulário administrativo deverá transmitir
a versão consultada pelo operador.

Validar essa versão antes de executar a operação.

Não substituir silenciosamente a versão recebida
pela versão mais recente do banco.

Considerar o cenário:

    Operador A abre o agendamento.

    Operador B abre o mesmo agendamento.

    Operador A altera o horário.

    Operador B tenta cancelar utilizando
    a versão anterior do registro.

Resultado esperado:

- A alteração do operador A é preservada.
- A operação desatualizada é rejeitada.
- Nenhum dado é sobrescrito silenciosamente.

Apresentar a mensagem:

    Este agendamento foi atualizado por outra operação.
    Consulte os dados atualizados antes de continuar.

Não repetir automaticamente operações administrativas
rejeitadas por conflito de versão.

---

## 24. Concorrência entre reservas

Considerar que o formulário público continuará
recebendo novos agendamentos.

Cenário:

    Um operador seleciona uma nova posição
    para reagendar um veículo.

    Simultaneamente, uma transportadora tenta
    reservar a mesma posição.

Apenas uma operação poderá confirmar a posição.

Preservar o índice único parcial criado no RF002.

O PostgreSQL deverá continuar impedindo duas
reservas que consumam a mesma combinação de:

- Data.
- Doca.
- Janela.

Tratar conflitos sem apresentar erros internos.

Caso a alteração seja rejeitada:

- Preservar a reserva original.
- Preservar os dados informados no formulário.
- Atualizar a disponibilidade.
- Solicitar uma nova seleção.

Não gerar auditoria de sucesso para uma alteração
que tenha falhado.

---

## 25. Integridade entre reservas e bloqueios

Reutilizar a estratégia de controle transacional
implementada no RF003 para alterações de capacidade.

Não criar um segundo mecanismo de travas independente.

Ao alterar uma reserva, considerar:

- A posição original.
- A nova posição.

Utilizar a mesma estratégia de travamento para
cancelamentos, alterações e reagendamentos que
modifiquem o consumo de capacidade.

Quando for necessário adquirir travas para
mais de uma posição, utilizar uma ordem
determinística para reduzir riscos de deadlock.

Após adquirir as travas:

- Reconsultar a reserva.
- Validar o estado atual.
- Validar a versão.
- Revalidar a nova posição.
- Verificar a existência de bloqueios.
- Verificar reservas concorrentes.
- Confirmar a validade temporal da nova posição.

Executar a alteração e a auditoria dentro
da mesma transação.

Não utilizar:

- Mutex Ruby como única proteção.
- Travas exclusivamente em memória.
- JavaScript como proteção de concorrência.
- Redis.

O futuro RF de bloqueios deverá utilizar
obrigatoriamente a mesma estratégia.

Documentar qualquer limitação ainda existente
na proteção entre bookings e slot_blocks.

Não declarar essa proteção integralmente concluída
enquanto existirem caminhos de escrita que não
utilizem o mecanismo compartilhado.

---

## 26. Concorrência com check-in e liberação

Preservar as funcionalidades do RF005.

Considerar o cenário:

    Um operador tenta cancelar uma reserva.

    Simultaneamente, outro operador tenta
    registrar seu check-in.

Somente uma transição compatível poderá ser
confirmada.

Se o check-in for confirmado primeiro:

- A reserva passa para em_operacao.
- O cancelamento deverá ser rejeitado.

Se o cancelamento for confirmado primeiro:

- A reserva passa para cancelado.
- O check-in deverá ser rejeitado.

Aplicar a mesma proteção para alterações
e reagendamentos concorrentes com check-in.

Não permitir alteração de uma reserva que
tenha entrado em operação após a abertura
do formulário administrativo.

Utilizar controle de concorrência, transações
e validação do estado atual do registro.

---

## 27. Auditoria de cancelamento

Utilizar a tabela:

    audit_events

Registrar:

    entity_type: Booking

    entity_id: ID interno da reserva

    action: cancel

    reason: motivo do cancelamento

Registrar em previous_values:

- Status anterior.
- Data agendada.
- Doca.
- Janela.
- Motivo anterior, quando existente.

Registrar em new_values:

- Novo status.
- Motivo atualizado.

Utilizar o horário do servidor para created_at.

Não implementar identificação individual
de usuários neste requisito.

---

## 28. Auditoria de alteração

Registrar:

    entity_type: Booking

    entity_id: ID interno da reserva

    action: reschedule

    reason: motivo da alteração

Exemplo conceitual:

    previous_values:

        booking_date: 2026-11-26
        dock_number: 3
        slot_number: 3
        status: agendado

    new_values:

        booking_date: 2026-11-27
        dock_number: 5
        slot_number: 7
        status: agendado

Para uma reserva no estado reagendamento,
registrar também a transição:

    reagendamento -> agendado

Preservar a nomenclatura de auditoria existente,
caso já exista uma convenção equivalente no projeto.

Não criar dois eventos para representar
uma única alteração.

Não sobrescrever auditorias anteriores.

---

## 29. Integridade da auditoria

Todas as alterações operacionais deverão
ser registradas na mesma transação da reserva.

Caso a gravação da auditoria falhe:

- Reverter a alteração.
- Reverter o cancelamento.
- Preservar a posição original.
- Preservar o estado original.

Não criar eventos de sucesso para operações rejeitadas.

Não registrar indiscriminadamente todos os parâmetros
recebidos pelo controller.

Não armazenar:

- Tokens.
- Credenciais.
- Cookies.
- Informações de sessão.
- Dados pessoais desnecessários.

Preservar a estrutura existente da tabela audit_events.

A interface completa de consulta do histórico
será implementada em requisito posterior.

---

## 30. Atualização do painel administrativo

Após uma operação bem-sucedida, atualizar
as informações apresentadas no painel.

### 30.1 Cancelamento

- Alterar o status para Cancelado.
- Remover a ocupação da posição na matriz.
- Preservar a reserva na lista de agendamentos.
- Atualizar os indicadores operacionais.
- Exibir o motivo do cancelamento nos detalhes.

### 30.2 Alteração

- Remover a reserva da posição anterior.
- Apresentar a reserva na nova posição.
- Atualizar os indicadores das datas envolvidas.
- Exibir os dados atualizados na lista.
- Exibir o motivo da última alteração.

### 30.3 Reagendamento

- Alterar o status para Agendado.
- Apresentar a reserva na nova posição.
- Atualizar os indicadores.
- Preservar o histórico.

Não reconstruir a matriz existente.

Não alterar a estrutura geral do Dashboard.

Não implementar atualização automática
neste requisito.

Utilizar o mecanismo atual de atualização
das informações.

---

## 31. Rotas administrativas

Criar as rotas necessárias dentro do namespace
administrativo existente.

Estrutura sugerida:

    GET /admin/bookings/:id/edit

    PATCH /admin/bookings/:id/reschedule

    GET /admin/bookings/:id/cancellation

    PATCH /admin/bookings/:id/cancel

Utilizar os helpers e convenções nativas do Rails.

A nomenclatura poderá ser adaptada à estrutura
existente, desde que as responsabilidades sejam
mantidas.

Utilizar GET exclusivamente para consulta
e apresentação dos formulários.

Utilizar PATCH para operações que alterem
o estado da reserva.

Não criar uma rota DELETE para agendamentos.

Não criar APIs JSON exclusivamente para
alimentar as próprias views Rails.

---

## 32. Organização do backend

Analisar a estrutura existente.

Manter os controllers pequenos e organizados.

Centralizar as regras de:

- Cancelamento.
- Alteração.
- Reagendamento.
- Validação de disponibilidade.
- Concorrência.
- Auditoria.

Reutilizar services e métodos de domínio
existentes quando apropriado.

Caso seja necessário criar novos services,
utilizar responsabilidades específicas.

Não criar abstrações genéricas desnecessárias.

Não adicionar bibliotecas de state machine.

Não utilizar callbacks complexos para
executar transições automaticamente.

As alterações deverão ser explícitas,
previsíveis e testáveis.

---

## 33. Tratamento de erros

Apresentar mensagens claras em português do Brasil.

### Reserva incompatível

    O estado atual do agendamento não permite
    realizar esta operação.

### Motivo inválido

    Informe um motivo contendo entre
    3 e 500 caracteres.

### Horário indisponível

    O horário selecionado não está mais disponível.
    Selecione outro horário.

### Horário bloqueado

    A posição selecionada está bloqueada.

### Data inválida

    Selecione uma data dentro do período
    permitido para agendamento.

### Conflito de versão

    Este agendamento foi atualizado por outra operação.
    Consulte os dados atualizados antes de continuar.

### Alteração inexistente

    Nenhuma alteração foi realizada.

### Cancelamento confirmado

    Agendamento cancelado com sucesso.

### Alteração confirmada

    Agendamento alterado com sucesso.

### Reagendamento confirmado

    Agendamento reagendado com sucesso.

Preservar os dados preenchidos quando ocorrer
um erro de validação.

Não apresentar mensagens internas do PostgreSQL.

Não expor stack traces.

Utilizar códigos HTTP adequados para validações,
conflitos e registros inexistentes.

---

## 34. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Utilizar Strong Parameters.

Para cancelamento, permitir somente:

- change_reason
- lock_version

Para alteração e reagendamento, permitir somente:

- booking_date
- dock_number
- slot_number
- change_reason
- lock_version

Não permitir que o navegador determine diretamente:

- id
- status
- protocol
- request_id
- operation
- checkin_at
- released_at
- release_remark
- created_at
- updated_at

O status deverá ser definido pelo backend
conforme a operação solicitada.

Validar os parâmetros antes de executar
qualquer alteração.

Manter proteção CSRF habilitada.

Preservar Content Security Policy.

Utilizar escaping padrão do ERB.

Não utilizar raw ou html_safe para apresentar
motivos fornecidos pelo operador.

Utilizar consultas parametrizadas.

Não concatenar entrada de usuário em SQL.

Não implementar autenticação provisória.

Não criar usuários ou credenciais fixas.

Manter todas as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

Não disponibilizar essas funcionalidades
em produção antes da implementação de
autenticação e autorização.

---

## 35. JavaScript

Utilizar o mínimo necessário de JavaScript.

Priorizar:

- HTML.
- CSS.
- ERB.
- Formulários Rails.
- Turbo, quando necessário.
- Stimulus, somente quando justificado.

Reutilizar os componentes existentes de
seleção de datas, docas e horários.

Ao alterar a data ou doca:

- Atualizar a disponibilidade.
- Preservar o motivo preenchido.
- Limpar uma seleção que deixe de ser válida.
- Impedir respostas antigas de sobrescrever
  seleções mais recentes.

Não implementar regras de negócio exclusivamente
no navegador.

Não utilizar JavaScript para decidir se uma
reserva pode ser cancelada ou reagendada.

Não utilizar:

- eval
- new Function
- document.write
- innerHTML com conteúdo não confiável
- outerHTML com conteúdo não confiável
- Handlers JavaScript inline
- Scripts de CDNs

Não enfraquecer a Content Security Policy.

Não introduzir novas dependências frontend.

---

## 36. Banco de dados

Utilizar as tabelas existentes:

    bookings
    slot_blocks
    audit_events

Utilizar os índices e constraints implementados
nos requisitos anteriores.

Não criar novas tabelas.

Não criar migrations desnecessárias.

Não modificar migrations já aplicadas.

Caso seja indispensável uma alteração estrutural
para garantir integridade ou preservar a
idempotência original, documentar a necessidade
e utilizar uma nova migration.

Não excluir dados existentes.

Não implementar expurgo de registros.

Não modificar a quantidade de docas ou janelas.

---

## 37. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 37.1 Cancelamento válido

Validar:

- Cancelamento de reserva agendada.
- Cancelamento de reserva em reagendamento.
- Persistência do motivo.
- Alteração do status para cancelado.
- Preservação do protocolo.
- Preservação do registro original.
- Criação da auditoria.
- Liberação da capacidade quando elegível.

### 37.2 Cancelamento inválido

Validar a rejeição de:

- Reserva em operação.
- Reserva liberada.
- Reserva já cancelada.
- Motivo ausente.
- Motivo inferior a 3 caracteres úteis.
- Motivo superior a 500 caracteres.
- Motivo composto somente por espaços.
- Versão desatualizada.
- Registro inexistente.

### 37.3 Alteração válida

Validar:

- Alteração somente da data.
- Alteração somente da doca.
- Alteração somente da janela.
- Alteração simultânea de data, doca e janela.
- Preservação do ID interno.
- Preservação do protocolo.
- Preservação dos dados cadastrais.
- Liberação da posição original.
- Reserva da nova posição.
- Criação da auditoria.

### 37.4 Alteração inválida

Validar a rejeição de:

- Reserva em operação.
- Reserva liberada.
- Reserva cancelada.
- Data anterior ao dia atual.
- Data posterior ao horizonte permitido.
- Doca inválida.
- Janela inválida.
- Horário já iniciado no dia atual.
- Posição reservada por outro agendamento.
- Posição bloqueada.
- Motivo inválido.
- Versão desatualizada.

### 37.5 Alteração sem mudanças

Validar:

- Identificação da própria reserva.
- Ausência de falso conflito com a própria posição.
- Ausência de atualização desnecessária.
- Ausência de auditoria duplicada.

### 37.6 Reagendamento

Validar:

- Reserva em reagendamento.
- Seleção de uma posição válida.
- Alteração para status agendado.
- Preservação do protocolo.
- Preservação do histórico.
- Criação da auditoria.
- Consumo da nova posição.

### 37.7 Disponibilidade

Validar:

- Horários passados bloqueados somente no dia atual.
- Horários de datas futuras disponíveis quando livres.
- Consulta de bloqueios.
- Reservas canceladas não consomem capacidade.
- Reservas em reagendamento não consomem capacidade.
- Reservas liberadas continuam consumindo capacidade.
- Atualização da disponibilidade após cancelamento.
- Atualização da disponibilidade após alteração.

### 37.8 Concorrência

Realizar testes utilizando conexões independentes
e transações efetivamente concorrentes no PostgreSQL.

Validar:

- Duas alterações para a mesma posição.
- Alteração concorrente com criação de nova reserva.
- Cancelamento concorrente com check-in.
- Alteração concorrente com check-in.
- Duas operações sobre a mesma versão da reserva.
- Dois cancelamentos simultâneos.
- Reagendamentos concorrentes.

Somente operações compatíveis poderão
ser confirmadas.

Não simular concorrência exclusivamente através
de operações sequenciais.

### 37.9 Transações e rollback

Simular falhas durante a operação.

Validar:

- Falha na auditoria de cancelamento.
- Falha na auditoria de alteração.
- Conflito na nova posição.
- Preservação da posição original.
- Preservação do status original.
- Ausência de atualizações parciais.
- Ausência de auditorias de sucesso indevidas.

### 37.10 Idempotência

Validar:

- Reenvio da solicitação original após alteração.
- Reenvio da solicitação original após reagendamento.
- Reenvio da solicitação original após cancelamento.
- Ausência de reservas duplicadas.
- Ausência de reativação indevida.
- Preservação da posição atual.
- Ausência de auditorias duplicadas.

### 37.11 Segurança

Validar:

- Manipulação de status pelo navegador.
- Tentativa de alteração do protocolo.
- Tentativa de alteração do request_id.
- Tentativa de alteração de dados cadastrais.
- Tentativa de alteração dos horários efetivos.
- Tentativa de XSS no motivo.
- Tentativa de SQL Injection.
- Proteção CSRF efetivamente habilitada.
- Preservação da Content Security Policy.
- Indisponibilidade das rotas em produção.

### 37.12 Regressão

Executar todos os testes existentes dos:

- RF001.
- RF002.
- RF003.
- RF004.
- RF005.

Não remover ou enfraquecer testes anteriores
para permitir a aprovação deste requisito.

---

## 38. Validação manual

Realizar os seguintes cenários utilizando
o ambiente de desenvolvimento.

### Cenário 01 — Cancelamento

1. Criar um agendamento para uma data futura.
2. Acessar o painel administrativo.
3. Localizar o agendamento.
4. Selecionar Cancelar agendamento.
5. Informar o motivo.
6. Confirmar o cancelamento.
7. Verificar o status Cancelado.
8. Verificar a disponibilidade da posição original.
9. Verificar os indicadores.
10. Verificar a auditoria.

### Cenário 02 — Alteração

1. Criar um agendamento.
2. Acessar seus detalhes.
3. Selecionar Alterar agendamento.
4. Selecionar uma nova data.
5. Selecionar uma nova doca.
6. Selecionar uma nova janela.
7. Informar o motivo.
8. Confirmar a alteração.
9. Verificar a nova posição na matriz.
10. Verificar a posição original.
11. Confirmar que o protocolo permanece igual.
12. Verificar a auditoria.

### Cenário 03 — Conflito

1. Abrir a mesma reserva em duas sessões.
2. Alterar a reserva na primeira sessão.
3. Tentar cancelar na segunda sessão.
4. Confirmar que a operação desatualizada
   é rejeitada.
5. Verificar a integridade do agendamento.

### Cenário 04 — Veículo em operação

1. Criar uma reserva válida.
2. Registrar o check-in.
3. Verificar que as opções de alteração
   e cancelamento não estão disponíveis.
4. Tentar executar diretamente uma dessas ações.
5. Confirmar que o backend rejeita a operação.
6. Liberar a doca normalmente.

### Cenário 05 — Disponibilidade futura

1. Abrir a tela de alteração após o início
   de algumas janelas do dia atual.
2. Verificar os horários indisponíveis de hoje.
3. Selecionar amanhã.
4. Confirmar que as janelas livres voltam
   a ficar disponíveis.
5. Selecionar depois de amanhã.
6. Confirmar o mesmo comportamento.

Utilizar dados de teste.

Não alterar o relógio do sistema operacional
para simular horários.

Verificar o console do navegador.

Não deverão existir:

- Erros JavaScript.
- Violações inesperadas de CSP.
- Erros de carregamento.
- Links quebrados.
- Componentes sobrepostos.

---

## 39. Documentação

Registrar o requisito em:

    docs/requisitos/RF006.md

Atualizar o índice de requisitos.

Documentar:

- Fluxo de cancelamento.
- Fluxo de alteração.
- Fluxo de reagendamento.
- Estados permitidos.
- Transições implementadas.
- Campos permitidos.
- Motivos obrigatórios.
- Estratégia de concorrência.
- Estratégia de auditoria.
- Preservação da idempotência.
- Rotas administrativas adicionadas.
- Limitações existentes.

Atualizar a documentação do banco caso
alguma alteração estrutural seja necessária.

Criar ADR somente quando existir uma nova
decisão arquitetural relevante.

---

## 40. Critérios de aceite

### Cancelamento

- [ ] Botão Cancelar agendamento implementado.
- [ ] Confirmação de cancelamento implementada.
- [ ] Motivo obrigatório.
- [ ] Status atualizado para cancelado.
- [ ] Registro original preservado.
- [ ] Protocolo preservado.
- [ ] Cancelamento duplicado impedido.
- [ ] Capacidade liberada quando elegível.

### Alteração

- [ ] Botão Alterar agendamento implementado.
- [ ] Informações atuais apresentadas.
- [ ] Seleção de nova data funcional.
- [ ] Seleção de nova doca funcional.
- [ ] Seleção de nova janela funcional.
- [ ] Comparação entre posição atual e nova.
- [ ] Disponibilidade consultada no backend.
- [ ] Motivo obrigatório.
- [ ] Protocolo original preservado.
- [ ] ID interno preservado.
- [ ] Posição original liberada após confirmação.
- [ ] Nova posição reservada corretamente.
- [ ] Alterações sem mudanças tratadas.

### Reagendamento

- [ ] Reserva em reagendamento pode ser reagendada.
- [ ] Nova posição validada.
- [ ] Status atualizado para agendado.
- [ ] Histórico preservado.
- [ ] Nenhuma reserva duplicada criada.

### Concorrência

- [ ] Controle por lock_version funcional.
- [ ] Alterações concorrentes protegidas.
- [ ] Conflitos com novas reservas protegidos.
- [ ] Conflitos com check-in protegidos.
- [ ] Estratégia compartilhada de travamento reutilizada.
- [ ] Reserva original preservada em caso de falha.
- [ ] Idempotência original preservada.

### Auditoria

- [ ] Cancelamento auditado.
- [ ] Alteração auditada.
- [ ] Reagendamento auditado.
- [ ] Valores anteriores preservados.
- [ ] Novos valores registrados.
- [ ] Motivos registrados.
- [ ] Auditoria gravada na mesma transação.
- [ ] Rollback validado.
- [ ] Nenhuma auditoria de sucesso indevida.

### Painel administrativo

- [ ] Layout aprovado preservado.
- [ ] Matriz atualizada corretamente.
- [ ] Lista de agendamentos atualizada.
- [ ] Indicadores consistentes.
- [ ] Reservas canceladas permanecem consultáveis.
- [ ] Motivos apresentados nos detalhes.
- [ ] Formulário público preservado.
- [ ] Check-in e liberação continuam funcionando.

### Segurança

- [ ] Strong Parameters utilizado.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Dados do usuário escapados corretamente.
- [ ] Transições validadas no backend.
- [ ] Constraints do PostgreSQL preservadas.
- [ ] Nenhuma autenticação provisória criada.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma vulnerabilidade alta ou crítica conhecida
      sem tratamento.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de segurança executados.
- [ ] Testes de regressão aprovados.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.
- [ ] Console do navegador sem erros inesperados.
- [ ] Documentação atualizada.

---

## 41. Fora do escopo

Não implementar neste requisito:

- Exclusão definitiva de agendamentos.
- Reativação de reservas canceladas.
- Alteração de dados cadastrais da reserva.
- Alteração do tipo de operação.
- Cadastro de docas.
- Cadastro de janelas.
- Bloqueio de docas.
- Desbloqueio de docas.
- Fechamento automático de no-show.
- Atualização automática do painel.
- Polling.
- WebSockets.
- QR Code.
- Interface completa de histórico e auditoria.
- Exportação Excel.
- Notificações por e-mail.
- Upload de documentos.
- Active Storage.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente o gerenciamento
de cancelamento, alteração e reagendamento.

---

## 42. Entrega

Ao concluir o RF006, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Interface

- Componentes adicionados.
- Botões implementados.
- Screenshot do formulário de alteração.
- Screenshot da confirmação de cancelamento.
- Screenshot dos estados atualizados no painel.

### Backend

- Rotas criadas.
- Controllers modificados.
- Models modificados.
- Services criados ou reutilizados.
- Regras operacionais implementadas.
- Estratégia de concorrência.
- Estratégia de idempotência.
- Estratégia de auditoria.

### Banco de dados

- Índices utilizados.
- Constraints utilizadas.
- Eventuais migrations e justificativas.

### Segurança

- Proteções preservadas.
- Proteções adicionadas.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Riscos identificados.
- Limitações existentes.

### Testes

- Comandos executados.
- Quantidade de testes.
- Quantidade de assertions.
- Falhas.
- Erros.
- Testes ignorados.
- Resultados dos testes de concorrência.
- Resultado do RuboCop.
- Testes não executados e respectivos motivos.

### Critérios de aceite

Informar individualmente os critérios
atendidos e pendentes.

Não inventar resultados de testes.

Não declarar o requisito concluído quando
existirem critérios obrigatórios pendentes.

### Repositório

Apresentar:

    git status --short

### Pendências

Informar qualquer problema, limitação ou decisão
técnica que necessite de homologação.

---

## 43. Regra de parada

Ao concluir o RF006, PARE.

Não implementar o RF007.

Não implementar bloqueios ou desbloqueios de docas.

Não implementar fechamento automático de no-show.

Não implementar autenticação ou autorização.

Não alterar o layout administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.