# RF007 — Bloqueio e Desbloqueio de Docas e Janelas de Horários

## 1. Objetivo

Implementar o gerenciamento de bloqueios operacionais
na aplicação DSV Doca Agenda.

Permitir que a equipe administrativa realize:

- Bloqueio individual de uma janela.
- Bloqueio de múltiplas janelas.
- Bloqueio de múltiplas docas.
- Bloqueio de uma doca durante todo o dia.
- Bloqueio de todas as docas durante todo o dia.
- Desbloqueio individual.
- Desbloqueio em lote.
- Consulta dos bloqueios existentes.
- Registro do motivo do bloqueio.
- Auditoria das operações.

Os bloqueios deverão afetar diretamente a disponibilidade
apresentada no formulário público de agendamento.

Preservar o layout administrativo aprovado e todas
as funcionalidades implementadas até o RF006.

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
- docs/referencias/

Analisar a implementação atual antes de realizar alterações.

Reutilizar os componentes, services, models, controllers,
helpers e estilos existentes.

Preservar a arquitetura monolítica Ruby on Rails.

Trabalhar exclusivamente dentro do repositório atual.

Não reconstruir o painel administrativo.

---

## 3. Estrutura do banco de dados

Utilizar a tabela existente:

    slot_blocks

Estrutura prevista no RF002:

    id
    blocked_date
    dock_number
    slot_number
    reason
    created_at
    updated_at

Utilizar também:

    bookings
    audit_events

Não criar novas tabelas.

Não criar tabelas de cadastro de docas ou janelas.

Não adicionar campos relacionados a usuários.

Não criar migrations desnecessárias.

Preservar os índices e constraints existentes.

Caso seja identificada uma necessidade indispensável
de alteração estrutural, documentar sua justificativa
e criar uma nova migration.

Não modificar migrations anteriormente aplicadas.

---

## 4. Menu administrativo

Adicionar à Sidebar existente:

    Bloqueios

Utilizar o mesmo padrão visual dos demais menus.

Preservar:

- Header.
- Logo DSV.
- Sidebar.
- Paleta de cores.
- Tipografia.
- Espaçamentos.
- Identificação do menu ativo.

O novo menu deverá direcionar para:

    /admin/slot_blocks

Não alterar os demais menus.

---

## 5. Tela de gerenciamento de bloqueios

Criar uma página administrativa denominada:

    Bloqueios de docas e horários

A página deverá possuir:

- Título.
- Descrição da funcionalidade.
- Seletor de data.
- Seleção de docas.
- Seleção de janelas.
- Campo de motivo.
- Resumo da operação.
- Botão de confirmação.
- Lista de bloqueios existentes.

Utilizar componentes semelhantes aos já existentes
no formulário público e nas telas administrativas.

Priorizar uma interface simples e objetiva.

---

## 6. Estrutura visual sugerida

    +------------------------------------------------+
    | Bloqueios de docas e horários                  |
    | Gerencie a disponibilidade operacional.        |
    +------------------------------------------------+
    |                                                |
    | Data do bloqueio                               |
    | [ Hoje ] [ Amanhã ] [ Depois de amanhã ]        |
    |                                                |
    | Selecionar docas                               |
    | [ ] Selecionar todas                           |
    |                                                |
    | [01] [02] [03] [04]                            |
    | [05] [06] [07] [08]                            |
    |                                                |
    | Selecionar horários                            |
    | [ ] Selecionar todos                           |
    |                                                |
    | [08:00 - 09:00] [09:00 - 10:00]               |
    | [10:00 - 11:00] [11:00 - 12:00]               |
    | [12:00 - 13:00] [13:00 - 14:00]               |
    | [14:00 - 15:00] [15:00 - 16:00]               |
    | [16:00 - 17:00] [17:00 - 17:48]               |
    |                                                |
    | Motivo do bloqueio (opcional)                  |
    | [__________________________________________]  |
    |                                                |
    | Docas selecionadas: 2                          |
    | Janelas selecionadas: 3                        |
    | Total de posições: 6                          |
    |                                                |
    |             [ Confirmar bloqueio ]             |
    +------------------------------------------------+
    |                                                |
    | Bloqueios existentes                           |
    |                                                |
    | Data | Doca | Horário | Motivo | Desbloquear   |
    |                                                |
    +------------------------------------------------+

A estrutura acima é uma referência conceitual.

Adaptar ao layout administrativo existente.

Não redesenhar a aplicação.

---

## 7. Seleção da data

Permitir criar bloqueios para:

- Hoje.
- Amanhã.
- Depois de amanhã.

Utilizar o mesmo horizonte de agendamento
implementado no RF003.

Utilizar o relógio do servidor.

Considerar o fuso:

    America/Sao_Paulo

Não utilizar o relógio do navegador como fonte
de verdade.

Não permitir criação de bloqueios para:

- Datas anteriores ao dia atual.
- Datas posteriores ao horizonte permitido.
- Datas inválidas.

A consulta dos bloqueios históricos poderá utilizar
datas fora do horizonte de criação.

Não implementar bloqueios recorrentes.

Não implementar intervalos de múltiplas datas
neste requisito.

---

## 8. Seleção das docas

