# RF008 — Controle de Atrasos e No-show Automático

## 1. Objetivo

Implementar o controle automático de não comparecimento
de veículos na aplicação DSV Doca Agenda.

Permitir que o sistema identifique:

- Agendamentos aguardando chegada.
- Veículos atrasados.
- Veículos em operação com horário excedido.
- Veículos que não realizaram check-in até o limite.
- Agendamentos pendentes de reagendamento.

Automatizar a transição de reservas elegíveis para
o estado reagendamento.

Preservar todas as funcionalidades implementadas
até o RF007.

Não modificar o layout administrativo aprovado.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

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
- docs/requisitos/RF006.md
- docs/requisitos/RF007.md
- docs/referencias/

Analisar a implementação existente.

Reutilizar os services, models, controllers, helpers
e componentes existentes sempre que possível.

Preservar a arquitetura monolítica Ruby on Rails.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Definições operacionais

Preservar os horários existentes:

    Início da operação:       08:00
    Limite de check-in:       17:30
    Última janela encerra:    17:48

Utilizar o fuso operacional:

    America/Sao_Paulo

Utilizar o relógio do servidor como fonte de verdade.

Não utilizar o relógio do navegador para determinar
transições operacionais.

Não modificar a quantidade de docas ou janelas.

Preservar:

    8 docas físicas
    10 janelas de horários

---

## 4. Estados dos agendamentos

Preservar os estados existentes:

    agendado
    em_operacao
    liberado
    cancelado
    reagendamento

Não criar novos estados no banco de dados.

A classificação de atraso deverá ser calculada
dinamicamente.

Neste RF, implementar a transição automática:

    agendado -> reagendamento

Não realizar automaticamente outras transições.

---

## 5. Classificações operacionais

Distinguir os seguintes conceitos:

### 5.1 Aguardando chegada

Reserva com status agendado cujo horário inicial
ainda não foi alcançado.

### 5.2 Aguardando check-in

Reserva com status agendado cujo horário inicial
já foi alcançado, mas cuja janela ainda não terminou.

### 5.3 Chegada atrasada

Reserva com status agendado cuja janela original
já terminou, mas que ainda pode realizar check-in
conforme as regras operacionais.

### 5.4 Operação com horário excedido

Reserva com status em_operacao cujo horário final
da janela foi alcançado ou ultrapassado.

Preservar a implementação existente do RF005.

### 5.5 No-show

Reserva com status agendado que não realizou
check-in até o limite operacional permitido.

A reserva deverá ser alterada automaticamente
para reagendamento.

### 5.6 Reagendamento obrigatório

Reserva que perdeu a possibilidade de realizar
check-in e precisa receber uma nova posição.

Utilizar o estado existente:

    reagendamento

---

## 6. Controle de chegada atrasada

Uma reserva não deverá ser automaticamente
classificada como no-show apenas porque sua
janela terminou.

Exemplo:

    Data: Hoje
    Janela: 10:00 - 11:00
    Horário atual: 11:20
    Status: agendado

Resultado:

    Chegada atrasada.

O veículo ainda poderá realizar check-in
desde que:

- A data agendada seja a data atual.
- A doca esteja fisicamente disponível.
- O horário atual seja anterior às 17:30.
- As demais regras do RF005 sejam atendidas.

Não implementar tolerância máxima de atraso.

Não cancelar ou reagendar automaticamente
a reserva ao término da janela original.

---

## 7. Identificação visual de chegada atrasada

No painel administrativo, destacar reservas
que ultrapassaram o horário final da janela
sem realizar check-in.

Exemplo:

    Agendado — Chegada atrasada

Utilizar:

- Indicador visual de atenção.
- Texto identificando a condição.
- Cor vermelha ou elemento de alerta compatível
  com a identidade visual existente.

Não alterar o status persistido.

O status continuará sendo:

    agendado

O destaque deverá ser apresentado, quando adequado:

- Na matriz de docas.
- Na lista de agendamentos.
- Na página de detalhes.

Não depender exclusivamente da cor.

Não reconstruir os componentes existentes.

---

## 8. Operações com horário excedido

Preservar a regra implementada no RF005.

Uma reserva com status em_operacao deverá
apresentar um destaque quando o horário atual
alcançar ou ultrapassar o término da janela.

Exemplo:

    Janela: 10:00 - 11:00
    Check-in: 10:15
    Horário atual: 11:30

Resultado:

    Em operação — Horário excedido

O status persistido continuará sendo:

    em_operacao

Não alterar automaticamente a reserva para:

- liberado
- cancelado
- reagendamento

A liberação continuará sendo manual.

---

## 9. Regra de no-show

Uma reserva deverá ser considerada elegível
para fechamento automático quando:

- Possuir status agendado.
- Não possuir check-in registrado.
- Pertencer a uma data anterior à data atual.

