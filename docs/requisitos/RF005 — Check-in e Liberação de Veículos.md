# RF005 — Check-in e Liberação de Veículos

## 1. Objetivo

Implementar o controle de entrada e liberação de veículos
através do painel administrativo da aplicação DSV Doca Agenda.

Permitir que a equipe operacional registre:

- Chegada do veículo.
- Check-in.
- Início da operação.
- Ocupação da doca.
- Liberação da doca.
- Horário efetivo de liberação.
- Observação da liberação.

As operações deverão atualizar os agendamentos existentes
no PostgreSQL e registrar o histórico na tabela audit_events.

Preservar integralmente o layout administrativo aprovado
no RF004.

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
- docs/referencias/

Analisar a implementação existente antes de realizar alterações.

Reutilizar os models, controllers, layouts, componentes
e estilos existentes sempre que possível.

Não reconstruir o painel administrativo.

Preservar a arquitetura monolítica Ruby on Rails.

---

## 3. Fluxo operacional

Implementar as seguintes transições:

    agendado
        |
        | Registrar check-in
        v
    em_operacao
        |
        | Liberar doca
        v
    liberado

As demais situações existentes deverão permanecer
inalteradas:

- cancelado
- reagendamento

Não implementar cancelamento ou reagendamento neste RF.

Não permitir transições diferentes das previstas
neste requisito.

Todas as transições deverão ser validadas no backend.

---

## 4. Integração com o painel administrativo

Utilizar a página de detalhes do agendamento
implementada no RF004.

Adicionar uma seção denominada:

    Controle operacional

Essa seção deverá apresentar:

- Status atual do agendamento.
- Data e horário agendados.
- Doca selecionada.
- Horário efetivo de check-in.
- Horário efetivo de liberação.
- Observação da liberação.
- Ações operacionais disponíveis.

Exibir somente os botões compatíveis com o estado
atual do agendamento.

Não modificar desnecessariamente:

- Header.
- Sidebar.
- Paleta de cores.
- Indicadores existentes.
- Matriz de docas.
- Lista de agendamentos.
- Formulário público /agendar.

---

## 5. Check-in

### 5.1 Objetivo

Permitir registrar a chegada de um veículo para
iniciar sua operação na doca agendada.

### 5.2 Botão

Disponibilizar o botão:

    Registrar check-in

O botão deverá estar disponível para reservas
com status:

    agendado

Quando alguma condição impedir o check-in,
apresentar uma mensagem informando o motivo.

Não permitir check-in para reservas nos estados:

- em_operacao
- liberado
- cancelado
- reagendamento

A disponibilidade visual do botão não substitui
a validação obrigatória no backend.

### 5.3 Confirmação

Antes de registrar o check-in, apresentar
uma confirmação simples.

Exemplo:

    Registrar check-in?

    Protocolo: DA-XXXXXXXX
    Placa: ABC1D23
    Doca: 03
    Horário agendado: 10:00 - 11:00

    Confirma a entrada do veículo?

    [Voltar] [Confirmar check-in]

Priorizar uma solução simples utilizando os
recursos nativos do Rails.

Não criar componentes JavaScript complexos.

---

## 6. Regras para realização do check-in

O check-in somente poderá ser realizado quando
TODAS as condições abaixo forem atendidas.

### 6.1 Status

A reserva deverá estar no estado:

    agendado

### 6.2 Data

A data agendada deverá corresponder à data
operacional atual.

Não permitir check-in:

- Em agendamentos de dias anteriores.
- Em agendamentos de dias futuros.

Utilizar o fuso:

    America/Sao_Paulo

### 6.3 Horário inicial da operação

O check-in deverá ser realizado somente
a partir das 08:00.

### 6.4 Horário da janela

O horário atual deverá ser igual ou posterior
ao início da janela agendada.

Exemplo:

    Janela: 10:00 - 11:00

    09:59 -> Check-in não permitido.
    10:00 -> Check-in permitido.
    10:15 -> Check-in permitido.

Considerar as demais condições de disponibilidade
da doca.

### 6.5 Limite operacional

O horário limite para realização de check-in será:

    17:30

A partir das 17:30:00, inclusive, não permitir
novos check-ins.

