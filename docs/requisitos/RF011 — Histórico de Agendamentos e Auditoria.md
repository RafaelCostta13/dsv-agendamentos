# RF011 — Histórico de Agendamentos e Auditoria

## 1. Objetivo

Implementar a interface de consulta do histórico
operacional e da auditoria da aplicação DSV Doca Agenda.

Permitir que a equipe administrativa consulte:

- Histórico completo dos agendamentos.
- Criação de reservas.
- Alterações de data, doca e horário.
- Cancelamentos.
- Reagendamentos.
- Check-ins.
- Liberações.
- Ocorrências de no-show.
- Bloqueios de posições.
- Desbloqueios de posições.
- Valores anteriores e posteriores às operações.
- Motivos e observações registrados.
- Data e horário de cada evento.

Reutilizar os eventos já registrados na tabela audit_events.

Preservar todas as funcionalidades implementadas
até o RF010.

Preservar o layout administrativo aprovado.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/database/
- docs/requisitos/RF001.md até RF010.md
- docs/referencias/

Analisar a implementação existente de auditoria.

Identificar:

- Estrutura da tabela audit_events.
- Model responsável pela auditoria.
- Services responsáveis pelas gravações.
- Nomenclatura dos eventos existentes.
- Estrutura dos valores anteriores e posteriores.
- Regras de persistência.
- Índices e constraints existentes.

Não assumir que a implementação atual corresponde
exatamente aos exemplos conceituais dos requisitos.

Adaptar este RF à estrutura efetivamente implementada,
preservando suas regras de negócio.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Arquitetura

Preservar a arquitetura monolítica Ruby on Rails.

Utilizar:

- Ruby on Rails.
- Active Record.
- PostgreSQL.
- Controllers.
- Views ERB.
- Partials.
- Helpers.
- CSS.

Priorizar renderização no servidor.

Não criar uma aplicação frontend independente.

Não introduzir:

- React.
- Vue.
- Angular.
- SPA.
- Redis.
- Elasticsearch.
- Microsserviços.
- APIs REST desnecessárias.
- Bibliotecas externas de auditoria sem necessidade.

Utilizar o mínimo necessário de JavaScript.

---

## 4. Conceitos

Distinguir dois tipos de consulta.

### 4.1 Histórico individual

Apresentar todos os eventos associados a uma
reserva específica.

Exemplo:

    Agendamento criado
    Agendamento alterado
    Check-in realizado
    Veículo liberado

O histórico individual deverá ser apresentado
na página de detalhes do agendamento.

### 4.2 Auditoria geral

Apresentar os eventos operacionais registrados
em toda a aplicação.

Incluindo:

- Eventos de agendamentos.
- Eventos de bloqueios.
- Eventos de desbloqueios.
- Eventos automáticos de no-show.

A auditoria geral deverá possuir uma página
administrativa específica.

---

## 5. Estrutura do banco de dados

Utilizar a tabela existente:

    audit_events

Estrutura prevista:

    id
    entity_type
    entity_id
    action
    previous_values
    new_values
    reason
    created_at

Verificar a estrutura efetivamente implementada.

Utilizar também, quando necessário:

    bookings
    slot_blocks

Não criar uma nova tabela de histórico.

Não duplicar os eventos existentes.

Não criar tabelas adicionais exclusivamente
para apresentação da auditoria.

Não adicionar usuários ou relacionamentos
com operadores neste requisito.

Não modificar migrations anteriormente aplicadas.

Caso seja necessária uma migration para garantir
a integridade da auditoria, documentar e justificar.

---

## 6. Menu administrativo

Adicionar à Sidebar existente:

    Histórico

Preservar o padrão visual dos menus existentes.

Estrutura esperada:

    Dashboard
    Agendamentos
    Bloqueios
    Histórico

Não modificar os demais menus.

Preservar:

- Logo DSV.
- Header.
- Sidebar.
- Paleta de cores.
- Tipografia.
- Identificação do menu ativo.
- Responsividade.

O menu Histórico deverá direcionar para
a página de auditoria geral.

---

## 7. Página de auditoria geral

Criar uma página denominada:

    Histórico de operações

Apresentar uma descrição:

    Consulte o histórico de alterações e operações
    realizadas no sistema.

A página deverá possuir:

- Título.
- Descrição.
- Filtros.
- Tabela de eventos.
- Paginação.
- Acesso aos detalhes de cada evento.

Não criar novos indicadores no Dashboard.

Não modificar o polling implementado no RF009.

---

## 8. Estrutura visual sugerida

    +------------------------------------------------------+
    | Histórico de operações                              |
    | Consulte os eventos registrados no sistema.         |
    +------------------------------------------------------+
    |                                                      |
    | Data inicial: [________] Data final: [________]       |
    |                                                      |
    | Evento: [Todos] Entidade: [Todas]                     |
    |                                                      |
    | Protocolo: [____________________________]             |
    |                                                      |
    | [Limpar filtros] [Filtrar]                           |
    +------------------------------------------------------+
    |                                                      |
    | Data/hora | Evento | Referência | Origem | Detalhes   |
    |------------------------------------------------------|
    | 14:48     | Liberação | DA-XXX | Painel  | Visualizar |
    | 14:05     | Check-in  | DA-XXX | Painel  | Visualizar |
    | 13:30     | Bloqueio  | Doca 3 | Painel  | Visualizar |
    | 09:15     | Criação   | DA-YYY | Público | Visualizar |
    |                                                      |
    |              [Anterior] 1 2 3 [Próximo]              |
    +------------------------------------------------------+