OU quando:

- Possuir status agendado.
- Não possuir check-in registrado.
- Pertencer à data atual.
- O horário atual for igual ou posterior às 17:30.

A partir das 17:30:00, inclusive, a reserva
sem check-in deverá ser considerada elegível.

Não aguardar até as 17:48.

Não aguardar até a meia-noite.

Não aplicar essa regra a reservas de datas futuras.

---

## 10. Exemplos de no-show

### Cenário 01

    Data: Hoje
    Janela: 08:00 - 09:00
    Horário atual: 15:00
    Status: agendado

Resultado:

    Permanece agendado.
    Apresenta indicação de chegada atrasada.
    Ainda pode realizar check-in, se elegível.

### Cenário 02

    Data: Hoje
    Janela: 08:00 - 09:00
    Horário atual: 17:29:59
    Status: agendado

Resultado:

    Permanece agendado.

### Cenário 03

    Data: Hoje
    Janela: 08:00 - 09:00
    Horário atual: 17:30:00
    Status: agendado

Resultado:

    Elegível para alteração automática
    para reagendamento.

### Cenário 04

    Data: Hoje
    Janela: 17:00 - 17:48
    Horário atual: 17:30
    Status: agendado

Resultado:

    Elegível para reagendamento.

### Cenário 05

    Data: Amanhã
    Janela: 08:00 - 09:00
    Horário atual: 18:00
    Status: agendado

Resultado:

    Permanece agendado.

### Cenário 06

    Data: Ontem
    Status: agendado

Resultado:

    Elegível para reagendamento,
    independentemente do horário atual.

---

## 11. Proteção de veículos em operação

Reservas com status em_operacao não deverão
ser afetadas pelo processamento de no-show.

Exemplo:

    Check-in: 17:20
    Horário atual: 18:30
    Status: em_operacao

Resultado:

    Permanece em_operacao.

A doca deverá continuar fisicamente ocupada.

A liberação deverá continuar disponível,
conforme RF005.

Não encerrar automaticamente operações
no final do expediente.

Não liberar automaticamente a doca.

Não alterar horários efetivamente registrados.

---

## 12. Estados protegidos

O processamento automático não deverá alterar
reservas nos estados:

    em_operacao
    liberado
    cancelado
    reagendamento

Também não deverá alterar reservas agendadas
para datas futuras.

Caso seja identificada uma reserva com status
agendado e checkin_at preenchido, não corrigir
silenciosamente a inconsistência.

Registrar a ocorrência de forma segura para
análise técnica.

---

## 13. Persistência do no-show

Ao processar uma reserva elegível, atualizar:

    bookings.status = reagendamento

    bookings.change_reason =
        Não comparecimento até o horário limite de check-in.

Utilizar uma mensagem consistente para o motivo
automático.

Preservar:

- ID interno.
- Protocolo.
- Request ID.
- Nome do responsável.
- Empresa.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Tipo de operação.
- Data originalmente agendada.
- Doca originalmente agendada.
- Janela originalmente agendada.
- Data de criação.

Não gerar uma nova reserva.

Não excluir a reserva original.

Não preencher checkin_at.

Não preencher released_at.

Atualizar updated_at e lock_version utilizando
os mecanismos nativos do Rails.

---

## 14. Disponibilidade após no-show

Reservas com status reagendamento não consomem
capacidade.

Preservar essa regra estrutural.

Entretanto, como o no-show será identificado
a partir das 17:30 ou em datas anteriores,
não apresentar automaticamente a posição
original como disponível para novos agendamentos.

A disponibilidade continuará dependendo:

- Da data.
- Do horário inicial da janela.
- Do horizonte permitido.
- Dos bloqueios existentes.
- Das demais reservas.

Reutilizar o motor de disponibilidade existente.

Não modificar as regras de disponibilidade
implementadas nos RFs anteriores.

---

## 15. Processamento automático

O processamento de no-show deverá acontecer
automaticamente no backend.

Não depender de:

- Acesso ao Dashboard.
- Acesso ao formulário público.
- Navegador aberto.
- JavaScript.
- Atualização manual da página.
- Ação de um operador.
- Sessão autenticada.

O processamento deverá funcionar mesmo quando
nenhum usuário estiver utilizando a aplicação.

Não executar transições de estado como efeito
colateral de uma requisição GET.

---

## 16. Estratégia de execução

Analisar os recursos de processamento em segundo
plano disponíveis na versão do Rails utilizada
pela aplicação.

Priorizar:

- Active Job.
- Solid Queue, caso já esteja disponível
  ou seja compatível com a versão instalada.
- Mecanismo nativo de tarefas recorrentes.

Utilizar PostgreSQL para persistência das tarefas,
quando necessário.

Não introduzir:

- Redis.
- Sidekiq.
- Celery.
- Serviços externos de agendamento.
- Microsserviços.
- Aplicações independentes.

Caso a aplicação ainda não possua um mecanismo
de tarefas recorrentes, implementar a solução
mais simples e compatível com a arquitetura atual.

Documentar a estratégia escolhida e justificar
eventuais dependências adicionadas.

Não atualizar a versão do Rails exclusivamente
para implementar este requisito.

---

## 17. Frequência de processamento

Configurar a execução recorrente do processamento
de no-show a cada 1 minuto.

A regra de elegibilidade continuará utilizando
o limite exato das 17:30.

O processamento recorrente poderá efetivar
a alteração na próxima execução disponível
após esse horário.

Exemplo:

    17:29 -> Nenhuma reserva de hoje encerrada.

    17:30 -> Reservas elegíveis processadas.

    17:31 -> Nova verificação.

Não executar um agendamento independente
para cada reserva.

Utilizar uma única tarefa recorrente para
identificar os registros elegíveis.

Não implementar atualização automática da
interface neste requisito.

O processamento em segundo plano é independente
da atualização visual do Dashboard.

---

## 18. Integração com Docker

Preservar o ambiente Docker existente.

Caso o mecanismo de processamento em segundo
plano necessite de um processo independente,
permitir a criação de um serviço dedicado
no Docker Compose.

Estrutura conceitual:

    Docker Compose
        |
        +-- web
        |   Rails + Puma
        |
        +-- db
        |   PostgreSQL
        |
        +-- worker
            Processamento de tarefas Rails

O serviço worker, quando necessário, deverá:

- Utilizar o mesmo código da aplicação Rails.
- Utilizar a mesma imagem da aplicação,
  quando tecnicamente apropriado.
- Compartilhar as configurações necessárias.
- Comunicar-se com o PostgreSQL.
- Não publicar portas externas.
- Executar com usuário não root.
- Possuir encerramento adequado.
- Utilizar a política de reinicialização
  apropriada ao ambiente.

O worker não representa um microsserviço.

Ele será um processo auxiliar da mesma
aplicação monolítica.

Não adicionar Nginx ao Docker.

Não alterar as portas existentes.

Não expor a porta do PostgreSQL.

Caso a estratégia escolhida dispense um
container separado, documentar essa decisão.

---

## 19. Recuperação após indisponibilidade

O processamento não deverá depender de uma
execução exclusiva às 17:30.

Considerar:

    17:20 -> Servidor desligado.

    17:30 -> Processamento não realizado.

    19:00 -> Servidor reiniciado.

Resultado esperado:

    Na próxima execução da tarefa,
    identificar todas as reservas elegíveis
    ainda no estado agendado.

Considerar também reservas de dias anteriores.

Não perder o fechamento de no-show porque
o servidor estava indisponível.

Não depender de flags exclusivamente em memória.

Não alterar reservas futuras.

Não processar novamente reservas que já
tenham sido alteradas para reagendamento.

---

## 20. Organização do backend

Separar a regra de negócio do mecanismo
responsável por executar a tarefa recorrente.

Estrutura sugerida:

    app/jobs/
        process_no_shows_job.rb

    app/services/
        bookings/
            process_no_shows.rb

A nomenclatura poderá ser adaptada às
convenções existentes no projeto.

Responsabilidades:

### Job

- Acionar o processamento.
- Integrar com o mecanismo recorrente.
- Registrar informações técnicas da execução.

### Service

- Identificar reservas elegíveis.
- Validar estados.
- Aplicar regras temporais.
- Controlar concorrência.
- Executar transições.
- Registrar auditorias.

Não concentrar todas as regras de negócio
dentro do job.

Não criar abstrações genéricas desnecessárias.

Não duplicar as regras temporais existentes.

---

## 21. Consulta de reservas elegíveis

Utilizar consultas Active Record eficientes.

Buscar somente registros potencialmente
elegíveis para processamento.

Considerar:

    status = agendado

    checkin_at IS NULL

    booking_date anterior à data atual

Ou:

    booking_date igual à data atual

    horário atual igual ou posterior às 17:30

Não carregar todo o histórico de reservas
na memória.

Utilizar processamento em lotes quando
apropriado.

Avaliar os índices existentes.

Criar índices adicionais somente quando
houver necessidade demonstrável.

Não criar índices duplicados.

Não executar consultas diretamente nas views.

---

## 22. Transações

Processar cada reserva dentro de uma
transação independente.

Cada transação deverá incluir:

- Aquisição das travas necessárias.
- Reconsulta da reserva.
- Validação do estado atual.
- Validação temporal.
- Atualização do status.
- Atualização do motivo.
- Criação do evento de auditoria.

Caso uma reserva apresente falha,
reverter integralmente sua transação.