Exemplo:

    17:29:59 -> Permitido, se as demais regras forem atendidas.
    17:30:00 -> Não permitido.
    17:31:00 -> Não permitido.

A última janela operacional permanece:

    17:00 - 17:48

Não confundir o horário limite de entrada com
o horário de encerramento da última janela.

### 6.6 Disponibilidade física da doca

A doca não poderá possuir outro veículo
com status:

    em_operacao

Essa validação deverá considerar todas as
reservas existentes, independentemente da
data ou janela do veículo que ocupa a doca.

Uma operação iniciada anteriormente e ainda
não liberada deverá impedir um novo check-in.

### 6.7 Concorrência

A versão do registro deverá corresponder à
versão consultada pelo operador.

Utilizar o atributo:

    lock_version

Preservar o mecanismo nativo de optimistic locking
do Active Record.

Não permitir sobrescrita de alterações concorrentes.

---

## 7. Chegada atrasada

O término da janela original não deverá,
isoladamente, impedir a realização do check-in.

Exemplo:

    Janela agendada: 10:00 - 11:00
    Horário de chegada: 11:20

O check-in poderá ser realizado desde que:

- A reserva permaneça no estado agendado.
- A data seja a data atual.
- A doca esteja fisicamente disponível.
- O horário atual seja anterior às 17:30.
- As demais condições sejam atendidas.

Não implementar tolerância máxima de atraso
neste requisito.

Não criar regras adicionais que não estejam
definidas na especificação funcional.

O controle automático de no-show será tratado
em requisito posterior.

---

## 8. Persistência do check-in

Ao confirmar um check-in válido, atualizar:

    bookings.status = em_operacao

    bookings.checkin_at = horário atual do servidor

Utilizar:

    Time.current

Não receber o horário de check-in através
de um campo editável do navegador.

Não permitir que o frontend determine
o horário efetivo da operação.

O atributo released_at deverá permanecer
nulo durante a operação.

Registrar a atualização dentro de uma transação.

Registrar também o evento correspondente
na tabela audit_events.

A alteração do agendamento e a criação da
auditoria deverão ocorrer na mesma transação.

Caso a auditoria falhe, a operação deverá
ser revertida integralmente.

---

## 9. Ocupação física da doca

A aplicação deverá distinguir dois conceitos:

### 9.1 Reserva de horário

Representa uma posição reservada na combinação:

- Data.
- Doca.
- Janela.

### 9.2 Ocupação física

Representa um veículo efetivamente em operação
na doca.

Uma doca poderá possuir várias reservas para
diferentes horários.

Entretanto, somente poderá possuir um veículo
fisicamente em operação por vez.

Exemplo:

    Doca 01

    08:00 - 09:00 -> Veículo A
    09:00 - 10:00 -> Veículo B
    10:00 - 11:00 -> Veículo C

Se o veículo A ainda estiver em operação
às 09:15, o veículo B não poderá registrar
check-in.

O veículo B deverá aguardar a liberação
da doca.

Não cancelar ou reagendar automaticamente
a reserva do veículo B.

---

## 10. Proteção no PostgreSQL

Preservar o índice único parcial criado
no RF002 para ocupação física.

Estrutura conceitual:

    CREATE UNIQUE INDEX bookings_dock_occupation_unique
    ON bookings (dock_number)
    WHERE status = 'em_operacao';

Verificar se o índice existente está presente
e funcional.

Não criar um índice duplicado.

A proteção deverá impedir que duas transações
concorrentes coloquem veículos diferentes
em operação na mesma doca.

A validação realizada pelo Rails deverá auxiliar
na apresentação de mensagens compreensíveis.

O PostgreSQL deverá permanecer como proteção
definitiva contra ocupação simultânea.

Não utilizar exclusivamente:

- Validações JavaScript.
- Consultas anteriores à transação.
- Variáveis em memória.
- Mutex Ruby.
- Estado visual da interface.

---

## 11. Check-ins concorrentes

Considerar o cenário:

    Operador A registra o check-in do veículo A.

    Operador B registra simultaneamente o check-in
    do veículo B.

    Ambos os veículos possuem a mesma doca.

Resultado esperado:

- Somente um check-in poderá ser confirmado.
- Somente um veículo poderá ficar em operação.
- A segunda operação deverá ser rejeitada.
- Não deverá existir auditoria de sucesso
  para a operação rejeitada.

Apresentar uma mensagem:

    Esta doca já está ocupada por outro veículo.
    Aguarde a liberação antes de registrar
    um novo check-in.

Tratar adequadamente as violações de unicidade
do PostgreSQL.

Não apresentar mensagens SQL ou páginas de
erro interno para conflitos operacionais.

Não repetir automaticamente uma operação que
tenha sido rejeitada por conflito de capacidade.

---

## 12. Liberação de veículos

### 12.1 Objetivo

Permitir encerrar uma operação em andamento
e liberar fisicamente a doca.

### 12.2 Botão

Disponibilizar o botão:

    Liberar doca

O botão deverá estar disponível exclusivamente
para reservas no estado:

    em_operacao

Não permitir liberação para reservas:

- agendado
- liberado
- cancelado
- reagendamento

### 12.3 Confirmação

Ao selecionar a ação, apresentar uma interface
simples para informar a observação da liberação.

Exemplo:

    Liberar doca

    Protocolo: DA-XXXXXXXX
    Placa: ABC1D23
    Doca: 03

    Check-in: 10:05

    Observação da liberação:

    [____________________________________]
    [____________________________________]

    [Voltar] [Confirmar liberação]

Utilizar formulário Rails.

Não implementar uma estrutura frontend
independente.

---

## 13. Observação da liberação

A observação será obrigatória.

Utilizar o atributo existente:

    bookings.release_remark

Regras:

- Mínimo de 3 caracteres úteis.
- Máximo de 500 caracteres.
- Remover espaços desnecessários nas extremidades.
- Não aceitar conteúdo composto somente por espaços.
- Aceitar caracteres acentuados.
- Tratar o conteúdo como texto simples.

Exemplo:

    Operação concluída sem ocorrências.

Não interpretar a observação como HTML.

Validar os limites no backend.

Não depender exclusivamente de maxlength
ou outras validações HTML.

Apresentar mensagens de erro próximas
ao campo correspondente.

---

## 14. Persistência da liberação

Ao confirmar uma liberação válida, atualizar:

    bookings.status = liberado

    bookings.released_at = horário atual do servidor

    bookings.release_remark = observação informada

Preservar o horário original de check-in.

Não permitir que o horário de liberação
seja anterior ao horário de check-in.

Utilizar optimistic locking.

Registrar a operação em uma transação.

Criar o evento de auditoria na mesma transação.

Não permitir uma segunda liberação para
uma reserva já liberada.

Não sobrescrever os horários anteriormente
registrados.

---

## 15. Liberação após o expediente

O limite de entrada às 17:30 aplica-se
exclusivamente ao check-in.

A liberação de um veículo que esteja em operação
deverá continuar disponível após:

- 17:30.
- 17:48.
- Meia-noite.
- Mudança de data.

Exemplo:

    Check-in: 17:20
    Liberação: 18:15

A liberação deverá ser permitida.

Registrar o horário real do encerramento.

Não ajustar artificialmente o horário
de liberação para 17:48.

Não encerrar operações automaticamente
no final do expediente.

---

## 16. Disponibilidade após a liberação

A liberação deverá tornar a doca fisicamente
disponível para outro veículo.

Entretanto, a janela originalmente reservada
deverá continuar consumindo capacidade.

Exemplo:

    Doca 01
    Janela: 10:00 - 11:00

    Check-in: 10:00
    Liberação: 10:25

Resultado:

- A doca fica fisicamente desocupada.
- A reserva permanece no estado liberado.
- A janela das 10:00 - 11:00 não é disponibilizada
  para uma segunda reserva.

Preservar as regras de capacidade implementadas
nos requisitos anteriores.

Não excluir o agendamento após a liberação.

Não modificar o horário originalmente reservado.

---

## 17. Atualização do painel administrativo

Após um check-in ou uma liberação bem-sucedida,
atualizar as informações apresentadas no painel.

### 17.1 Check-in

Alterar a representação da reserva para:

    Em operação

Utilizar o padrão visual amarelo ou laranja
já existente no painel.

### 17.2 Liberação

Alterar a representação da reserva para:

    Liberado