Disponibilizar as oito docas físicas existentes:

    Doca 01
    Doca 02
    Doca 03
    Doca 04
    Doca 05
    Doca 06
    Doca 07
    Doca 08

Permitir selecionar:

- Uma única doca.
- Múltiplas docas.
- Todas as docas.

Utilizar checkboxes nativos do HTML.

Apresentar os checkboxes como cards selecionáveis,
quando adequado ao padrão visual existente.

Não utilizar radio buttons, pois a seleção
deverá permitir múltiplas opções.

Disponibilizar:

    Selecionar todas

Permitir também desmarcar todas as docas.

Reutilizar a definição centralizada de docas
existente no backend.

Não duplicar a quantidade de docas em JavaScript.

Validar todos os números recebidos no servidor.

---

## 9. Seleção das janelas

Disponibilizar as dez janelas fixas:

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

Permitir selecionar:

- Uma janela.
- Múltiplas janelas.
- Todas as janelas elegíveis.

Utilizar checkboxes nativos.

Disponibilizar:

    Selecionar todos os horários

Não alterar os horários operacionais.

A última janela deverá continuar terminando às 17:48.

Reutilizar as definições existentes no Rails.

---

## 10. Disponibilidade temporal dos bloqueios

Para a data atual, permitir bloquear somente
janelas cujo horário inicial seja estritamente
posterior ao horário atual do servidor.

Exemplo:

    Horário atual: 11:30

    08:00 - 09:00 -> Não elegível
    09:00 - 10:00 -> Não elegível
    10:00 - 11:00 -> Não elegível
    11:00 - 12:00 -> Não elegível
    12:00 - 13:00 -> Elegível
    13:00 - 14:00 -> Elegível

Para datas futuras, não aplicar o bloqueio
por horário atual.

Exemplo:

    Horário atual: 14:30

    Hoje, 08:00 -> Não elegível
    Amanhã, 08:00 -> Elegível
    Depois de amanhã, 08:00 -> Elegível

Considerar sempre a data completa da janela.

Não repetir o problema identificado anteriormente
no formulário público, no qual horários passados
afetavam indevidamente datas futuras.

Validar novamente a condição temporal no momento
da confirmação do bloqueio.

---

## 11. Bloqueio individual

Permitir selecionar uma doca e uma janela.

Exemplo:

    Data: Amanhã
    Doca: 03
    Janela: 10:00 - 11:00

Resultado:

    1 registro criado em slot_blocks.

A posição deverá ficar indisponível para novos
agendamentos após a confirmação da transação.

---

## 12. Bloqueio em lote

Permitir selecionar múltiplas docas e janelas.

A operação deverá considerar todas as combinações
entre as docas e as janelas selecionadas.

Exemplo:

    Data: Amanhã

    Docas selecionadas:
        01
        02

    Janelas selecionadas:
        08:00 - 09:00
        09:00 - 10:00
        10:00 - 11:00

Resultado:

    Doca 01 / Janela 01
    Doca 01 / Janela 02
    Doca 01 / Janela 03
    Doca 02 / Janela 01
    Doca 02 / Janela 02
    Doca 02 / Janela 03

Total:

    6 posições bloqueadas.

Cada combinação deverá possuir seu próprio registro
na tabela slot_blocks.

Não armazenar múltiplas docas ou janelas em arrays,
strings concatenadas ou JSONB.

Preservar a estrutura relacional existente.

---

## 13. Bloqueio de uma doca durante todo o dia

Permitir selecionar uma doca e todas as janelas
elegíveis.

Exemplo:

    Data: Amanhã
    Doca: 05
    Janelas: Todas

Resultado:

    10 posições bloqueadas.

Quando a data selecionada for o dia atual,
selecionar somente as janelas futuras elegíveis.

Não apresentar como bloqueadas retroativamente
as janelas que já passaram.

---

## 14. Bloqueio de toda a operação

Permitir selecionar todas as docas e todas
as janelas elegíveis.

Exemplo:

    Data: Amanhã
    Docas: Todas
    Janelas: Todas

Capacidade nominal:

    8 docas x 10 janelas = 80 posições

Caso todas as posições estejam livres e elegíveis,
a operação poderá criar 80 bloqueios.

Não criar um status global de indisponibilidade.

Não criar uma tabela adicional de fechamento diário.

Utilizar os registros individuais em slot_blocks.

---

## 15. Motivo do bloqueio

Utilizar o atributo existente:

    slot_blocks.reason

O preenchimento será opcional.

Quando informado:

- Remover espaços nas extremidades.
- Limitar a 250 caracteres.
- Aceitar caracteres acentuados.
- Tratar como texto simples.

Exemplos:

    Manutenção preventiva da doca.

    Inventário operacional.

    Indisponibilidade da equipe.

    Interrupção programada da operação.

O mesmo motivo deverá ser aplicado a todos
os novos registros de um bloqueio em lote.

Não expor o motivo do bloqueio no formulário público.

---

## 16. Resumo da operação

Antes da confirmação, apresentar:

- Data selecionada.
- Quantidade de docas selecionadas.
- Quantidade de janelas selecionadas.
- Total de combinações.
- Motivo informado.