Não impedir necessariamente o processamento
das demais reservas elegíveis por causa
de uma falha isolada.

Registrar a falha tecnicamente.

Uma reserva que não puder ser processada
deverá continuar elegível para uma tentativa
posterior, quando apropriado.

---

## 23. Concorrência compartilhada

Reutilizar o mecanismo de travamento
implementado nos RF003, RF006 e RF007.

O processamento de no-show altera
o consumo de capacidade de uma posição.

Portanto, deverá utilizar a mesma estratégia
transacional adotada pelas operações de:

- Criação de reserva.
- Alteração.
- Reagendamento.
- Cancelamento.
- Bloqueio.
- Desbloqueio.

Não criar um mecanismo de travamento
independente e incompatível.

Utilizar a mesma ordem de aquisição das travas
estabelecida anteriormente.

Preservar o controle por lock_version.

Reconsultar a reserva após adquirir
as travas necessárias.

Não utilizar exclusivamente:

- Mutex Ruby.
- Variáveis em memória.
- Estado do navegador.
- Verificações realizadas antes da transação.

---

## 24. Concorrência com check-in

Considerar o cenário:

    Um operador inicia o registro de check-in
    próximo ao horário limite.

    Simultaneamente, o processamento automático
    identifica a reserva como elegível para no-show.

Apenas uma transição compatível poderá
ser confirmada.

### Check-in confirmado validamente primeiro

Resultado:

    A reserva permanece em_operacao.

    O processamento automático não deverá
    alterá-la para reagendamento.

### No-show confirmado primeiro

Resultado:

    A reserva passa para reagendamento.

    O check-in deverá ser rejeitado.

O horário limite do check-in deverá ser
revalidado na operação crítica do RF005.

Uma página aberta antes das 17:30 não poderá
autorizar um check-in inválido após o limite.

Não permitir estados inconsistentes.

Não criar auditorias de sucesso para operações
que tenham sido rejeitadas.

---

## 25. Concorrência com alterações administrativas

Considerar operações simultâneas de:

- Cancelamento.
- Alteração de data.
- Alteração de doca.
- Alteração de janela.
- Reagendamento.
- Processamento automático de no-show.

Exemplo:

    O processamento identifica uma reserva
    agendada para hoje.

    Um operador altera a reserva para amanhã.

    O processamento automático obtém a trava
    após a alteração administrativa.

Resultado:

    A reserva deverá ser revalidada.

    Como a nova data é futura, não deverá
    ser alterada para reagendamento.

Não utilizar dados desatualizados obtidos
antes da aquisição das travas.

Não sobrescrever alterações administrativas.

Preservar os protocolos e o histórico.

---

## 26. Idempotência do processamento

A tarefa recorrente deverá ser idempotente.

Executar a tarefa várias vezes sobre
o mesmo conjunto de reservas não poderá gerar:

- Transições duplicadas.
- Auditorias duplicadas.
- Alterações desnecessárias.
- Sobrescrita do motivo.
- Incrementos desnecessários de lock_version.

Exemplo:

    Primeira execução:

        5 reservas alteradas para reagendamento.
        5 eventos de auditoria criados.

    Segunda execução:

        0 reservas alteradas.
        0 novos eventos de auditoria.

Garantir também a segurança caso duas
instâncias da tarefa sejam executadas
simultaneamente.

Não depender exclusivamente da existência
de um único worker.

Preservar a idempotência original da criação
de reservas implementada no RF003 e RF006.

---

## 27. Auditoria de no-show

Utilizar a tabela existente:

    audit_events

Registrar um evento para cada reserva
alterada automaticamente.

Estrutura conceitual:

    entity_type: Booking

    entity_id: ID interno da reserva

    action: no_show

    reason:
        Não comparecimento até o horário limite de check-in.

    previous_values:
        status: agendado
        booking_date: data original
        dock_number: doca original
        slot_number: janela original
        change_reason: motivo anterior

    new_values:
        status: reagendamento
        change_reason: motivo automático

    created_at: horário real do processamento

Respeitar a convenção de nomenclatura existente
no projeto.

Não registrar um usuário fictício.

Não criar tabelas de usuários.

Não criar campos de autorização.

Documentar que o evento no_show é originado
pelo processamento automático do sistema.

---

## 28. Integridade da auditoria

A alteração da reserva e o registro
da auditoria deverão ocorrer na mesma transação.

Caso a criação da auditoria falhe:

- Reverter a alteração do status.
- Reverter a atualização do motivo.
- Preservar o estado original.
- Registrar a falha técnica.

Não gerar auditoria de sucesso para uma
operação que não tenha sido confirmada.

Não sobrescrever eventos anteriores.

Não excluir registros históricos.

---

## 29. Atualização do Dashboard

Preservar o Dashboard implementado
nos requisitos anteriores.