Utilizar o padrão visual verde já existente.

### 17.3 Matriz

A posição correspondente deverá apresentar
o estado atualizado do agendamento.

Não criar uma nova matriz.

Não reconstruir o Dashboard.

Reutilizar os componentes existentes.

### 17.4 Indicadores

Preservar o cálculo dos indicadores existentes.

Reservas nos estados em_operacao e liberado
continuam consumindo capacidade.

A liberação não deverá aumentar indevidamente
a quantidade de horários disponíveis.

---

## 18. Operação com horário excedido

Quando uma reserva estiver no estado:

    em_operacao

e o horário atual alcançar ou ultrapassar
o horário final da janela agendada, apresentar
um destaque visual.

Exemplo:

    Em operação — Horário excedido

Utilizar o vermelho como indicação de atenção.

Para a última janela, considerar o horário:

    17:48

O cálculo deverá considerar:

- Data originalmente agendada.
- Horário final da janela.
- Fuso America/Sao_Paulo.
- Horário atual do servidor.

Não comparar somente o horário do relógio
ignorando a data do agendamento.

O destaque visual não deverá alterar
o status armazenado no banco.

A reserva continuará com status:

    em_operacao

Não liberar a doca automaticamente.

Não criar um novo status para representar atraso.

Neste requisito, o destaque poderá ser atualizado
nas consultas normais e na atualização manual
do painel.

A atualização automática será implementada
posteriormente.

---

## 19. Horários efetivos

Na página de detalhes do agendamento,
apresentar separadamente:

### Horário agendado

    10:00 - 11:00

### Check-in

    10:05

### Liberação

    10:48

Quando um evento ainda não tiver ocorrido,
apresentar:

    Não registrado

Exibir os horários no fuso operacional
da aplicação.

Quando o evento ocorrer em uma data diferente
da data agendada, apresentar também a data
efetiva do evento.

Não sobrescrever os horários originalmente
definidos no agendamento.

---

## 20. Auditoria

Utilizar a tabela existente:

    audit_events

Registrar um evento para cada operação
confirmada com sucesso.

### 20.1 Evento de check-in

Utilizar:

    entity_type: Booking
    entity_id: ID da reserva
    action: checkin

Registrar em previous_values os valores
operacionais anteriores.

Registrar em new_values os valores atualizados.

Exemplo conceitual:

    previous_values:
        status: agendado
        checkin_at: null

    new_values:
        status: em_operacao
        checkin_at: horário efetivo

### 20.2 Evento de liberação

Utilizar:

    entity_type: Booking
    entity_id: ID da reserva
    action: release

Registrar:

- Status anterior.
- Novo status.
- Horário de liberação.
- Observação da liberação.

### 20.3 Integridade

A auditoria deverá ser criada na mesma transação
da alteração do agendamento.

Não criar eventos de sucesso para operações
rejeitadas.

Não duplicar eventos em requisições repetidas.

Não registrar:

- Credenciais.
- Tokens.
- Cookies.
- Parâmetros completos da requisição.
- Informações pessoais desnecessárias.

Não implementar identificação individual
de operadores neste requisito.

A identificação será adicionada posteriormente,
quando forem implementados os usuários.

---

## 21. Rotas administrativas

Criar as rotas necessárias dentro do namespace
administrativo existente.

Estrutura sugerida:

    PATCH /admin/bookings/:id/checkin

    PATCH /admin/bookings/:id/release

Utilizar os padrões REST e os recursos
nativos do Rails.

Não utilizar requisições GET para alterar
o estado de reservas.

Não criar APIs JSON exclusivamente para
realizar essas operações.

Utilizar formulários Rails com proteção CSRF.

Preservar as rotas administrativas existentes.

---

## 22. Organização do backend

Analisar a estrutura atual do projeto.

Implementar as operações mantendo os
controllers pequenos e organizados.

Centralizar as regras de check-in e liberação.

Utilizar métodos de domínio ou services
específicos quando necessário.

Exemplo conceitual:

    Booking
        |
        +-- Regras de check-in
        |
        +-- Regras de liberação

Não criar abstrações genéricas sem necessidade.

Não implementar uma biblioteca externa
de state machine.

Não criar callbacks complexos que alterem
automaticamente o status de reservas.