A estrutura acima é somente uma referência conceitual.

Adaptar ao layout administrativo existente.

---

## 9. Tipos de eventos

Identificar os eventos efetivamente utilizados
pelos requisitos anteriores.

Mapeamento conceitual:

    create
        Agendamento criado

    reschedule
        Agendamento alterado ou reagendado

    cancel
        Agendamento cancelado

    checkin
        Check-in realizado

    release
        Veículo liberado

    no_show
        Reagendamento obrigatório por não comparecimento

    block
        Posição bloqueada

    unblock
        Posição desbloqueada

Preservar os nomes técnicos já utilizados
na implementação existente.

Não modificar registros históricos para
adequá-los a uma nova nomenclatura.

Centralizar o mapeamento entre:

- Nome técnico.
- Nome apresentado ao usuário.
- Ícone.
- Cor.
- Descrição.

---

## 10. Diferenciação entre alteração e reagendamento

Quando existir um evento de alteração de reserva,
utilizar os estados anteriores e posteriores
para identificar a operação.

Exemplo 01:

    Status anterior: agendado
    Novo status: agendado

Apresentar:

    Agendamento alterado

Exemplo 02:

    Status anterior: reagendamento
    Novo status: agendado

Apresentar:

    Veículo reagendado

Não criar eventos artificiais.

Não modificar o evento original armazenado.

Essa diferenciação deverá ocorrer somente
na apresentação do histórico.

Quando os dados históricos forem insuficientes,
apresentar uma descrição genérica e verdadeira.

---

## 11. Origem dos eventos

Apresentar a origem da operação quando
ela puder ser identificada com segurança.

Origens previstas:

    Formulário público
    Painel administrativo
    Sistema automático

Mapeamento esperado para os fluxos atuais:

- Criação pública: Formulário público.
- Alteração administrativa: Painel administrativo.
- Cancelamento: Painel administrativo.
- Reagendamento: Painel administrativo.
- Check-in: Painel administrativo.
- Liberação: Painel administrativo.
- Bloqueio: Painel administrativo.
- Desbloqueio: Painel administrativo.
- No-show: Sistema automático.

Verificar se esse mapeamento corresponde
aos caminhos de escrita existentes.

Caso não seja possível determinar a origem
de um evento com segurança, apresentar:

    Origem não registrada

Não inventar informações históricas.

Não criar usuários fictícios.

Não atribuir uma operação a uma pessoa
sem que essa informação esteja registrada.

A identificação individual dos operadores
será implementada posteriormente.

---

## 12. Tabela de eventos

Apresentar as seguintes colunas:

- Data e hora.
- Evento.
- Tipo de entidade.
- Referência.
- Origem, quando identificável.
- Resumo da operação.
- Ação de visualizar detalhes.

Exemplo:

    26/11/2026 14:48
    Veículo liberado
    Agendamento
    DA-7F3A92B8C104
    Painel administrativo

Para eventos relacionados a bloqueios,
apresentar como referência:

- Data bloqueada.
- Doca.
- Janela.

Não utilizar exclusivamente o ID interno
como identificação visual.

Não apresentar JSON bruto na tabela principal.

---

## 13. Ordenação

Apresentar inicialmente os eventos
mais recentes.

Ordenação padrão:

    created_at DESC
    id DESC

Utilizar o ID como critério adicional
para garantir ordenação determinística.

Não permitir que a paginação apresente
uma ordenação aleatória.

---

## 14. Filtro por período

Disponibilizar:

    Data inicial

    Data final

Permitir consultar eventos de qualquer
período existente.

Não aplicar o horizonte de três dias
utilizado para criação de agendamentos.

O filtro deverá considerar a data
de realização do evento de auditoria.

Não confundir:

- Data do evento.
- Data originalmente agendada.

Exemplo:

    Agendamento criado em 25/11/2026.

    Data reservada: 27/11/2026.

Ao consultar eventos de 25/11/2026,
a criação deverá ser encontrada.

Utilizar o fuso America/Sao_Paulo.

Considerar os limites completos do dia.

Preferir intervalos com início inclusivo
e término exclusivo no início do dia seguinte.

Validar datas inválidas e períodos invertidos.

---

## 15. Filtro por tipo de evento

Disponibilizar:

    Todos os eventos
    Agendamento criado
    Alteração / Reagendamento
    Cancelamento
    Check-in
    Liberação
    No-show
    Bloqueio
    Desbloqueio

Utilizar os nomes técnicos existentes
para realizar as consultas.

Validar os parâmetros no backend.

Não concatenar parâmetros diretamente em SQL.

---

## 16. Filtro por entidade

Disponibilizar:

    Todas
    Agendamentos
    Bloqueios

Mapeamento conceitual:

    Booking
        Agendamentos

    SlotBlock
        Bloqueios

Utilizar uma lista explícita de entidades permitidas.

Não utilizar constantize ou métodos equivalentes
sobre parâmetros não confiáveis.

Não permitir que parâmetros recebidos determinem
arbitrariamente classes ou tabelas consultadas.

---

## 17. Pesquisa por protocolo

Permitir pesquisar eventos associados
ao protocolo de um agendamento.

Exemplo:

    DA-7F3A92B8C104