Após o processamento automático, as consultas
ao painel deverão refletir os dados atualizados.

Uma reserva em reagendamento:

- Não deverá consumir capacidade na matriz.
- Deverá permanecer na lista de agendamentos.
- Deverá apresentar o estado correspondente.
- Deverá permitir reagendamento pelo RF006.
- Deverá permitir cancelamento pelo RF006.
- Não deverá permitir check-in antes de
  receber uma nova posição válida.

Não criar uma nova matriz.

Não modificar o layout administrativo aprovado.

Não implementar polling neste requisito.

---

## 30. Indicador de reagendamentos pendentes

Adicionar um indicador operacional:

    Reagendamentos pendentes

O indicador deverá representar a quantidade
de reservas atualmente no estado:

    reagendamento

Como se trata de uma pendência operacional,
considerar todas as datas, inclusive anteriores.

Não restringir esse indicador exclusivamente
à data selecionada no Dashboard.

Identificar claramente que esse indicador
representa pendências gerais.

Não apresentar como quantidade de no-shows
do dia selecionado.

Exemplo:

    Reagendamentos pendentes: 5

Utilizar o padrão visual existente.

Preferir uma cor de atenção compatível
com a identidade visual da aplicação.

Não alterar os cálculos dos quatro
indicadores existentes.

Adaptar a organização dos cards somente
quando necessário para incluir o novo indicador.

---

## 31. Acesso aos reagendamentos pendentes

Permitir acessar as reservas pendentes
através do indicador.

Ao selecionar o card Reagendamentos pendentes,
direcionar para a lista de agendamentos existente,
aplicando o filtro:

    status = reagendamento

A consulta deverá incluir todas as datas.

Não criar uma nova página exclusivamente
para reagendamentos pendentes.

Reutilizar os filtros existentes.

Garantir que reservas de datas anteriores
não sejam ocultadas pelo filtro padrão
de data atual.

---

## 32. Lista de agendamentos

Preservar a lista existente.

Apresentar o status:

    Reagendamento obrigatório

para reservas com status reagendamento.

Permitir identificar:

- Protocolo.
- Data originalmente agendada.
- Doca.
- Janela.
- Empresa.
- Placa.
- Motivo da necessidade de reagendamento.

Preservar as funcionalidades de:

- Filtros.
- Paginação.
- Ordenação.
- Consulta de detalhes.

Não apresentar o motivo interno no formulário
público.

---

## 33. Página de detalhes

Quando uma reserva estiver no estado
reagendamento, apresentar uma mensagem clara.

Exemplo:

    Reagendamento obrigatório

    O veículo não realizou check-in até
    o horário limite de entrada.

    É necessário selecionar uma nova data,
    doca e janela de horário.

Exibir:

- Motivo registrado.
- Data originalmente agendada.
- Doca original.
- Janela original.

Reutilizar os botões existentes do RF006:

    Reagendar

    Cancelar agendamento

Não criar um segundo fluxo de reagendamento.

Não implementar reagendamento automático.

---

## 34. Reagendamento após no-show

Utilizar a funcionalidade implementada
no RF006.

Após o operador selecionar uma nova
posição válida:

    reagendamento -> agendado

Preservar:

- ID interno.
- Protocolo.
- Request ID.
- Dados cadastrais.
- Histórico.
- Auditoria de no-show.

A nova posição deverá respeitar todas
as regras de disponibilidade.

Não preencher horários efetivos de operação.

O veículo deverá realizar check-in normalmente
na nova data.

O evento original de no-show deverá continuar
disponível na auditoria.

Caso a reserva não compareça novamente,
permitir que o processamento registre
um novo evento de no-show correspondente
à nova ocorrência.

Não impedir novos eventos legítimos apenas
porque a reserva já sofreu no-show anteriormente.

---

## 35. Logs do processamento

Registrar informações técnicas suficientes
para acompanhar a execução.

Exemplo conceitual:

    Processamento de no-show iniciado.

    Reservas elegíveis: 8

    Reservas processadas: 7

    Reservas ignoradas após revalidação: 1

    Falhas: 0

    Processamento concluído.

Registrar:

- Horário da execução.
- Quantidade de registros elegíveis.
- Quantidade processada.
- Quantidade ignorada.
- Quantidade de falhas.
- Identificação técnica da tarefa.

Não registrar:

- Nome do responsável.
- Nota fiscal.
- Placa.
- Empresa.
- Dados pessoais desnecessários.
- Credenciais.
- Tokens.

Evitar excesso de mensagens repetitivas
quando não existirem reservas elegíveis.

---

## 36. Tratamento de falhas

Caso o PostgreSQL esteja temporariamente
indisponível, não considerar o processamento
como concluído com sucesso.

Utilizar os mecanismos de tratamento
de falhas da solução de tarefas adotada.

Evitar:

- Repetições infinitas imediatas.
- Consumo excessivo de recursos.
- Transações mantidas abertas.
- Bloqueios indefinidos.
- Auditorias duplicadas.

Utilizar tentativas limitadas e intervalos
adequados quando aplicável.

A próxima execução recorrente deverá
continuar verificando reservas elegíveis.

Não ignorar silenciosamente erros.

Não alterar registros inconsistentes
sem uma regra definida.

---

## 37. Banco de dados

Reutilizar as tabelas:

    bookings
    slot_blocks
    audit_events

Não criar uma tabela de no-shows.

Não criar uma tabela de atrasos.

Não criar uma tabela de histórico duplicada.

Não adicionar um novo status.

Não adicionar campos redundantes como:

    is_late
    is_no_show
    requires_reschedule

Essas condições deverão ser representadas
pelos estados existentes ou calculadas
dinamicamente.

Caso sejam necessárias tabelas internas
para o mecanismo de processamento Rails,
permitir exclusivamente as estruturas
técnicas indispensáveis.

Documentar a finalidade dessas tabelas.

Não modificar migrations anteriormente
aplicadas.

Não excluir volumes ou dados existentes.

---

## 38. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Não criar uma rota pública para executar
o processamento de no-show.

Não criar endpoints administrativos
desnecessários para disparar a tarefa.

Não permitir que o participante informe
ou altere o horário de processamento.

Não aceitar parâmetros externos para
determinar quais reservas devem sofrer
no-show automaticamente.

Não desabilitar CSRF.

Não enfraquecer a Content Security Policy.

Preservar o escaping padrão do ERB.

Não implementar:

- Cadastro de usuários.
- Login.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.

Manter as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

---

## 39. JavaScript

Não utilizar JavaScript para executar
o processamento automático de no-show.

Não utilizar:

    setInterval

ou:

    setTimeout

como mecanismo responsável por alterar
estados de agendamentos.

Não criar temporizadores no navegador
para executar transições operacionais.

Os estados deverão ser determinados
pelo backend Rails.

A utilização de JavaScript deverá permanecer
restrita aos componentes visuais existentes.

Não implementar atualização automática
do Dashboard neste requisito.

---

## 40. Testes automatizados

Utilizar Minitest e PostgreSQL.

Utilizar controle de tempo nos testes.

Não alterar o relógio do sistema operacional.

### 40.1 Limites de horário

Validar:

    17:29:59 -> Não processar reserva de hoje.

    17:30:00 -> Processar reserva elegível.

    17:30:01 -> Processar reserva elegível.

    17:48:00 -> Processar reserva elegível.

    23:59:59 -> Processar reserva elegível.

### 40.2 Datas

Validar:

- Reserva de hoje antes das 17:30.
- Reserva de hoje após as 17:30.
- Reserva de ontem.
- Reserva de vários dias anteriores.
- Reserva de amanhã.
- Reserva de depois de amanhã.
- Virada de dia.
- Fuso America/Sao_Paulo.

### 40.3 Estados

Validar:

- agendado elegível é alterado.
- em_operacao permanece inalterado.
- liberado permanece inalterado.
- cancelado permanece inalterado.
- reagendamento permanece inalterado.

### 40.4 Chegada atrasada

Validar:

- Janela encerrada antes das 17:30.
- Reserva permanece agendada.
- Indicação visual de chegada atrasada.
- Check-in continua permitido, se elegível.

### 40.5 Operação excedida

Validar:

- Operação ultrapassando a janela.
- Operação após 17:30.
- Operação após 17:48.
- Operação iniciada em data anterior.
- Preservação da ocupação física.
- Liberação manual continua disponível.

### 40.6 Persistência

Validar:

- Alteração para reagendamento.
- Motivo automático registrado.
- Protocolo preservado.
- Request ID preservado.
- Data original preservada.
- Doca original preservada.
- Janela original preservada.
- Dados cadastrais preservados.
- Atualização de lock_version.

### 40.7 Auditoria

Validar:

- Evento no_show criado.
- Valores anteriores registrados.
- Novos valores registrados.
- Motivo registrado.
- Horário real do processamento.
- Rollback em caso de falha da auditoria.

### 40.8 Idempotência

Validar:

- Execução repetida da tarefa.
- Ausência de auditorias duplicadas.
- Ausência de atualizações desnecessárias.
- Preservação do motivo.
- Preservação de lock_version após
  execuções sem alteração.

### 40.9 Concorrência

Utilizar conexões independentes
e transações efetivamente concorrentes.

Validar:

- Duas tarefas de no-show simultâneas.
- No-show concorrente com check-in.
- No-show concorrente com cancelamento.
- No-show concorrente com alteração.
- No-show concorrente com reagendamento.

Garantir que somente transições compatíveis
sejam confirmadas.