As transições deverão ser explícitas,
previsíveis e testáveis.

Reutilizar as definições existentes de
docas e janelas.

Não duplicar as definições operacionais.

---

## 23. Tratamento de erros

Apresentar mensagens claras em português.

### Check-in antecipado

    O horário agendado ainda não foi iniciado.

### Data incorreta

    O check-in somente pode ser realizado
    na data do agendamento.

### Doca ocupada

    Esta doca está ocupada.
    Aguarde a liberação do veículo anterior.

### Limite operacional

    O horário limite para check-in é 17:30.

### Status incompatível

    O estado atual do agendamento não permite
    realizar esta operação.

### Observação inválida

    Informe uma observação de liberação válida.

### Conflito de versão

    Este agendamento foi atualizado por outra
    operação. Consulte os dados atualizados
    antes de continuar.

Preservar os dados preenchidos em caso de erro.

Não exibir mensagens internas do PostgreSQL.

Não expor stack traces ou informações
de infraestrutura.

Utilizar respostas HTTP adequadas para
validações, conflitos e registros inexistentes.

---

## 24. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Utilizar Strong Parameters.

Para o check-in, aceitar somente os parâmetros
necessários à identificação do registro e
ao controle de versão.

Para a liberação, aceitar:

- release_remark
- lock_version

Não permitir que o navegador determine:

- status
- checkin_at
- released_at
- dock_number
- booking_date
- slot_number
- protocol

Esses atributos deverão permanecer sob
controle do backend.

Não confiar no estado informado pelo frontend.

Reconsultar e validar o registro antes
de realizar qualquer alteração.

Manter proteção CSRF habilitada.

Preservar a Content Security Policy.

Utilizar escaping padrão do ERB.

Não utilizar raw ou html_safe para apresentar
observações fornecidas pelo operador.

Não implementar autenticação provisória.

Não criar credenciais fixas.

Manter todas as rotas administrativas restritas
ao ambiente de desenvolvimento e teste.

Não disponibilizar as ações operacionais
em produção antes da implementação definitiva
de autenticação e autorização.

---

## 25. JavaScript

Utilizar o mínimo possível de JavaScript.

Priorizar:

- HTML.
- CSS.
- ERB.
- Formulários Rails.
- Turbo, quando necessário.
- Stimulus, somente quando justificado.

Não utilizar JavaScript para determinar:

- Permissão para realizar check-in.
- Horário permitido.
- Disponibilidade física da doca.
- Status do agendamento.
- Horário de entrada.
- Horário de saída.
- Validade da operação.
- Controle de concorrência.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Handlers JavaScript inline.
- Scripts de CDNs.

Não enfraquecer a CSP para facilitar
a implementação.

Não introduzir novas dependências frontend.

---

## 26. Banco de dados

Utilizar a estrutura criada no RF002.

Atributos existentes:

    bookings.status
    bookings.checkin_at
    bookings.released_at
    bookings.release_remark
    bookings.lock_version

Utilizar também:

    audit_events

Não criar novas tabelas neste requisito.

Não criar migrations desnecessárias.

Não modificar migrations já aplicadas.

Caso seja identificada alguma ausência de
constraint indispensável, documentar o problema.

Criar uma nova migration somente quando
necessária para garantir uma regra deste RF.

Preservar os índices existentes.

Não excluir ou modificar dados históricos
para facilitar a implementação.

---

## 27. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 27.1 Check-in válido

Validar:

- Reserva agendada.
- Data correspondente ao dia atual.
- Horário igual ao início da janela.
- Horário posterior ao início da janela.
- Doca disponível.
- Versão atualizada.
- Alteração para em_operacao.
- Persistência de checkin_at.
- Criação do evento de auditoria.

### 27.2 Check-in inválido

Validar a rejeição de:

- Reserva cancelada.
- Reserva liberada.
- Reserva em operação.
- Reserva em reagendamento.
- Reserva de data anterior.
- Reserva de data futura.
- Check-in antes das 08:00.
- Check-in antes do início da janela.
- Check-in às 17:30.
- Check-in após 17:30.
- Check-in em doca ocupada.
- Check-in com lock_version desatualizado.
- Registro inexistente.

### 27.3 Limites de horário