Localizar a reserva correspondente e consultar
os eventos relacionados ao seu ID interno.

A pesquisa deverá utilizar o protocolo
normalizado conforme a implementação existente.

Preferir inicialmente pesquisa exata.

Não pesquisar indiscriminadamente todos
os campos JSONB.

Não criar uma ferramenta de pesquisa global
complexa neste requisito.

O filtro por protocolo deverá ser compatível
somente com eventos de agendamentos.

Informar claramente quando não forem
encontrados resultados.

Não criar uma rota pública de pesquisa.

---

## 18. Limpar filtros

Disponibilizar o botão:

    Limpar filtros

Ao selecionar essa opção:

- Remover os filtros aplicados.
- Retornar à configuração padrão da página.
- Reiniciar a paginação.
- Preservar o layout administrativo.

Utilizar requisições GET.

Não realizar alterações no banco de dados.

---

## 19. Paginação

Implementar paginação no backend.

Utilizar inicialmente:

    25 eventos por página

Caso já exista um mecanismo de paginação
na aplicação, reutilizá-lo.

Não carregar todos os eventos em uma única
requisição.

Preservar os filtros durante a navegação
entre páginas.

Validar o número da página solicitado.

Impedir parâmetros que solicitem volumes
excessivos de registros.

Não introduzir uma biblioteca adicional
se a implementação existente for suficiente.

---

## 20. Detalhes do evento

Permitir visualizar os detalhes de um
evento específico.

Apresentar:

- Tipo do evento.
- Data e hora.
- Entidade relacionada.
- Protocolo, quando aplicável.
- Origem, quando identificável.
- Valores anteriores.
- Valores posteriores.
- Motivo.
- Observação, quando aplicável.

Exemplo:

    Evento: Agendamento alterado

    Protocolo: DA-XXXXXXXX

    Data do evento: 25/11/2026 14:32:15

    Origem: Painel administrativo

    Motivo:
    Alteração solicitada pela transportadora.

    Valores anteriores:

        Data: 26/11/2026
        Doca: 03
        Horário: 10:00 - 11:00

    Valores posteriores:

        Data: 27/11/2026
        Doca: 05
        Horário: 14:00 - 15:00

Utilizar o layout administrativo existente.

Não exigir modais complexos.

Não disponibilizar ações de edição
ou exclusão do evento.

---

## 21. Comparação de valores

Utilizar os atributos existentes:

    previous_values

    new_values

Apresentar os valores em formato legível.

Preferir uma tabela comparativa:

    Campo       | Anterior       | Novo
    ------------------------------------------
    Data        | 26/11/2026     | 27/11/2026
    Doca        | 03             | 05
    Horário     | 10:00 - 11:00  | 14:00 - 15:00
    Status      | Agendado       | Agendado

Destacar os campos efetivamente modificados.

Utilizar vermelho discreto para valores anteriores
e verde ou azul para os novos valores.

Não depender exclusivamente de cores.

Não apresentar campos técnicos desnecessários.

Não modificar os valores persistidos.

Quando um campo não possuir informação histórica,
apresentar:

    Não registrado

Não preencher valores históricos utilizando
os valores atuais da reserva.

---

## 22. Formatação dos campos

Centralizar a tradução dos campos técnicos.

Exemplo:

    booking_date
        Data agendada

    blocked_date
        Data bloqueada

    dock_number
        Doca

    slot_number
        Horário

    status
        Status

    checkin_at
        Horário de check-in

    released_at
        Horário de liberação

    release_remark
        Observação da liberação

    change_reason
        Motivo da alteração

    reason
        Motivo

Reutilizar os helpers existentes.

Não duplicar as definições de docas e janelas.

Preservar:

    8 docas

    10 janelas

    Última janela: 17:00 - 17:48

Caso as definições operacionais sejam alteradas
em requisitos futuros, avaliar uma estratégia
para preservar a interpretação histórica.

---

## 23. Formatação de datas e horários

Apresentar datas no padrão brasileiro:

    DD/MM/AAAA

Apresentar horários de auditoria:

    HH:mm:ss

Exemplo:

    26/11/2026 14:48:32

Utilizar o fuso operacional:

    America/Sao_Paulo

Preservar a estratégia de armazenamento
de timestamps definida no projeto.

Não utilizar o relógio do navegador
para determinar horários históricos.

---

## 24. Histórico individual do agendamento

Na página de detalhes de uma reserva,
adicionar uma seção denominada:

    Histórico do agendamento

Apresentar os eventos relacionados
ao ID interno da reserva.

Utilizar uma linha do tempo vertical.

Exemplo:

    25/11/2026 - 09:15

        Agendamento criado

        Doca 03
        Horário: 10:00 - 11:00

            |

    25/11/2026 - 14:32

        Agendamento alterado

        Anterior:
        Doca 03 - 10:00 - 11:00

        Novo:
        Doca 05 - 14:00 - 15:00

        Motivo:
        Solicitação da transportadora.

            |

    26/11/2026 - 14:05

        Check-in realizado

            |

    26/11/2026 - 14:48

        Veículo liberado

        Observação:
        Operação concluída sem ocorrências.

A linha do tempo deverá utilizar os eventos
efetivamente existentes na auditoria.

Não gerar eventos com base exclusivamente
no estado atual do agendamento.

---

## 25. Ordenação do histórico individual

Apresentar preferencialmente os eventos
em ordem cronológica crescente.