### 40.10 Recuperação

Validar:

- Processamento executado após o horário limite.
- Processamento executado no dia seguinte.
- Processamento de pendências acumuladas.
- Reservas futuras preservadas.
- Ausência de processamento duplicado.

### 40.11 Integração da tarefa recorrente

Validar:

- Job executável.
- Configuração recorrente funcional.
- Processamento independente de requisições HTTP.
- Funcionamento sem navegador aberto.
- Inicialização do mecanismo de tarefas.
- Recuperação após reinicialização.

Não considerar suficiente apenas testar
a chamada direta do service.

Validar também a execução recorrente
efetivamente configurada.

### 40.12 Dashboard

Validar:

- Indicação de chegada atrasada.
- Indicação de operação excedida.
- Indicador de reagendamentos pendentes.
- Contagem de pendências de dias anteriores.
- Filtro de reagendamentos.
- Acesso aos detalhes.
- Reutilização das ações do RF006.
- Indicadores anteriores preservados.

### 40.13 Reagendamento após no-show

Validar:

- Retorno para agendado.
- Preservação do protocolo.
- Preservação da auditoria anterior.
- Possibilidade de check-in na nova data.
- Possibilidade de nova ocorrência legítima
  de no-show após outro reagendamento.

### 40.14 Segurança e regressão

Executar todos os testes existentes
dos RF001 até RF007.

Validar:

- Ausência de endpoints públicos
  de processamento automático.
- Proteção CSRF preservada.
- Content Security Policy preservada.
- Rotas administrativas indisponíveis
  em produção.
- Ausência de exposição de dados internos.

Não remover ou enfraquecer testes anteriores.

---

## 41. Validação manual

### Cenário 01 — Chegada atrasada

1. Preparar uma reserva elegível para teste.
2. Simular horário posterior ao fim da janela.
3. Manter o horário anterior às 17:30.
4. Verificar a indicação de atraso.
5. Confirmar que a reserva permanece agendada.
6. Confirmar a possibilidade de check-in.

### Cenário 02 — No-show

1. Preparar uma reserva sem check-in.
2. Executar o processamento com horário controlado.
3. Verificar a alteração para reagendamento.
4. Verificar o motivo.
5. Verificar a auditoria.
6. Verificar o indicador de pendências.
7. Acessar a lista de reagendamentos.

### Cenário 03 — Veículo em operação

1. Preparar uma reserva em operação.
2. Simular horário posterior às 17:30.
3. Executar o processamento.
4. Confirmar que a reserva permanece em operação.
5. Confirmar que a doca permanece ocupada.
6. Realizar a liberação manual.

### Cenário 04 — Datas futuras

1. Criar reservas para amanhã.
2. Simular horário posterior às 17:30 de hoje.
3. Executar o processamento.
4. Confirmar que as reservas futuras
   permanecem agendadas.

### Cenário 05 — Recuperação

1. Preparar reservas pendentes de datas anteriores.
2. Inicializar o ambiente de processamento.
3. Confirmar a execução da tarefa recorrente.
4. Verificar o processamento das pendências.
5. Confirmar a ausência de auditorias duplicadas.

### Cenário 06 — Reagendamento

1. Localizar uma reserva em reagendamento.
2. Selecionar uma nova posição válida.
3. Confirmar o reagendamento.
4. Verificar o estado agendado.
5. Verificar a redução do indicador de pendências.
6. Confirmar a preservação do histórico.

Utilizar ambiente de teste ou dados isolados.

Não alterar o relógio do sistema operacional.

Não expor mecanismos de simulação temporal
através de rotas públicas.

---

## 42. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Validar também:

- Inicialização dos containers.
- Inicialização do mecanismo de tarefas.
- Logs do processamento.
- Comunicação com PostgreSQL.
- Reinicialização do ambiente.
- Console do navegador.
- Ausência de erros inesperados.

Não declarar testes aprovados sem executá-los.

---

## 43. Documentação

Registrar o requisito em:

    docs/requisitos/RF008.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação operacional.
- Documentação do banco, quando necessário.

Documentar:

- Conceito de chegada atrasada.
- Conceito de operação excedida.
- Regra de no-show.
- Horário limite de check-in.
- Processamento automático.
- Frequência de execução.
- Estratégia de concorrência.
- Estratégia de auditoria.
- Recuperação após indisponibilidade.
- Mecanismo de tarefas recorrentes.
- Configuração Docker.
- Comandos para verificar o processamento.
- Procedimento para executar testes.
- Indicador de reagendamentos pendentes.
- Limitações existentes.

Caso seja introduzido um novo mecanismo
de processamento em segundo plano,
registrar uma ADR justificando a decisão.

Utilizar a próxima numeração disponível.

---

## 44. Critérios de aceite

### Regras operacionais