Validar:

    07:59:59 -> Rejeitado
    08:00:00 -> Permitido na primeira janela
    17:29:59 -> Permitido, se elegível
    17:30:00 -> Rejeitado
    17:48:00 -> Rejeitado

Utilizar controle de tempo nos testes.

Considerar o fuso America/Sao_Paulo.

### 27.4 Chegada atrasada

Validar:

- Chegada após o término da janela.
- Doca fisicamente disponível.
- Horário anterior às 17:30.
- Aceitação do check-in.

Validar também a rejeição quando a doca
estiver ocupada.

### 27.5 Liberação válida

Validar:

- Reserva em operação.
- Observação válida.
- Alteração para liberado.
- Persistência de released_at.
- Persistência de release_remark.
- Preservação do horário de check-in.
- Criação da auditoria.
- Liberação física da doca.
- Preservação da capacidade da janela original.

### 27.6 Liberação inválida

Validar a rejeição de:

- Reserva ainda agendada.
- Reserva já liberada.
- Reserva cancelada.
- Reserva em reagendamento.
- Observação ausente.
- Observação composta somente por espaços.
- Observação inferior a 3 caracteres.
- Observação superior a 500 caracteres.
- Versão desatualizada.
- Horário de liberação anterior ao check-in.

### 27.7 Liberação após expediente

Validar:

- Liberação após 17:30.
- Liberação após 17:48.
- Liberação no dia seguinte.

### 27.8 Concorrência

Realizar testes com conexões independentes
ao PostgreSQL.

Validar:

- Dois veículos tentando ocupar a mesma doca.
- Dois check-ins simultâneos da mesma reserva.
- Duas liberações simultâneas da mesma reserva.
- Requisições com lock_version desatualizado.
- Ausência de auditorias duplicadas.

Somente operações válidas poderão ser persistidas.

Não simular concorrência apenas através
de operações sequenciais.

### 27.9 Auditoria e transações

Simular falha na gravação da auditoria.

Validar que:

- O check-in é revertido integralmente.
- A liberação é revertida integralmente.
- O status anterior permanece preservado.
- Os horários não são gravados parcialmente.

### 27.10 Horário excedido

Validar:

- Operação dentro do horário.
- Operação no instante final da janela.
- Operação após o término da janela.
- Última janela excedida a partir das 17:48.
- Operação excedida de data anterior.
- Reserva liberada sem indicação de atraso ativo.

### 27.11 Segurança

Validar:

- Manipulação de status pelo navegador.
- Manipulação do horário de check-in.
- Manipulação do horário de liberação.
- Manipulação do número da doca.
- Tentativa de XSS na observação.
- Proteção CSRF efetivamente habilitada no teste.
- Preservação da Content Security Policy.
- Indisponibilidade das rotas em produção.

### 27.12 Regressão

Executar todos os testes existentes dos
RF001, RF002, RF003 e RF004.

Não remover ou enfraquecer testes anteriores.

---

## 28. Validação manual

Realizar uma homologação utilizando
o ambiente Docker de desenvolvimento.

Cenário principal:

1. Criar um agendamento pelo formulário público.
2. Localizar o agendamento no painel administrativo.
3. Acessar seus detalhes.
4. Registrar um check-in válido.
5. Verificar o status Em operação.
6. Verificar o horário registrado.
7. Tentar registrar outro veículo na mesma doca.
8. Confirmar que a segunda operação é impedida.
9. Registrar a liberação do primeiro veículo.
10. Informar uma observação.
11. Verificar o status Liberado.
12. Verificar o horário de liberação.
13. Confirmar a possibilidade de check-in
    do segundo veículo, se elegível.
14. Verificar os eventos de auditoria.
15. Verificar a atualização da matriz.
16. Verificar os indicadores do Dashboard.

Utilizar dados fictícios e horários controlados
em ambiente de teste quando necessário.

Não alterar o relógio do sistema operacional
para simular horários.

Verificar o console do navegador.

Não deverão existir:

- Erros JavaScript.
- Violações inesperadas de CSP.
- Links quebrados.
- Erros de carregamento.
- Componentes sobrepostos.

---

## 29. Documentação

Registrar este requisito em:

    docs/requisitos/RF005.md

Atualizar o índice de requisitos.