Exemplo:

    Criação
    Alteração
    Check-in
    Liberação

Utilizar ordenação determinística:

    created_at ASC
    id ASC

Permitir acompanhar a evolução da reserva
desde sua criação.

Limitar a quantidade de registros carregados
inicialmente quando o histórico for extenso.

Disponibilizar paginação ou uma opção de consulta
completa sem carregamento ilimitado de registros.

---

## 26. Identidade visual dos eventos

Utilizar ícones e cores consistentes
com o painel administrativo.

Sugestão:

    Agendamento criado
        Azul
        Ícone de calendário

    Alteração
        Azul ou laranja
        Ícone de edição

    Reagendamento
        Laranja
        Ícone de calendário com relógio

    Check-in
        Amarelo ou laranja
        Ícone de veículo

    Liberação
        Verde
        Ícone de confirmação

    Cancelamento
        Vermelho
        Ícone de cancelamento

    No-show
        Vermelho
        Ícone de alerta

    Bloqueio
        Cinza
        Ícone de cadeado

    Desbloqueio
        Verde ou azul
        Ícone de cadeado aberto

Reutilizar a biblioteca de ícones existente.

Não adicionar uma biblioteca exclusivamente
para representar o histórico.

Não utilizar cores como única forma
de identificação.

---

## 27. Histórico de criação

Apresentar os dados originais da criação
quando estiverem registrados no evento.

Exemplo:

    Protocolo: DA-XXXXXXXX

    Operação: Entrega

    Data originalmente agendada: 26/11/2026

    Doca original: 03

    Janela original: 10:00 - 11:00

Preservar a distinção entre:

- Dados registrados no momento da criação.
- Dados atuais da reserva.

Uma alteração posterior não deverá modificar
a apresentação dos dados originais.

Não reconstruir informações históricas ausentes
a partir dos valores atuais da reserva.

---

## 28. Histórico de cancelamento

Apresentar:

- Data e hora do cancelamento.
- Status anterior.
- Novo status.
- Posição existente no momento do cancelamento.
- Motivo registrado.

Exemplo:

    Agendamento cancelado

    Status anterior: Agendado

    Novo status: Cancelado

    Motivo:
    Veículo apresentou problema mecânico.

Preservar as informações existentes.

Não permitir reativação de reservas através
da interface de auditoria.

---

## 29. Histórico de alteração e reagendamento

Apresentar:

- Data anterior.
- Nova data.
- Doca anterior.
- Nova doca.
- Janela anterior.
- Nova janela.
- Status anterior.
- Novo status.
- Motivo da alteração.

Utilizar os valores existentes em:

    previous_values
    new_values

Não substituir os valores históricos
pela posição atual da reserva.

Quando existirem múltiplas alterações,
apresentar todas as ocorrências separadamente.

---

## 30. Histórico de check-in

Apresentar:

- Data e hora do evento.
- Horário efetivo de check-in.
- Status anterior.
- Novo status.

Exemplo:

    Check-in realizado

    Horário efetivo: 14:05:32

    Agendado -> Em operação

Não permitir alteração do horário
através da interface de histórico.

Não executar um novo check-in ao consultar
o evento.

---

## 31. Histórico de liberação

Apresentar:

- Data e hora do evento.
- Horário efetivo de liberação.
- Status anterior.
- Novo status.
- Observação da liberação.

Exemplo:

    Veículo liberado

    Horário efetivo: 14:48:15

    Em operação -> Liberado

    Observação:
    Operação concluída sem ocorrências.

Utilizar os valores registrados no evento.

Não permitir edição da observação histórica.

---

## 32. Histórico de no-show

Apresentar:

- Data e hora real do processamento.
- Status anterior.
- Novo status.
- Posição original, quando registrada.
- Motivo automático.
- Origem: Sistema automático.

Exemplo:

    Reagendamento obrigatório

    26/11/2026 - 17:30:04

    Agendado -> Reagendamento obrigatório

    Motivo:
    Não comparecimento até o horário limite
    de check-in.

Não apresentar o horário do evento como
se fosse necessariamente 17:30 exatas.

O processamento pode ocorrer posteriormente,
conforme as regras do RF008.

Preservar ocorrências múltiplas de no-show
da mesma reserva após novos reagendamentos.

Não disparar o processamento automático
ao consultar o histórico.

---

## 33. Histórico de bloqueios

Apresentar os eventos relacionados
à entidade SlotBlock.

Para cada bloqueio, exibir:

- Data e hora da criação do bloqueio.
- Data bloqueada.
- Doca.
- Janela.
- Motivo original.
- Identificação da operação.

Exemplo:

    Posição bloqueada

    Evento registrado em:
    25/11/2026 - 15:30:10

    Data bloqueada: 26/11/2026

    Doca: 03

    Horário: 10:00 - 11:00

    Motivo:
    Manutenção preventiva.

Utilizar os valores históricos registrados
na auditoria.

Não depender exclusivamente da existência
do registro atual em slot_blocks.

---

## 34. Histórico de desbloqueios

Uma operação de desbloqueio remove o registro
correspondente da tabela slot_blocks.

O evento de auditoria deverá continuar
disponível após essa remoção.

Apresentar:

- Data e hora do desbloqueio.
- Data originalmente bloqueada.
- Doca.
- Janela.
- Motivo original do bloqueio.