Exemplo:

    Data: 26/11/2026

    Docas selecionadas: 3

    Janelas selecionadas: 4

    Total de posições: 12

    Motivo: Manutenção operacional.

O resumo visual poderá ser atualizado utilizando
JavaScript simples, quando necessário.

O cálculo definitivo deverá ser realizado
e validado no backend.

Não confiar em uma quantidade enviada pelo navegador.

---

## 17. Confirmação do bloqueio

Disponibilizar o botão:

    Confirmar bloqueio

Antes de executar a operação, apresentar
uma confirmação clara.

Exemplo:

    Você está prestes a bloquear 12 posições
    da agenda para a data selecionada.

    Deseja continuar?

    [Voltar] [Confirmar bloqueio]

A operação deverá ser executada somente
após a confirmação.

Não utilizar requisições GET para criar bloqueios.

Não criar um bloqueio automaticamente
ao selecionar uma doca ou janela.

---

## 18. Conflitos com agendamentos existentes

Não permitir bloquear uma posição que possua
uma reserva que consuma capacidade.

Estados que impedem o bloqueio:

    agendado
    em_operacao
    liberado

Estados que não impedem o bloqueio:

    cancelado
    reagendamento

Exemplo:

    Doca 03
    Data: Amanhã
    Janela: 10:00 - 11:00

    Existe um agendamento ativo.

Resultado:

    Bloqueio não permitido.

Apresentar:

    Não é possível bloquear esta posição,
    pois existe um agendamento registrado.

Não cancelar automaticamente a reserva.

Não reagendar automaticamente a reserva.

Não alterar o status de nenhum agendamento.

Caso seja necessário liberar a posição,
o operador deverá utilizar as funcionalidades
existentes do RF006, quando permitidas.

---

## 19. Conflitos durante bloqueios em lote

O bloqueio em lote deverá ser atômico.

Considerar o cenário:

    12 posições selecionadas.

    11 posições livres.

    1 posição possui uma reserva ativa.

Resultado esperado:

    Nenhum novo bloqueio deverá ser criado.

A operação deverá ser rejeitada integralmente.

Apresentar as posições conflitantes, identificando:

- Doca.
- Data.
- Horário.

Exemplo:

    Não foi possível concluir o bloqueio.

    Existem agendamentos nas seguintes posições:

    Doca 03 — 10:00 às 11:00
    Doca 05 — 14:00 às 15:00

    Nenhuma posição foi bloqueada.

Não executar bloqueios parciais silenciosamente.

Preservar as seleções realizadas pelo operador.

Permitir que o operador ajuste a seleção
e tente novamente.

---

## 20. Posições já bloqueadas

Não criar bloqueios duplicados.

Preservar o índice único existente para:

    blocked_date
    dock_number
    slot_number

Caso uma posição selecionada já esteja bloqueada:

- Preservar o registro existente.
- Preservar seu motivo original.
- Não criar um segundo registro.
- Não criar uma segunda auditoria de bloqueio.
- Informar que a posição já estava bloqueada.

Se todas as posições selecionadas já estiverem
bloqueadas, não realizar novas gravações.

Exemplo:

    Posições selecionadas: 10
    Já bloqueadas: 2
    Novos bloqueios: 8

Esse comportamento somente será permitido
quando não existirem outros conflitos que
invalidem a operação.

Caso exista uma inconsistência entre um bloqueio
existente e uma reserva que consome capacidade,
rejeitar a operação e informar o problema.

Não corrigir inconsistências automaticamente.

---

## 21. Persistência dos bloqueios

Ao confirmar uma operação válida, criar os
registros correspondentes em slot_blocks.

Exemplo:

    blocked_date: 2026-11-26
    dock_number: 3
    slot_number: 3
    reason: Manutenção preventiva.

Todos os novos registros de uma operação em lote
deverão ser criados dentro da mesma transação.

As auditorias correspondentes deverão ser
gravadas na mesma transação.

Caso qualquer criação ou auditoria falhe:

- Reverter todos os novos bloqueios.
- Preservar os bloqueios anteriormente existentes.
- Não deixar registros parciais.
- Não apresentar mensagem de sucesso.

---

## 22. Lista de bloqueios existentes

Apresentar na página de gerenciamento uma
lista dos bloqueios registrados.

Colunas:

- Data.
- Doca.
- Janela.
- Horário.
- Motivo.
- Data e hora de criação.
- Ações.

Exemplo:

    Data       | Doca | Horário       | Motivo
    26/11/2026 | 03   | 10:00 - 11:00 | Manutenção
    26/11/2026 | 03   | 11:00 - 12:00 | Manutenção
    27/11/2026 | 05   | 14:00 - 15:00 | Inventário

Permitir filtros por:

- Data.
- Doca.

Ordenar preferencialmente por:

1. Data.
2. Doca.
3. Janela.

Utilizar consultas Active Record parametrizadas.

Não carregar todos os registros no navegador
para realizar filtragem por JavaScript.

Utilizar paginação quando necessária.

---

## 23. Desbloqueio individual

Disponibilizar uma ação:

    Desbloquear

O desbloqueio deverá remover o registro
correspondente de slot_blocks.

Antes da confirmação, apresentar:

- Data.
- Doca.
- Horário.
- Motivo original.

Exemplo:

    Desbloquear posição?

    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 - 11:00
    Motivo original: Manutenção preventiva.

    [Voltar] [Confirmar desbloqueio]

Não executar o desbloqueio por GET.

Não remover registros sem confirmação.

Preservar o histórico do bloqueio na auditoria.

---

## 24. Desbloqueio em lote

Permitir selecionar múltiplos registros
na lista de bloqueios existentes.

Disponibilizar:

    Desbloquear selecionados

Permitir selecionar todos os registros
elegíveis da lista apresentada.

Informar claramente o escopo da seleção.

Não incluir registros de outras páginas
ou filtros de maneira implícita.

Apresentar a quantidade de bloqueios selecionados
antes da confirmação.

Exemplo:

    Você selecionou 10 bloqueios.

    Deseja desbloquear essas posições?

    [Voltar] [Confirmar desbloqueio]

Validar todos os registros no backend.

Executar a remoção e a auditoria dentro
da mesma transação.

Não permitir desbloqueio parcial silencioso.

Caso algum bloqueio selecionado não exista mais
ou tenha sido alterado durante a operação,
rejeitar o lote e atualizar a lista.

---

## 25. Regras temporais do desbloqueio

Permitir desbloquear posições futuras elegíveis
dentro do horizonte operacional.

Não disponibilizar ações de desbloqueio para
bloqueios de datas anteriores ou janelas
já iniciadas.

Preservar esses registros para consulta histórica.

Não excluir automaticamente bloqueios antigos.

Não implementar políticas de retenção neste RF.

O desbloqueio de uma posição não deverá
ignorar as demais regras de disponibilidade.

---

## 26. Motivo do desbloqueio

Não exigir um novo motivo obrigatório para
realizar o desbloqueio neste requisito.

Preservar na auditoria:

- Motivo original do bloqueio.
- Data bloqueada.
- Doca.
- Janela.
- Data e hora do desbloqueio.

Não criar uma nova coluna na tabela slot_blocks
para armazenar informações de desbloqueio.

A auditoria deverá preservar o histórico mesmo
após a remoção do bloqueio.

---

## 27. Disponibilidade após o bloqueio

Após confirmar um bloqueio, a posição deverá
ficar indisponível no formulário público.

Exemplo:

    Doca 03
    Data: Amanhã
    Janela: 10:00 - 11:00

    Status da posição: Bloqueada

O participante não deverá conseguir selecionar
essa janela.

Caso tente enviar diretamente uma requisição
manipulada, o backend deverá rejeitar a reserva.

Não revelar no formulário público:

- Motivo do bloqueio.
- Informações administrativas.
- Dados internos da operação.

Apresentar somente a indisponibilidade da posição.

---

## 28. Disponibilidade após o desbloqueio

Após confirmar um desbloqueio, a posição poderá
voltar a receber agendamentos.

Entretanto, deverá respeitar todas as regras
existentes:

- Data permitida.
- Horário futuro.
- Doca válida.
- Janela válida.
- Ausência de reserva que consuma capacidade.
- Ausência de outro bloqueio.

Não apresentar uma posição como disponível
apenas porque o registro de bloqueio foi removido.

Reutilizar o motor de disponibilidade existente.

Não duplicar regras de negócio.

---

## 29. Integração com o Dashboard

Atualizar a matriz existente para refletir
os bloqueios registrados.

Uma posição bloqueada deverá apresentar:

    Bloqueado

Utilizar o padrão visual aprovado no RF004.

Preferir:

- Fundo cinza.
- Ícone de cadeado.
- Texto identificando o bloqueio.

Não depender exclusivamente da cor.

Ao consultar uma posição bloqueada, permitir
visualizar seu motivo no painel administrativo.

Não revelar esse motivo no formulário público.

Após o desbloqueio, recalcular o estado
da posição conforme as regras existentes.

Não reconstruir a matriz.

Não alterar seu layout.

---

## 30. Indicadores do Dashboard

Os bloqueios deverão afetar corretamente
o indicador de horários disponíveis.

Exemplo:

    Capacidade nominal: 80
    Reservas que consomem capacidade: 20
    Posições bloqueadas: 10

    Posições livres nominais: 50

A disponibilidade efetiva deverá considerar
também a data e o horário atual.

Não contar posições passadas como disponíveis.

Não contabilizar duas vezes a mesma posição.

Os bloqueios não deverão ser contabilizados como:

- Agendamentos.
- Entregas.
- Coletas.
- Veículos em operação.

Preservar os indicadores existentes.

Não adicionar novos cards ao Dashboard
neste requisito.

---

## 31. Controle de concorrência compartilhado

Reutilizar a estratégia transacional de travamento
implementada nos RF003 e RF006.

Todas as operações que alterem a disponibilidade
deverão utilizar o mesmo mecanismo.

Considerar:

- Criação de reserva pública.
- Alteração de reserva.
- Reagendamento.
- Cancelamento.
- Bloqueio.
- Desbloqueio.

Não criar um mecanismo de travamento independente
exclusivamente para slot_blocks.

A unidade de controle deverá considerar:

    Data + Doca + Janela