Documentar:

- Fluxo de check-in.
- Fluxo de liberação.
- Transições permitidas.
- Horários operacionais.
- Controle de ocupação física.
- Controle de concorrência.
- Auditoria.
- Rotas administrativas adicionadas.
- Tratamento de horários excedidos.
- Limitações existentes.

Atualizar a documentação do banco caso
alguma alteração estrutural seja necessária.

Criar ADR somente quando existir uma
decisão arquitetural relevante.

---

## 30. Critérios de aceite

### Check-in

- [ ] Botão Registrar check-in implementado.
- [ ] Confirmação de check-in implementada.
- [ ] Status atualizado para em_operacao.
- [ ] Horário registrado pelo servidor.
- [ ] Check-in permitido somente na data agendada.
- [ ] Check-in antecipado impedido.
- [ ] Check-in a partir das 17:30 impedido.
- [ ] Chegada atrasada tratada conforme as regras.
- [ ] Ocupação simultânea da mesma doca impedida.
- [ ] Controle de concorrência funcional.

### Liberação

- [ ] Botão Liberar doca implementado.
- [ ] Observação obrigatória.
- [ ] Limite de caracteres validado.
- [ ] Status atualizado para liberado.
- [ ] Horário real de liberação registrado.
- [ ] Horário original de check-in preservado.
- [ ] Liberação após expediente permitida.
- [ ] Liberação duplicada impedida.
- [ ] Doca fisicamente desocupada após liberação.
- [ ] Slot original continua consumindo capacidade.

### Painel administrativo

- [ ] Layout aprovado no RF004 preservado.
- [ ] Seção Controle operacional implementada.
- [ ] Estados da reserva atualizados corretamente.
- [ ] Horários efetivos apresentados.
- [ ] Operações com horário excedido destacadas.
- [ ] Matriz atualizada corretamente.
- [ ] Indicadores permanecem consistentes.

### Auditoria

- [ ] Evento de check-in registrado.
- [ ] Evento de liberação registrado.
- [ ] Valores anteriores e posteriores registrados.
- [ ] Auditoria executada na mesma transação.
- [ ] Rollback validado.
- [ ] Auditorias duplicadas impedidas.

### Segurança

- [ ] Strong Parameters utilizado.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Horários controlados exclusivamente pelo servidor.
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
- [ ] Testes anteriores aprovados.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.
- [ ] Console do navegador sem erros inesperados.
- [ ] Documentação atualizada.

---

## 31. Fora do escopo

Não implementar neste requisito:

- Cancelamento de agendamentos.
- Reagendamento.
- Alteração de docas.
- Alteração de horários agendados.
- Bloqueio de docas.
- Desbloqueio de docas.
- Fechamento automático de no-show.
- Tolerância máxima de atraso.
- Atualização automática do Dashboard.
- Polling.
- WebSockets.
- QR Code.
- Check-in através de QR Code.
- Geolocalização.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis e permissões.
- Exportação Excel.
- Notificações por e-mail.
- Upload de documentos.
- Active Storage.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente o controle operacional
de check-in e liberação.

---

## 32. Entrega

Ao concluir o RF005, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Interface

- Componentes adicionados.
- Botões implementados.
- Screenshots dos estados operacionais.
- Screenshot da confirmação de check-in.
- Screenshot da confirmação de liberação.

### Backend

- Rotas criadas.
- Controllers modificados.
- Models modificados.
- Services criados, quando aplicável.
- Regras operacionais implementadas.
- Estratégia de concorrência.
- Estratégia de auditoria.

### Banco de dados

- Constraints utilizadas.
- Índices utilizados.
- Eventuais migrations e justificativas.

### Segurança

- Proteções preservadas.
- Proteções adicionadas.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Riscos e limitações identificados.

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

Não inventar resultados.

### Repositório

Apresentar:

    git status --short

### Pendências

Informar qualquer problema ou limitação
que necessite de homologação.

---

## 33. Regra de parada

Ao concluir o RF005, PARE.

Não implementar cancelamento.

Não implementar reagendamento.

Não implementar autenticação ou autorização.

Não alterar o layout administrativo aprovado.

Não avançar automaticamente para o RF006.

Aguardar homologação do controle operacional.