Exemplo:

    Posição desbloqueada

    Data: 26/11/2026

    Doca: 03

    Horário: 10:00 - 11:00

    Motivo original:
    Manutenção preventiva.

Utilizar previous_values e demais informações
existentes no evento.

Não exigir que o registro removido
continue existindo.

Não recriar o bloqueio para consultar
seu histórico.

---

## 35. Eventos de operações em lote

Os bloqueios e desbloqueios em lote
geram eventos individuais para cada posição.

Preservar esses eventos.

Não consolidar ou excluir eventos históricos.

Caso exista um identificador de lote
na implementação atual, utilizá-lo
para melhorar a apresentação.

Caso não exista, não agrupar operações
como se pertencessem necessariamente
ao mesmo lote apenas porque possuem
horários próximos ou motivos iguais.

Não criar novas estruturas de agrupamento
neste requisito.

---

## 36. Integridade da auditoria

A auditoria deverá funcionar como um
histórico somente de consulta.

Não permitir através da aplicação:

- Editar eventos existentes.
- Excluir eventos existentes.
- Sobrescrever motivos.
- Alterar horários históricos.
- Alterar valores anteriores.
- Alterar valores posteriores.

Avaliar as proteções existentes no model
e nos fluxos de persistência.

Garantir que a aplicação não possua caminhos
administrativos de edição ou exclusão
de eventos de auditoria.

Não utilizar apenas a ausência de botões
como mecanismo de proteção.

---

## 37. Proteção append-only

Avaliar a implementação de uma proteção
para que audit_events seja append-only.

Operações normais permitidas:

    INSERT
    SELECT

Operações que deverão ser impedidas
para o fluxo normal da aplicação:

    UPDATE
    DELETE

Priorizar uma proteção efetiva no PostgreSQL,
quando compatível com a infraestrutura existente.

Avaliar alternativas como:

- Privilégios específicos para a aplicação.
- Trigger de proteção contra UPDATE e DELETE.

Escolher uma estratégia simples e compatível
com o ambiente Docker e Rails existente.

Não introduzir mecanismos redundantes
sem necessidade.

Caso seja necessária uma migration:

- Criar uma nova migration.
- Preservar os eventos existentes.
- Documentar a proteção.
- Garantir compatibilidade com os testes.
- Documentar o procedimento de manutenção
  autorizado do banco de dados.

Não afirmar que a auditoria é absolutamente
imutável perante um administrador do banco
ou usuário com privilégios superiores.

A proteção deverá impedir alterações indevidas
através dos fluxos normais da aplicação.

Não implementar blockchain ou assinaturas
criptográficas neste requisito.

---

## 38. Preservação das transações

Preservar todas as garantias implementadas
nos requisitos anteriores.

A operação de negócio e seu evento
de auditoria deverão permanecer na mesma
transação quando essa for a regra existente.

Exemplo:

    Check-in confirmado
        +
    Evento de auditoria criado

Caso a auditoria falhe:

    A operação deverá ser revertida.

Não substituir os mecanismos atuais de auditoria
por callbacks genéricos sem necessidade.

Não comprometer:

- Criação de reservas.
- Idempotência.
- Controle de concorrência.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- Desbloqueios.
- No-show.

---

## 39. Consulta sem efeitos colaterais

As páginas de histórico deverão ser
exclusivamente de consulta.

Não criar novos eventos ao:

- Abrir a página de histórico.
- Consultar os detalhes de um evento.
- Aplicar filtros.
- Alterar a paginação.
- Consultar a linha do tempo.
- Atualizar a página.

Não executar alterações de negócio
através de requisições GET.

Não modificar a reserva relacionada
durante a consulta.

A proteção contra alterações dos eventos
não deverá impedir a criação de novas
auditorias pelos fluxos operacionais.

---

## 40. Retenção de informações

Preservar os eventos de auditoria existentes.

Não implementar:

- Exclusão automática.
- Expiração de eventos.
- Exclusão após 72 horas.
- Exclusão por idade do registro.
- Limpeza automática do histórico.
- Arquivamento externo.

Não excluir eventos relacionados a reservas
canceladas ou bloqueios removidos.

Uma política formal de retenção de dados
poderá ser definida posteriormente.

Não assumir que a retenção deverá ser
permanente sem avaliação futura dos requisitos
legais e operacionais.

---

## 41. Informações ausentes ou desconhecidas

Considerar que eventos históricos podem
possuir estruturas diferentes.

Tratar adequadamente:

- previous_values nulo.
- new_values nulo.
- Motivo não informado.
- Campos históricos ausentes.
- Entidade removida.
- Tipo de evento desconhecido.
- Origem não registrada.

Não provocar erros internos durante
a renderização desses eventos.

Para eventos desconhecidos, apresentar
uma descrição genérica.

Não interpretar arbitrariamente o conteúdo
de campos desconhecidos.

Não renderizar automaticamente todo o JSON
armazenado.

Não modificar ou excluir eventos considerados
incompletos.

---

## 42. Rotas administrativas

Criar as rotas necessárias dentro
do namespace administrativo existente.

Estrutura sugerida:

    GET /admin/audit_events

    GET /admin/audit_events/:id

Caso seja necessário consultar o histórico
individual separadamente:

    GET /admin/bookings/:id/history

A nomenclatura poderá ser adaptada
às convenções existentes.