Ao executar operações em lote, adquirir as travas
em uma ordem determinística e consistente.

Após adquirir as travas:

- Reconsultar os agendamentos.
- Reconsultar os bloqueios.
- Validar novamente as posições.
- Validar a condição temporal.
- Confirmar a operação.

Manter todas as operações críticas dentro
da mesma transação.

Não utilizar mutex Ruby como única proteção.

Não utilizar travas exclusivamente em memória.

Não adicionar Redis.

---

## 32. Concorrência entre bloqueio e agendamento

Considerar o cenário:

    Uma transportadora confirma um agendamento.

    Simultaneamente, um operador tenta bloquear
    exatamente a mesma posição.

Somente uma operação poderá ser confirmada.

### Cenário A

A reserva é confirmada primeiro.

Resultado:

- Reserva criada.
- Bloqueio rejeitado.

### Cenário B

O bloqueio é confirmado primeiro.

Resultado:

- Bloqueio criado.
- Reserva rejeitada.
- Participante orientado a selecionar outro horário.

Nunca permitir que as duas operações sejam
confirmadas para a mesma posição.

Preservar os índices únicos existentes.

Os índices individuais de bookings e slot_blocks
não garantem isoladamente essa integridade
entre tabelas diferentes.

Garantir que todos os fluxos de escrita da aplicação
utilizem a estratégia transacional compartilhada.

Documentar eventuais limitações relacionadas
a alterações realizadas diretamente via SQL.

Não declarar uma garantia absoluta no PostgreSQL
caso ela dependa da utilização dos services Rails.

---

## 33. Concorrência com reagendamento

Considerar:

    Operador A tenta reagendar um veículo.

    Operador B tenta bloquear a posição de destino.

Resultado:

- Somente uma operação poderá confirmar
  o consumo ou bloqueio da posição.

Caso o reagendamento seja rejeitado:

- Preservar a posição original da reserva.
- Preservar seu status.
- Preservar seu protocolo.
- Não criar auditoria de sucesso.

Caso um bloqueio em lote seja rejeitado:

- Reverter todos os novos bloqueios.
- Preservar os registros anteriores.

Não enfraquecer as proteções implementadas
no RF006.

---

## 34. Auditoria de bloqueio

Utilizar:

    audit_events

Registrar um evento para cada novo bloqueio.

Estrutura conceitual:

    entity_type: SlotBlock

    entity_id: ID do bloqueio

    action: block

    previous_values: null

    new_values:
        blocked_date
        dock_number
        slot_number
        reason

    reason: motivo informado

Utilizar o horário do servidor.

Respeitar a convenção de nomenclatura de auditoria
existente no projeto.

Não criar eventos adicionais para posições
que já estavam bloqueadas.

---

## 35. Auditoria de desbloqueio

Antes de remover um bloqueio, preservar
suas informações.

Registrar:

    entity_type: SlotBlock

    entity_id: ID do bloqueio removido

    action: unblock

    previous_values:
        blocked_date
        dock_number
        slot_number
        reason

    new_values: null

O evento deverá permanecer disponível mesmo
após a exclusão do registro em slot_blocks.

Não configurar exclusão em cascata dos eventos
de auditoria.

Não exigir que o registro original continue
existindo para consultar sua auditoria.

Não implementar identificação individual
do operador neste requisito.

---

## 36. Integridade da auditoria

A auditoria deverá ser registrada na mesma
transação da operação correspondente.

Para bloqueios em lote:

    N novos bloqueios = N eventos de auditoria.

Para desbloqueios em lote:

    N bloqueios removidos = N eventos de auditoria.

Caso uma auditoria falhe:

- Reverter toda a operação.
- Não criar registros parciais.
- Não remover parcialmente os bloqueios.
- Não apresentar mensagem de sucesso.

Não registrar informações sensíveis
desnecessárias.

Não registrar parâmetros completos da requisição.

---

## 37. Rotas administrativas

Criar as rotas necessárias dentro do namespace
administrativo existente.

Estrutura sugerida:

    GET /admin/slot_blocks

    POST /admin/slot_blocks

    DELETE /admin/slot_blocks/:id

    POST /admin/slot_blocks/bulk_unblock

A nomenclatura poderá ser adaptada às convenções
existentes no projeto.

Utilizar GET exclusivamente para consulta.

Utilizar POST ou DELETE para operações
que modifiquem o banco de dados.

Não utilizar GET para bloquear ou desbloquear.

Não criar APIs JSON exclusivamente para
alimentar as views Rails.

Preservar as rotas administrativas existentes.

---

## 38. Organização do backend

Manter os controllers pequenos.

Centralizar as responsabilidades de:

- Validação de posições.
- Criação de bloqueios.
- Desbloqueio.
- Operações em lote.
- Concorrência.
- Auditoria.

Reutilizar os services existentes.

Criar services específicos quando necessário.

Não criar abstrações genéricas desnecessárias.

Não duplicar regras de disponibilidade
entre controllers e services.

Não executar consultas diretamente nas views.

Evitar uma consulta ao banco para cada posição.

Consultar os agendamentos e bloqueios relevantes
de maneira agrupada.

---

## 39. Tratamento de erros