- [ ] Chegada atrasada identificada.
- [ ] Chegada atrasada não cancela a reserva.
- [ ] Check-in atrasado permitido conforme RF005.
- [ ] Limite das 17:30 preservado.
- [ ] No-show identificado corretamente.
- [ ] Reservas de dias anteriores processadas.
- [ ] Reservas futuras preservadas.
- [ ] Veículos em operação preservados.
- [ ] Reservas liberadas preservadas.
- [ ] Reservas canceladas preservadas.
- [ ] Nenhuma liberação automática implementada.

### Processamento automático

- [ ] Tarefa recorrente implementada.
- [ ] Frequência de um minuto configurada.
- [ ] Processamento independente do navegador.
- [ ] Processamento independente do Dashboard.
- [ ] Recuperação após indisponibilidade validada.
- [ ] Processamento idempotente.
- [ ] Concorrência entre tarefas protegida.
- [ ] Concorrência com check-in protegida.
- [ ] Concorrência com alterações protegida.

### Persistência

- [ ] Status alterado para reagendamento.
- [ ] Motivo automático registrado.
- [ ] Protocolo preservado.
- [ ] Request ID preservado.
- [ ] Dados cadastrais preservados.
- [ ] Posição original preservada.
- [ ] Nenhum registro excluído.
- [ ] Controle de lock_version preservado.

### Auditoria

- [ ] Evento no_show registrado.
- [ ] Valores anteriores preservados.
- [ ] Novos valores registrados.
- [ ] Auditoria na mesma transação.
- [ ] Rollback validado.
- [ ] Ausência de auditorias duplicadas.
- [ ] Novas ocorrências legítimas permitidas
      após reagendamento.

### Painel administrativo

- [ ] Layout aprovado preservado.
- [ ] Chegadas atrasadas destacadas.
- [ ] Operações excedidas destacadas.
- [ ] Indicador de reagendamentos pendentes criado.
- [ ] Pendências de datas anteriores contabilizadas.
- [ ] Filtro de reagendamentos funcional.
- [ ] Motivo apresentado nos detalhes.
- [ ] Funcionalidades do RF006 reutilizadas.
- [ ] Indicadores anteriores preservados.

### Infraestrutura

- [ ] Mecanismo de processamento documentado.
- [ ] Docker Compose funcional.
- [ ] Nenhuma porta externa desnecessária.
- [ ] Nenhum Redis introduzido.
- [ ] Arquitetura monolítica preservada.
- [ ] Reinicialização validada.

### Segurança e qualidade

- [ ] Proteções anteriores preservadas.
- [ ] Nenhum endpoint público de processamento.
- [ ] Nenhuma autenticação provisória criada.
- [ ] Testes automatizados executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 45. Fora do escopo

Não implementar neste requisito:

- Novos status de agendamentos.
- Tolerância máxima de atraso.
- Cancelamento automático.
- Liberação automática.
- Reagendamento automático para nova posição.
- Atualização automática do Dashboard.
- Polling da interface.
- WebSockets.
- Action Cable.
- Turbo Streams para atualização em tempo real.
- Notificações por e-mail.
- Notificações WhatsApp.
- QR Code.
- Exportação Excel.
- Upload de documentos.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Redesign do painel administrativo.
- Implantação na VPS.

Implementar exclusivamente o controle de atrasos
e o processamento automático de no-show.

---

## 46. Entrega

Ao concluir o RF008, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Processamento automático

- Mecanismo de tarefas adotado.
- Frequência configurada.
- Jobs criados.
- Services criados.
- Estratégia de recuperação.
- Estratégia de tratamento de falhas.

### Infraestrutura

- Alterações no Docker Compose.
- Containers adicionados, quando aplicável.
- Comandos de inicialização.
- Comandos de diagnóstico.
- Dependências adicionadas e justificativas.

### Interface

- Componentes adicionados.
- Screenshot das reservas atrasadas.
- Screenshot das operações excedidas.
- Screenshot do indicador de reagendamentos.
- Screenshot da lista de pendências.

### Banco de dados

- Tabelas utilizadas.
- Eventuais migrations.
- Índices adicionais, quando necessários.
- Estratégia de concorrência.

### Auditoria

- Eventos registrados.
- Estratégia transacional.
- Proteção contra duplicidade.

### Testes

- Comandos executados.
- Quantidade de testes.
- Quantidade de assertions.
- Falhas.
- Erros.
- Testes ignorados.
- Resultados dos testes de concorrência.
- Resultado do RuboCop.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
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

Informar qualquer limitação, risco ou
decisão técnica que necessite de homologação.

---

## 47. Regra de parada

Ao concluir o RF008, PARE.

Não implementar o RF009.

Não implementar atualização automática
do Dashboard.

Não implementar autenticação ou autorização.

Não modificar desnecessariamente o layout
administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.