Não criar rotas:

    POST /admin/audit_events

    PATCH /admin/audit_events/:id

    PUT /admin/audit_events/:id

    DELETE /admin/audit_events/:id

A criação de eventos deverá continuar
sendo responsabilidade dos fluxos de negócio.

Não criar APIs públicas de auditoria.

---

## 43. Organização do backend

Manter os controllers pequenos.

Utilizar preferencialmente:

- Controller administrativo de auditoria.
- Model de auditoria existente.
- Query objects ou scopes, quando necessários.
- Helpers ou presenters para formatação.
- Partials reutilizáveis.

Estrutura conceitual:

    app/
    ├── controllers/
    │   └── admin/
    │       └── audit_events_controller.rb
    │
    ├── helpers/
    │   └── audit_events_helper.rb
    │
    └── views/
        └── admin/
            ├── audit_events/
            │   ├── index.html.erb
            │   ├── show.html.erb
            │   ├── _filters.html.erb
            │   └── _event.html.erb
            │
            └── bookings/
                └── _history.html.erb

Adaptar à organização atual do projeto.

Não reorganizar arquivos sem necessidade.

Não criar abstrações genéricas desnecessárias.

Não executar consultas diretamente nas views.

---

## 44. Consultas e desempenho

Utilizar consultas Active Record eficientes.

Preservar os índices existentes.

Avaliar especialmente consultas por:

- entity_type
- entity_id
- created_at
- action

Evitar consultas N+1.

Para eventos relacionados a agendamentos,
carregar os protocolos necessários
de maneira agrupada.

Não realizar uma consulta independente
para cada evento da tabela.

Não carregar todos os registros históricos
na memória.

Aplicar os filtros e a paginação no PostgreSQL.

Avaliar os planos de execução quando necessário.

Adicionar índices somente quando houver
necessidade demonstrável.

Documentar eventuais índices adicionados.

Não adicionar:

- Elasticsearch.
- Redis.
- Banco de dados secundário.
- Cache externo.

---

## 45. Segurança e privacidade

Preservar todas as proteções implementadas
nos requisitos anteriores.

O histórico poderá conter dados
operacionais e informações internas.

Não disponibilizar essas informações
em páginas públicas.

Não apresentar automaticamente todos
os atributos armazenados nos campos JSONB.

Utilizar uma lista explícita de campos
permitidos para apresentação.

Não exibir:

- Credenciais.
- Tokens.
- Cookies.
- Informações de sessão.
- Segredos de infraestrutura.
- Request ID.
- Dados pessoais desnecessários.

Utilizar escaping padrão do ERB.

Não utilizar raw ou html_safe para
apresentar motivos e observações.

Configurar os cabeçalhos de cache apropriados
para páginas administrativas.

Não registrar o conteúdo integral da auditoria
nos logs das requisições.

Preservar a Content Security Policy.

Manter as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

---

## 46. Usuários e operadores

Não implementar cadastro de usuários
neste requisito.

Não criar:

- Login.
- Autenticação.
- Autorização.
- Sessões administrativas.
- Perfis.
- Permissões.
- Usuário administrador padrão.

Não adicionar nomes fictícios aos eventos.

Documentar que a auditoria atual
não identifica individualmente os operadores.

A identificação do responsável por cada ação
deverá ser tratada quando forem implementados
os requisitos de usuários e autenticação.

Não disponibilizar o painel administrativo
em produção antes da implementação das
proteções definitivas de acesso.

---

## 47. JavaScript

Priorizar HTML, CSS e ERB.

Não utilizar JavaScript para:

- Consultar diretamente o PostgreSQL.
- Interpretar regras de negócio.
- Determinar a origem definitiva dos eventos.
- Alterar registros históricos.
- Executar operações administrativas.
- Modificar valores de auditoria.

Não introduzir:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Handlers JavaScript inline.
- Scripts de CDNs.

Preservar a CSP existente.

Não implementar polling na página
de histórico neste requisito.

O polling existente do Dashboard
deverá continuar funcionando normalmente.

---

## 48. Responsividade

Preservar a identidade visual administrativa.

Priorizar a utilização em computadores.

Garantir:

- Filtros organizados.
- Tabela legível.
- Paginação acessível.
- Linha do tempo organizada.
- Motivos e observações sem sobreposição.
- Contraste adequado.
- Navegação por teclado.

Em dispositivos menores:

- Adaptar os filtros.
- Permitir scroll horizontal somente na tabela
  quando necessário.
- Preservar a legibilidade da linha do tempo.
- Permitir quebra de linhas em textos longos.

Não provocar scroll horizontal
em toda a página.

---

## 49. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 49.1 Auditoria geral

Validar:

- Acesso à página de histórico.
- Exibição dos eventos existentes.
- Ordenação dos eventos.
- Paginação.
- Consulta dos detalhes de um evento.
- Tratamento de evento inexistente.
- Estado vazio quando não existirem registros.

### 49.2 Filtros

Validar:

- Filtro por data inicial.
- Filtro por data final.
- Filtro por período.
- Filtro por evento.
- Filtro por entidade.
- Pesquisa por protocolo.
- Combinação de filtros.
- Preservação dos filtros na paginação.
- Limpeza dos filtros.
- Datas inválidas.
- Período invertido.
- Parâmetros desconhecidos.
- Limites de paginação.

### 49.3 Histórico individual

Validar:

- Exibição dos eventos da reserva correta.
- Ausência de eventos de outras reservas.
- Ordenação cronológica.
- Exibição da criação.
- Exibição de alterações sucessivas.
- Exibição do cancelamento.
- Exibição do reagendamento.
- Exibição do check-in.
- Exibição da liberação.
- Exibição de no-show.
- Preservação dos valores históricos.

### 49.4 Comparação de valores

Validar:

- Valores anteriores apresentados corretamente.
- Valores posteriores apresentados corretamente.
- Campos alterados identificados.
- Datas formatadas.
- Horários formatados.
- Status traduzidos.
- Docas formatadas.
- Última janela terminando às 17:48.

### 49.5 Bloqueios

Validar:

- Histórico de criação do bloqueio.
- Histórico de desbloqueio.
- Consulta após remoção de slot_blocks.
- Preservação do motivo original.
- Preservação dos valores históricos.
- Exibição de múltiplos eventos de um lote.

### 49.6 No-show

Validar:

- Exibição do motivo automático.
- Origem identificada como Sistema automático.
- Data efetiva de processamento.
- Múltiplas ocorrências após reagendamento.
- Ausência de alterações durante a consulta.

### 49.7 Integridade

Validar:

- Eventos não podem ser editados
  pelos fluxos normais da aplicação.
- Eventos não podem ser excluídos
  pelos fluxos normais da aplicação.
- Novos eventos continuam sendo criados.
- Proteção append-only, quando implementada.
- Proteção efetiva no banco, quando adotada.
- Preservação dos registros existentes.
- Ausência de rotas administrativas de escrita.

### 49.8 Transações

Validar que as garantias anteriores
continuam funcionando.

Incluindo:

- Criação de reservas.
- Cancelamentos.
- Reagendamentos.
- Check-ins.
- Liberações.
- Bloqueios.
- Desbloqueios.
- No-show.
- Rollback em caso de falha da auditoria.

### 49.9 Eventos incompletos

Validar:

- previous_values nulo.
- new_values nulo.
- Motivo ausente.
- Origem desconhecida.
- Entidade removida.
- Tipo de evento desconhecido.
- Campos históricos não registrados.

Não gerar erros internos.

Não inventar informações ausentes.

### 49.10 Segurança

Validar:

- Tentativa de XSS em motivos.
- Tentativa de XSS em observações.
- Tentativa de SQL Injection nos filtros.
- Manipulação do tipo de entidade.
- Manipulação de identificadores.
- Ausência de exposição de dados sensíveis.
- Ausência de endpoints públicos de auditoria.
- Rotas administrativas indisponíveis em produção.
- Content Security Policy preservada.

### 49.11 Desempenho

Validar:

- Paginação realizada no backend.
- Quantidade limitada de registros.
- Ausência de consultas N+1.
- Consultas agrupadas de referências.
- Funcionamento com volume representativo
  de registros históricos.

### 49.12 Regressão

Executar todos os testes existentes
dos RF001 até RF010.

Não remover ou enfraquecer testes anteriores.

Não declarar como aprovado um teste
que não tenha sido executado.

---

## 50. Validação manual

### Cenário 01 — Histórico completo

1. Criar um agendamento.
2. Alterar sua posição.
3. Registrar o check-in.
4. Registrar a liberação.
5. Acessar os detalhes da reserva.
6. Consultar a linha do tempo.
7. Verificar a sequência dos eventos.
8. Conferir os valores anteriores e posteriores.
9. Confirmar a preservação do protocolo.

### Cenário 02 — Cancelamento

1. Criar uma reserva.
2. Cancelar a reserva.
3. Informar um motivo.
4. Consultar o histórico.
5. Verificar o evento de cancelamento.
6. Conferir o motivo registrado.

### Cenário 03 — Bloqueio e desbloqueio

1. Bloquear uma posição.
2. Informar um motivo.
3. Desbloquear a posição.
4. Acessar a auditoria geral.
5. Localizar ambos os eventos.
6. Confirmar a preservação do histórico
   após a remoção do bloqueio.

### Cenário 04 — No-show

1. Preparar uma reserva elegível
   em ambiente isolado de teste.
2. Executar o processamento com tempo controlado.
3. Consultar o histórico da reserva.
4. Confirmar o evento de no-show.
5. Confirmar a origem automática.
6. Reagendar a reserva.
7. Verificar a preservação do evento anterior.

### Cenário 05 — Filtros

1. Acessar o menu Histórico.
2. Filtrar por período.
3. Filtrar por evento.
4. Filtrar por entidade.
5. Pesquisar um protocolo.
6. Navegar entre páginas.
7. Limpar os filtros.
8. Conferir os resultados.

### Cenário 06 — Integridade

1. Verificar que não existem ações de edição.
2. Verificar que não existem ações de exclusão.
3. Validar as proteções do backend.
4. Validar as proteções de persistência adotadas.
5. Confirmar que novos eventos continuam
   sendo registrados normalmente.

Utilizar exclusivamente dados de teste
ou um ambiente isolado.

Não realizar testes destrutivos sobre
registros operacionais existentes.

Não alterar o relógio do sistema operacional.

---

## 51. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Verificar também:

- Console do navegador.
- Carregamento dos assets.
- Responsividade.
- Paginação.
- Filtros.
- Linha do tempo.
- Ausência de erros de renderização.
- Ausência de violações inesperadas de CSP.

Não desabilitar verificações para
obter resultados positivos.