Apresentar mensagens claras em português.

### Nenhuma doca selecionada

    Selecione pelo menos uma doca.

### Nenhuma janela selecionada

    Selecione pelo menos um horário.

### Data inválida

    Selecione uma data dentro do período permitido.

### Horário inválido

    Uma ou mais janelas selecionadas não estão
    disponíveis para bloqueio.

### Conflito com reserva

    Existem agendamentos nas posições selecionadas.
    Nenhum novo bloqueio foi realizado.

### Posições já bloqueadas

    Algumas posições selecionadas já estavam bloqueadas.

### Bloqueio confirmado

    12 posições bloqueadas com sucesso.

### Desbloqueio confirmado

    10 posições desbloqueadas com sucesso.

### Conflito concorrente

    A disponibilidade foi alterada durante a operação.
    Consulte os dados atualizados antes de continuar.

Não exibir:

- SQL.
- Stack traces.
- Mensagens internas do PostgreSQL.
- Informações de infraestrutura.

Preservar os dados preenchidos quando ocorrer
um erro de validação.

---

## 40. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Utilizar Strong Parameters.

Permitir somente os atributos necessários:

- blocked_date
- dock_numbers
- slot_numbers
- reason

Para desbloqueios, validar os identificadores
dos registros selecionados.

Validar:

- Tipos dos parâmetros.
- Quantidade de elementos recebidos.
- Limites dos números de docas.
- Limites dos números de janelas.
- Formato da data.
- Tamanho do motivo.

Normalizar seleções duplicadas.

Não permitir mais de 80 combinações válidas
por operação de criação de bloqueios.

Não aceitar valores manipulados pelo navegador.

Manter proteção CSRF habilitada.

Preservar a Content Security Policy.

Utilizar escaping padrão do ERB.

Não utilizar raw ou html_safe para apresentar
motivos fornecidos pelo operador.

Utilizar consultas parametrizadas.

Não implementar autenticação provisória.

Não criar usuários, perfis ou permissões.

Manter as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

Não disponibilizar o painel administrativo
em produção antes da implementação de
autenticação e autorização.

---

## 41. JavaScript

Utilizar o mínimo necessário.

JavaScript poderá ser utilizado para:

- Selecionar todas as docas.
- Desmarcar todas as docas.
- Selecionar todas as janelas elegíveis.
- Atualizar o resumo visual.
- Atualizar a disponibilidade.
- Selecionar bloqueios para desbloqueio em lote.

Priorizar os recursos existentes:

- HTML.
- CSS.
- ERB.
- Turbo.
- Stimulus, quando necessário.

Não utilizar JavaScript para definir:

- Elegibilidade definitiva de um bloqueio.
- Disponibilidade real da posição.
- Regras de concorrência.
- Integridade dos registros.
- Regras de autorização.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Handlers JavaScript inline.
- Scripts de CDNs.

Não enfraquecer a CSP.

Não adicionar dependências frontend desnecessárias.

---

## 42. Responsividade

Preservar o padrão visual administrativo.

Priorizar a utilização em computadores.

Garantir:

- Cards selecionáveis.
- Áreas de interação adequadas.
- Estados selecionados claramente visíveis.
- Labels associados aos checkboxes.
- Navegação por teclado.
- Contraste adequado.
- Mensagens de erro legíveis.

Permitir utilização em tablets e celulares.

Não gerar scroll horizontal em toda a página.

Não criar uma interface independente
do layout administrativo existente.

---

## 43. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 43.1 Bloqueios individuais

Validar:

- Criação de bloqueio válido.
- Persistência da data.
- Persistência da doca.
- Persistência da janela.
- Persistência do motivo.
- Bloqueio sem motivo.
- Criação da auditoria.

### 43.2 Bloqueios em lote

Validar:

- Seleção de múltiplas docas.
- Seleção de múltiplas janelas.
- Produto cartesiano correto.
- Duas docas e três janelas geram seis posições.
- Uma doca e dez janelas geram dez posições.
- Oito docas e dez janelas geram oitenta posições.
- Ausência de registros duplicados.
- Auditoria correspondente a cada novo bloqueio.

### 43.3 Validações

Validar a rejeição de:

- Data anterior.
- Data fora do horizonte.
- Data inválida.
- Doca 0.
- Doca 9.
- Janela 0.
- Janela 11.
- Seleção vazia de docas.
- Seleção vazia de janelas.
- Motivo superior a 250 caracteres.
- Parâmetros manipulados.

### 43.4 Regras temporais

Validar:

- Janela passada no dia atual rejeitada.
- Janela futura no dia atual permitida.
- Janela no instante exato do início rejeitada.
- Janela de amanhã não afetada pelo horário atual.
- Janela de depois de amanhã não afetada.
- Última janela terminando às 17:48.
- Virada de data no fuso America/Sao_Paulo.

### 43.5 Conflitos com reservas

Validar que reservas nos estados:

- agendado
- em_operacao
- liberado

impedem bloqueios na mesma posição.

Validar que reservas nos estados:

- cancelado
- reagendamento

não impedem bloqueios.

### 43.6 Atomicidade

Validar:

- Lote contendo uma posição reservada.
- Lote contendo uma posição temporalmente inválida.
- Falha durante a criação de um bloqueio.
- Falha durante a criação de auditoria.

Nenhum novo bloqueio deverá permanecer
quando a operação for rejeitada.

### 43.7 Bloqueios existentes

Validar:

- Repetição de um bloqueio.
- Ausência de duplicidade.
- Preservação do motivo original.
- Ausência de auditoria duplicada.
- Lote com posições livres e já bloqueadas.
- Lote contendo somente posições já bloqueadas.

### 43.8 Desbloqueios

Validar:

- Desbloqueio individual.
- Desbloqueio em lote.
- Remoção dos registros corretos.
- Preservação da auditoria.
- Rejeição de identificadores inválidos.
- Rejeição de bloqueios históricos.
- Rejeição de bloqueios de horários já iniciados.
- Rollback em caso de falha da auditoria.
- Rejeição de lote com registro inexistente.
- Disponibilidade recalculada após desbloqueio.

### 43.9 Concorrência

Utilizar conexões independentes com PostgreSQL
e transações efetivamente concorrentes.

Validar:

- Dois operadores bloqueando a mesma posição.
- Bloqueio concorrente com criação de reserva.
- Bloqueio concorrente com alteração de reserva.
- Bloqueio concorrente com reagendamento.
- Desbloqueios concorrentes.
- Operações em lote com posições compartilhadas.
- Ausência de bloqueios e reservas incompatíveis
  confirmados simultaneamente.

Não simular concorrência exclusivamente
através de operações sequenciais.

Utilizar limites de espera adequados.

### 43.10 Integração com o formulário público

Validar:

- Posição bloqueada indisponível.
- Tentativa de reservar posição bloqueada rejeitada.
- Posição desbloqueada disponível quando elegível.
- Ausência do motivo interno na resposta pública.
- Preservação das regras de idempotência.

### 43.11 Dashboard

Validar:

- Exibição das posições bloqueadas.
- Atualização da matriz após desbloqueio.
- Indicador de horários disponíveis.
- Ausência de dupla contagem.
- Preservação dos indicadores de coleta e entrega.

### 43.12 Segurança

Validar:

- Proteção CSRF efetivamente habilitada.
- Manipulação de números de docas.
- Manipulação de números de janelas.
- Manipulação de identificadores.
- Tentativa de SQL Injection.
- Tentativa de XSS no motivo.
- Preservação da Content Security Policy.
- Indisponibilidade das rotas em produção.

### 43.13 Regressão

Executar todos os testes existentes dos:

- RF001.
- RF002.
- RF003.
- RF004.
- RF005.
- RF006.

Não remover ou enfraquecer testes anteriores.

---

## 44. Validação manual

### Cenário 01 — Bloqueio individual

1. Acessar o menu Bloqueios.
2. Selecionar amanhã.
3. Selecionar a doca 03.
4. Selecionar a janela 10:00 - 11:00.
5. Informar um motivo.
6. Confirmar o bloqueio.
7. Verificar a lista de bloqueios.
8. Verificar a matriz administrativa.
9. Acessar o formulário público.
10. Confirmar que a posição está indisponível.

### Cenário 02 — Bloqueio em lote

1. Selecionar uma data futura.
2. Selecionar duas docas.
3. Selecionar três janelas livres.
4. Verificar o resumo de seis posições.
5. Confirmar o bloqueio.
6. Verificar os seis registros.
7. Verificar os seis eventos de auditoria.

### Cenário 03 — Conflito

1. Criar um agendamento válido.
2. Selecionar um lote contendo sua posição.
3. Tentar confirmar o bloqueio.
4. Confirmar que a operação é rejeitada.
5. Verificar que nenhum novo bloqueio foi criado.
6. Confirmar que a reserva permanece intacta.

### Cenário 04 — Desbloqueio

1. Selecionar um bloqueio futuro.
2. Confirmar o desbloqueio.
3. Verificar a remoção do registro.
4. Verificar a auditoria.
5. Consultar o formulário público.
6. Confirmar a disponibilidade da posição,
   caso todas as demais regras sejam atendidas.

### Cenário 05 — Datas futuras

1. Acessar a tela após o início de algumas
   janelas do dia atual.
2. Verificar que essas janelas não são elegíveis hoje.
3. Selecionar amanhã.
4. Verificar que as mesmas janelas são elegíveis.
5. Selecionar depois de amanhã.
6. Confirmar o mesmo comportamento.

### Cenário 06 — Seleção completa

1. Selecionar uma data futura sem reservas.
2. Selecionar todas as docas.
3. Selecionar todas as janelas.
4. Verificar o resumo de 80 posições.
5. Confirmar o bloqueio.
6. Verificar a indisponibilidade de todas
   as posições no formulário público.

Utilizar dados isolados de teste.

Não alterar o relógio do sistema operacional.

Não executar testes destrutivos sobre dados existentes.

---

## 45. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Utilizar os procedimentos definidos
nos requisitos anteriores.

Validar o console do navegador.

Não deverão existir:

- Erros JavaScript.
- Violações inesperadas de CSP.
- Links quebrados.
- Erros de carregamento.
- Componentes sobrepostos.