Registrar os resultados efetivos.

---

## 52. Documentação

Registrar o requisito em:

    docs/requisitos/RF011.md

Atualizar o índice de requisitos.

Documentar:

- Menu Histórico.
- Auditoria geral.
- Histórico individual.
- Tipos de eventos.
- Mapeamento de origens.
- Filtros.
- Paginação.
- Formatação dos valores.
- Tratamento de dados históricos ausentes.
- Estratégia de consultas.
- Proteção append-only.
- Limitações da proteção.
- Preservação das transações.
- Tratamento de bloqueios removidos.
- Ausência de identificação individual
  dos operadores nesta etapa.
- Política atual de preservação do histórico.

Atualizar a documentação do banco
caso exista alteração estrutural.

Criar ADR somente quando houver
uma decisão arquitetural relevante.

---

## 53. Critérios de aceite

### Auditoria geral

- [ ] Menu Histórico implementado.
- [ ] Página de auditoria geral implementada.
- [ ] Tabela de eventos funcional.
- [ ] Detalhes dos eventos disponíveis.
- [ ] Ordenação determinística.
- [ ] Filtro por período.
- [ ] Filtro por evento.
- [ ] Filtro por entidade.
- [ ] Pesquisa por protocolo.
- [ ] Paginação funcional.
- [ ] Limpeza de filtros funcional.

### Histórico individual

- [ ] Linha do tempo implementada.
- [ ] Histórico associado à reserva correta.
- [ ] Criação apresentada.
- [ ] Alterações apresentadas.
- [ ] Reagendamentos apresentados.
- [ ] Cancelamentos apresentados.
- [ ] Check-ins apresentados.
- [ ] Liberações apresentadas.
- [ ] No-shows apresentados.
- [ ] Valores anteriores preservados.
- [ ] Valores posteriores apresentados.
- [ ] Motivos apresentados.
- [ ] Observações apresentadas.

### Bloqueios

- [ ] Eventos de bloqueio apresentados.
- [ ] Eventos de desbloqueio apresentados.
- [ ] Histórico preservado após remoção.
- [ ] Motivos originais preservados.
- [ ] Eventos em lote preservados.

### Integridade

- [ ] Auditoria exclusivamente de consulta.
- [ ] Ausência de rotas de edição.
- [ ] Ausência de rotas de exclusão.
- [ ] Proteção append-only avaliada e implementada.
- [ ] Limitações da proteção documentadas.
- [ ] Novas auditorias continuam funcionando.
- [ ] Transações anteriores preservadas.
- [ ] Nenhum histórico excluído.
- [ ] Nenhum evento fictício criado.
- [ ] Nenhum usuário fictício criado.
- [ ] Nenhum dado histórico ausente inventado.

### Interface

- [ ] Layout administrativo preservado.
- [ ] Sidebar preservada.
- [ ] Identidade visual preservada.
- [ ] Datas no padrão brasileiro.
- [ ] Horários no fuso operacional.
- [ ] Eventos apresentados em português.
- [ ] Interface responsiva.
- [ ] Estados vazios tratados.
- [ ] Campos desconhecidos tratados.

### Segurança

- [ ] Escaping padrão do ERB preservado.
- [ ] Consultas parametrizadas.
- [ ] Filtros validados.
- [ ] Nenhuma exposição pública da auditoria.
- [ ] Nenhuma exposição desnecessária de dados.
- [ ] Content Security Policy preservada.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma autenticação provisória criada.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de integridade executados.
- [ ] Testes de segurança executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 54. Fora do escopo

Não implementar neste requisito:

- Exportação Excel.
- Exportação CSV.
- Relatórios PDF.
- Upload de documentos.
- Notificações por e-mail.
- Notificações por WhatsApp.
- Cadastro de usuários.
- Login.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Identificação individual dos operadores.
- Exclusão de histórico.
- Expiração automática de registros.
- Arquivamento externo.
- Blockchain.
- Assinatura criptográfica dos eventos.
- Monitoramento externo.
- Integração com sistemas de segurança.
- Elasticsearch.
- Redis.
- Novos indicadores do Dashboard.
- Redesign do painel administrativo.
- Implantação na VPS.

Implementar exclusivamente a consulta
do histórico e a proteção da auditoria.

---

## 55. Entrega

Ao concluir o RF011, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.
- Limitações identificadas.

### Interface

- Screenshot da página de auditoria geral.
- Screenshot dos filtros.
- Screenshot dos detalhes de um evento.
- Screenshot da comparação de valores.
- Screenshot da linha do tempo de uma reserva.

### Backend

- Rotas criadas.
- Controllers criados ou modificados.
- Models modificados.
- Helpers criados ou reutilizados.
- Views e partials.
- Estratégia de consultas.
- Estratégia de paginação.

### Banco de dados

- Estrutura utilizada.
- Índices utilizados.
- Eventuais migrations e justificativas.
- Proteção append-only adotada.
- Limitações da proteção.

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
- Resultado do RuboCop.
- Testes de integridade.
- Testes de regressão.
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

Informar qualquer problema, limitação
ou decisão que necessite de homologação.

---

## 56. Regra de parada

Ao concluir o RF011, PARE.

Não implementar o RF012.

Não implementar exportação Excel.

Não implementar cadastro de usuários.

Não implementar autenticação ou autorização.

Não alterar desnecessariamente o layout
administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.