Não declarar testes aprovados sem executá-los.

---

## 46. Documentação

Registrar este requisito em:

    docs/requisitos/RF007.md

Atualizar o índice de requisitos.

Documentar:

- Menu Bloqueios.
- Rotas adicionadas.
- Bloqueio individual.
- Bloqueio em lote.
- Desbloqueio individual.
- Desbloqueio em lote.
- Regras temporais.
- Tratamento de conflitos.
- Estratégia de concorrência compartilhada.
- Atomicidade das operações.
- Auditoria.
- Integração com o formulário público.
- Integração com o Dashboard.
- Limitações existentes.

Atualizar a documentação do banco quando necessário.

Criar ADR somente quando houver uma nova
decisão arquitetural relevante.

---

## 47. Critérios de aceite

### Interface

- [ ] Menu Bloqueios implementado.
- [ ] Layout administrativo preservado.
- [ ] Seletor de data funcional.
- [ ] Seleção múltipla de docas.
- [ ] Seleção múltipla de janelas.
- [ ] Selecionar todas as docas.
- [ ] Selecionar todas as janelas elegíveis.
- [ ] Campo de motivo.
- [ ] Resumo das posições selecionadas.
- [ ] Confirmação da operação.
- [ ] Lista de bloqueios existentes.
- [ ] Filtros funcionais.
- [ ] Desbloqueio individual.
- [ ] Desbloqueio em lote.

### Regras de negócio

- [ ] Oito docas preservadas.
- [ ] Dez janelas preservadas.
- [ ] Última janela termina às 17:48.
- [ ] Horizonte de três datas respeitado.
- [ ] Horários passados impedidos.
- [ ] Datas futuras não afetadas pelo horário atual.
- [ ] Bloqueio individual funcional.
- [ ] Bloqueio em lote funcional.
- [ ] Bloqueio de uma doca durante todo o dia.
- [ ] Bloqueio de todas as docas em uma data elegível.
- [ ] Reservas existentes protegidas.
- [ ] Nenhum cancelamento automático.
- [ ] Nenhum reagendamento automático.

### Integridade

- [ ] Bloqueios duplicados impedidos.
- [ ] Índices existentes preservados.
- [ ] Operações em lote atômicas.
- [ ] Controle transacional compartilhado.
- [ ] Concorrência com reservas validada.
- [ ] Concorrência com reagendamentos validada.
- [ ] Ausência de gravações parciais.
- [ ] Rollback validado.

### Auditoria

- [ ] Bloqueios auditados.
- [ ] Desbloqueios auditados.
- [ ] Motivos preservados.
- [ ] Histórico preservado após desbloqueio.
- [ ] Ausência de auditorias duplicadas.
- [ ] Auditoria na mesma transação.

### Integração

- [ ] Formulário público respeita bloqueios.
- [ ] Backend rejeita reservas em posições bloqueadas.
- [ ] Disponibilidade recalculada após desbloqueio.
- [ ] Motivos internos não expostos publicamente.
- [ ] Matriz administrativa atualizada.
- [ ] Indicadores consistentes.
- [ ] RF005 preservado.
- [ ] RF006 preservado.

### Segurança e qualidade

- [ ] Strong Parameters utilizado.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Escaping de conteúdo preservado.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma autenticação provisória criada.
- [ ] Testes automatizados executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 48. Fora do escopo

Não implementar:

- Bloqueios recorrentes.
- Bloqueios semanais ou mensais.
- Bloqueios em intervalos de múltiplas datas.
- Calendário de feriados.
- Cadastro de docas.
- Cadastro de janelas.
- Alteração dos horários operacionais.
- Cancelamento automático de reservas.
- Reagendamento automático de reservas.
- No-show automático.
- Atualização automática do Dashboard.
- Polling.
- WebSockets.
- QR Code.
- Exportação Excel.
- Notificações por e-mail.
- Upload de documentos.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis e permissões.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente o gerenciamento
de bloqueios e desbloqueios operacionais.

---

## 49. Entrega

Ao concluir o RF007, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Interface

- Menu adicionado.
- Componentes implementados.
- Screenshots da tela de bloqueios.
- Screenshot da seleção em lote.
- Screenshot da lista de bloqueios.
- Screenshot da matriz com posições bloqueadas.

### Backend

- Rotas criadas.
- Controllers criados ou modificados.
- Models modificados.
- Services criados ou reutilizados.
- Estratégia de concorrência.
- Estratégia de atomicidade.
- Estratégia de auditoria.

### Banco de dados

- Índices utilizados.
- Constraints utilizadas.
- Eventuais migrations e justificativas.
- Limitações da proteção entre tabelas.

### Segurança

- Proteções preservadas.
- Proteções adicionadas.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Riscos identificados.

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

Não declarar conclusão caso existam
critérios obrigatórios pendentes.

### Repositório

Apresentar:

    git status --short

### Pendências

Informar qualquer problema, limitação ou decisão
que necessite de homologação.

---

## 50. Regra de parada

Ao concluir o RF007, PARE.

Não implementar o RF008.

Não implementar no-show automático.

Não implementar atualização automática do painel.

Não implementar autenticação ou autorização.

Preservar o layout administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.