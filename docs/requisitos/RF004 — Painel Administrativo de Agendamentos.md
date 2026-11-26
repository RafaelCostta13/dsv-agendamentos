# RF004 — Painel Administrativo de Agendamentos

## 1. Objetivo

Implementar a estrutura inicial do painel administrativo
da aplicação DSV Doca Agenda.

O painel deverá permitir acompanhar os agendamentos
realizados através do formulário implementado no RF003.

Neste requisito, implementar:

- Layout administrativo.
- Header.
- Sidebar.
- Área de conteúdo.
- Dashboard operacional.
- Indicadores de agendamentos.
- Seletor de data.
- Matriz de docas e horários.
- Lista de agendamentos.
- Visualização dos detalhes de uma reserva.

Neste primeiro momento, o painel será exclusivamente
para consulta.

Não implementar ações que alterem o estado dos
agendamentos.

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
- docs/referencias/

Analisar o código existente antes de implementar.

Preservar a arquitetura monolítica Ruby on Rails.

Não modificar o formulário de agendamento existente.

---

## 3. Arquitetura

Utilizar os recursos nativos do Ruby on Rails:

- Routes.
- Controllers.
- Models.
- Active Record.
- Views ERB.
- Layouts.
- Helpers.
- Partials.
- CSS.

Priorizar renderização no servidor.

Não criar uma aplicação frontend independente.

Não criar uma API JSON exclusivamente para alimentar
o próprio Dashboard.

Não introduzir:

- React.
- Vue.
- Angular.
- SPA.
- Node.js.
- TypeScript.
- Bibliotecas JavaScript desnecessárias.

Utilizar JavaScript somente quando necessário para
melhorar a interação com a interface.

---

## 4. Rotas administrativas

Disponibilizar inicialmente:

    GET /admin
    GET /admin/bookings
    GET /admin/bookings/:id

Responsabilidades:

- /admin: Dashboard operacional.
- /admin/bookings: Lista de agendamentos.
- /admin/bookings/:id: Detalhes do agendamento.

Utilizar namespace administrativo do Rails.

Organização sugerida:

    Admin::DashboardController
    Admin::BookingsController

Não criar rotas de alteração ou exclusão de reservas
neste requisito.

Não implementar autenticação ou autorização neste RF.

O namespace admin não representa um mecanismo
de segurança.

O painel deverá permanecer restrito ao ambiente
local de desenvolvimento.

Não disponibilizar o painel em produção antes da
implementação de autenticação e autorização.

---

## 5. Layout administrativo

Criar um layout exclusivo para as views administrativas.

Estrutura:

    +----------------------------------------------+
    |                    HEADER                    |
    +------------+---------------------------------+
    |            |                                 |
    |            |                                 |
    |  SIDEBAR   |        ÁREA DE CONTEÚDO          |
    |            |                                 |
    |            |                                 |
    +------------+---------------------------------+

Criar o layout preferencialmente em:

    app/views/layouts/admin.html.erb

Utilizar partials para os elementos compartilhados.

Organização sugerida:

    app/views/admin/shared/_header.html.erb
    app/views/admin/shared/_sidebar.html.erb

Não duplicar o Header ou a Sidebar em cada view.

O layout público da página /agendar deverá
permanecer independente.

---

## 6. Identidade visual

Utilizar a identidade visual corporativa da DSV.

Priorizar:

- Azul institucional.
- Azul escuro.
- Branco.
- Cinza claro.
- Bordas discretas.
- Tipografia legível.
- Componentes compactos.
- Espaçamento consistente.

Utilizar como referência:

    Azul institucional: #002664
    Fundo principal:    #F3F6FA
    Fundo dos cards:    #FFFFFF
    Texto principal:    #10243E
    Texto secundário:   #64748B
    Bordas:             #D5DFEC

Reutilizar as cores e os estilos já existentes
quando apropriado.

Evitar:

- Gradientes.
- Sombras excessivas.
- Animações desnecessárias.
- Excesso de elementos decorativos.

O Codex poderá propor melhorias visuais sem
alterar os comportamentos definidos neste RF.

---

## 7. Logo oficial

Utilizar o mesmo arquivo de logo utilizado
no formulário público:

    app/assets/images/DSV_Logo.svg

Utilizar o sistema de assets do Rails.

Preservar:

- Proporções.
- Cores.
- Formato.
- Qualidade visual.

Não redesenhar o logo.

Não criar cópias desnecessárias do arquivo.

Não utilizar URLs externas para carregar o logo.

---

## 8. Header

Criar um Header administrativo.

Exibir:

- Logo DSV.
- Nome Doca Agenda.
- Identificação do painel administrativo.

Características:

- Fundo branco.
- Altura compacta.
- Alinhamento horizontal.
- Identidade visual consistente.

Não implementar:

- Nome de usuário.
- Avatar de usuário.
- Botão de logout.
- Notificações.
- Menu de perfil.

Esses componentes serão adicionados quando
as respectivas funcionalidades existirem.

---

## 9. Sidebar

Criar uma Sidebar administrativa.

Utilizar preferencialmente fundo azul institucional.

Disponibilizar inicialmente os menus funcionais:

- Dashboard.
- Agendamentos.

Preparar visualmente a estrutura para expansão
dos menus em requisitos futuros.

Os menus futuros poderão incluir:

- Bloqueios.
- Histórico.
- Configurações.
- Usuários.

Não criar links quebrados.

Não criar páginas fictícias apenas para representar
funcionalidades futuras.

Identificar visualmente o menu ativo.

Não depender exclusivamente de JavaScript para
a navegação entre páginas.

Utilizar links e helpers nativos do Rails.

---

## 10. Dashboard operacional

A rota /admin deverá apresentar o Dashboard.

Estrutura:

1. Título da página.
2. Seletor de data.
3. Indicadores operacionais.
4. Matriz de docas e horários.
5. Legenda dos estados.

A data inicial deverá corresponder ao dia atual,
considerando o fuso America/Sao_Paulo.

Não utilizar dados fictícios na interface.

Todas as informações deverão ser obtidas através
do PostgreSQL e das definições operacionais do Rails.

---

## 11. Seletor de data

Disponibilizar um seletor de data no Dashboard.

Permitir:

- Consultar o dia atual.
- Consultar datas futuras.
- Consultar datas anteriores.

Não aplicar ao painel administrativo o limite
de três datas utilizado no formulário público.

Esse limite é uma regra de criação de reservas,
não uma regra de consulta administrativa.

Utilizar requisições GET para alterar a data
visualizada.

Exemplo:

    /admin?date=2026-11-25

Validar o parâmetro no backend.

Não permitir que datas inválidas provoquem
erros internos.

Utilizar o fuso America/Sao_Paulo.

Manter a data selecionada durante a navegação
relacionada à consulta.

---

## 12. Indicadores operacionais

Criar quatro cards na parte superior do Dashboard.

### 12.1 Agendamentos

Exibir a quantidade de reservas que consomem
capacidade na data selecionada.

Considerar os estados:

- agendado
- em_operacao
- liberado

Não incluir:

- cancelado
- reagendamento

### 12.2 Horários disponíveis

Exibir a quantidade de posições que ainda
podem receber novos agendamentos.

Considerar:

- Data selecionada.
- Docas existentes.
- Janelas existentes.
- Reservas que consomem capacidade.
- Bloqueios.
- Horizonte permitido para novas reservas.
- Horários já iniciados no dia atual.

Reutilizar a lógica de disponibilidade do RF003.

Não duplicar regras de disponibilidade no Dashboard.

Para datas anteriores ou fora do horizonte permitido,
o indicador deverá ser zero.

Não confundir capacidade nominal com capacidade
efetivamente disponível para agendamento.

### 12.3 Entregas

Exibir a quantidade de reservas de entrega
que consomem capacidade na data selecionada.

### 12.4 Coletas

Exibir a quantidade de reservas de coleta
que consomem capacidade na data selecionada.

Todos os indicadores deverão ser calculados
no backend.

Não utilizar valores fixos.

Não utilizar JavaScript para realizar os cálculos.

---

## 13. Matriz de docas

Criar uma matriz operacional contendo:

- Oito linhas de docas.
- Dez colunas de janelas.
- Oitenta posições nominais.

Docas:

    Doca 01
    Doca 02
    Doca 03
    Doca 04
    Doca 05
    Doca 06
    Doca 07
    Doca 08

Janelas:

    01 - 08:00 às 09:00
    02 - 09:00 às 10:00
    03 - 10:00 às 11:00
    04 - 11:00 às 12:00
    05 - 12:00 às 13:00
    06 - 13:00 às 14:00
    07 - 14:00 às 15:00
    08 - 15:00 às 16:00
    09 - 16:00 às 17:00
    10 - 17:00 às 17:48

Reutilizar as definições centralizadas no backend.

Não criar tabelas docks ou time_slots.

Não duplicar definições de docas e horários.

Não alterar os horários existentes.

Não criar registros no banco para representar
posições vazias.

A matriz deverá ser construída a partir das
definições fixas e dos registros existentes.

---

## 14. Estados da matriz

Cada posição deverá representar seu estado real.

### 14.1 Disponível

Posição livre e elegível para novo agendamento.

Utilizar fundo neutro ou verde claro.

### 14.2 Agendado

Existe uma reserva com status agendado.

Utilizar azul.

### 14.3 Em operação

Existe uma reserva com status em_operacao.

Utilizar amarelo ou laranja.

### 14.4 Liberado

Existe uma reserva com status liberado.

Utilizar verde.

A liberação física da doca não torna o slot
original disponível novamente.

### 14.5 Bloqueado

Existe um bloqueio correspondente na tabela
slot_blocks.

Utilizar cinza e indicador visual de bloqueio.

### 14.6 Horário encerrado

Posição sem reserva ou bloqueio cujo horário
já foi iniciado ou cuja data já passou.

Utilizar uma aparência neutra e desabilitada.

Não permitir que seja apresentada como posição
disponível para nova reserva.

### 14.7 Fora do horizonte

Posição livre em uma data futura que ainda
não pode receber novas reservas.

Identificar como fora do período de agendamento.

Não apresentar como disponível para reserva.

---

## 15. Cancelamentos e reagendamentos na matriz

Reservas com os estados:

- cancelado
- reagendamento

não deverão consumir capacidade.

Esses registros deverão permanecer disponíveis
na lista de agendamentos.

Não utilizar um registro cancelado para
representar uma posição ocupada.

Não esconder uma reserva ativa porque existe
um registro histórico cancelado no mesmo slot.

Caso existam simultaneamente uma reserva que
consome capacidade e um bloqueio para a mesma
posição, apresentar uma indicação de inconsistência.

Não ocultar ou corrigir automaticamente essa
inconsistência neste requisito.

---

## 16. Legenda

Apresentar uma legenda dos estados da matriz:

- Disponível.
- Agendado.
- Em operação.
- Liberado.
- Bloqueado.
- Horário encerrado.
- Fora do horizonte.

Utilizar cores consistentes.

Não depender exclusivamente da cor para
comunicar o estado.

Utilizar também textos, ícones ou indicadores
acessíveis.

---

## 17. Seleção de uma reserva

Ao selecionar uma posição que possua uma
reserva, permitir acessar seus detalhes.

Utilizar preferencialmente um link nativo
do Rails.

A posição poderá apresentar:

- Status.
- Protocolo resumido.
- Empresa, quando houver espaço adequado.

Não sobrecarregar a matriz com todos os
campos da reserva.

A consulta completa deverá ocorrer na
página de detalhes.

Não implementar modais complexos ou
manipulação excessiva do DOM.

Não criar ações de alteração ao selecionar
uma posição vazia.

---

## 18. Lista de agendamentos

Criar a página:

    /admin/bookings

Apresentar os registros existentes no PostgreSQL.

A tabela deverá possuir as seguintes colunas:

- Protocolo.
- Data agendada.
- Horário.
- Doca.
- Operação.
- Responsável.
- Empresa / transportadora.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Status.
- Ação de visualizar.

Apresentar os estados em português do Brasil.

Mapeamento:

    agendado      -> Agendado
    em_operacao   -> Em operação
    liberado      -> Liberado
    cancelado     -> Cancelado
    reagendamento -> Reagendamento obrigatório

Preservar zeros à esquerda da nota fiscal.

Ordenar os registros de forma determinística,
preferencialmente por:

1. Data agendada.
2. Janela.
3. Doca.
4. Identificador interno.

---

## 19. Filtros da lista

Disponibilizar filtros simples por:

- Data.
- Doca.
- Tipo de operação.
- Status.

Os filtros deverão funcionar através de
requisições GET.

Utilizar consultas Active Record parametrizadas.

Validar os parâmetros recebidos.

Não concatenar valores diretamente em SQL.

Não carregar todos os registros no navegador
para realizar filtragem com JavaScript.

Implementar paginação simples quando necessário.

Limitar a quantidade de registros retornados
por consulta.

Manter os filtros durante a navegação
entre páginas de resultados.

---

## 20. Detalhes do agendamento

Criar a página:

    /admin/bookings/:id

Exibir os dados da reserva:

### Identificação

- Protocolo.
- Status.
- Data de criação.

### Responsável

- Nome.
- Empresa / transportadora.

### Veículo e nota fiscal

- Número da NF.
- Placa.
- Modelo do veículo.

### Agendamento

- Operação.
- Data agendada.
- Doca.
- Horário inicial.
- Horário final.

### Controle operacional

Quando existentes:

- Horário de check-in.
- Horário de liberação.
- Observação da liberação.
- Motivo da alteração.

Exibir campos ainda não preenchidos como:

    Não registrado

Disponibilizar uma opção de retorno
à lista ou ao Dashboard.

Não implementar botões de:

- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Alteração.
- Exclusão.

Essas ações serão implementadas em
requisitos posteriores.

---

## 21. Atualização das informações

Neste primeiro momento, utilizar consultas
normais ao servidor.

Disponibilizar um botão:

    Atualizar

Ao clicar, atualizar os dados da data
selecionada.

Não implementar neste requisito:

- Polling automático.
- WebSockets.
- Action Cable.
- Turbo Streams.
- Atualizações em tempo real.

A atualização automática será avaliada
posteriormente.

Não apresentar informações como atualizadas
em tempo real quando esse recurso não existe.

---

## 22. Consultas e desempenho

Evitar consultas individuais para cada
posição da matriz.

Não executar oitenta consultas ao banco
para construir as oitenta posições.

Carregar os agendamentos e bloqueios
da data selecionada em consultas agrupadas.

Organizar os resultados no backend
por combinação de:

- Data.
- Doca.
- Janela.

Reutilizar os resultados na construção
da matriz e dos indicadores.

Não executar consultas diretamente
nas views ERB.

Evitar N+1.

Não adicionar Redis ou cache externo.

Não realizar otimizações prematuras.

---

## 23. Responsividade

O painel administrativo será utilizado
principalmente em computadores.

Priorizar resoluções:

    1280 x 720
    1366 x 768
    1440 x 900
    1920 x 1080

Também permitir utilização em tablets
e dispositivos móveis.

Em telas menores:

- Adaptar os cards de indicadores.
- Adaptar a Sidebar.
- Permitir scroll horizontal exclusivamente
  na matriz e nas tabelas quando necessário.
- Preservar a legibilidade.
- Evitar sobreposição de elementos.

Não permitir que a matriz provoque
scroll horizontal em toda a página.

---

## 24. CSS

Utilizar CSS local e o sistema de assets
existente no Rails.

Organizar os estilos administrativos
sem interferir na página /agendar.

Utilizar:

- CSS Grid.
- Flexbox.
- Variáveis CSS.
- Classes reutilizáveis.

Evitar:

- CSS inline.
- Estilos duplicados.
- Uso excessivo de !important.
- Frameworks CSS desnecessários.
- Dependências externas.

Manter a aparência do formulário público
já homologado.

---

## 25. JavaScript

Utilizar o mínimo necessário.

O Dashboard deverá funcionar prioritariamente
através de renderização no servidor.

Não utilizar JavaScript para:

- Consultar diretamente o PostgreSQL.
- Definir estados das reservas.
- Calcular disponibilidade.
- Calcular indicadores operacionais.
- Implementar regras de negócio.
- Controlar permissões.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Scripts inline.
- Scripts de CDNs.

Não enfraquecer a Content Security Policy.

---

## 26. Segurança

Preservar todas as configurações de
segurança dos requisitos anteriores.

Utilizar escaping padrão do ERB.

Considerar os dados das reservas como
conteúdo não confiável.

Não utilizar raw ou html_safe para exibir:

- Nome.
- Empresa.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Observações.

Não expor dados sensíveis em logs.

Não apresentar informações internas do
PostgreSQL nas páginas de erro.

Não publicar endpoints administrativos
na Internet.

Enquanto não existir autenticação, restringir
as rotas administrativas ao ambiente development
e aos testes automatizados.

Não implementar uma autenticação provisória.

Não criar credenciais administrativas fixas.

---

## 27. Banco de dados

Utilizar as tabelas existentes:

- bookings
- slot_blocks
- audit_events

Não criar migrations neste requisito.

Não modificar os tipos dos atributos existentes.

Não alterar índices ou constraints sem
necessidade relacionada ao requisito.

Não modificar registros para gerar
indicadores ou preencher o Dashboard.

Não criar agendamentos fictícios nos seeds.

O painel deverá apresentar os dados
efetivamente existentes.

---

## 28. Testes automatizados

Utilizar Minitest e PostgreSQL.

Validar:

- Acesso ao Dashboard no desenvolvimento.
- Acesso à lista de agendamentos.
- Consulta dos detalhes de uma reserva.
- Tratamento de reserva inexistente.
- Seleção de data válida.
- Tratamento de data inválida.
- Consulta de datas anteriores.
- Consulta de datas futuras.
- Exibição das oito docas.
- Exibição das dez janelas.
- Exibição correta da última janela.
- Cálculo dos quatro indicadores.
- Exibição de reservas agendadas.
- Exibição de reservas em operação.
- Exibição de reservas liberadas.
- Exibição de bloqueios.
- Exibição de horários encerrados.
- Exibição de posições fora do horizonte.
- Reservas canceladas não consomem capacidade.
- Reservas em reagendamento não consomem capacidade.
- Reservas liberadas continuam consumindo capacidade.
- Filtros da lista.
- Limites de registros retornados.
- Ausência de duplicidade nos indicadores.
- Ausência de consultas individuais por célula.
- Escaping de conteúdo fornecido pelo usuário.
- Proteção contra XSS armazenado.
- Proteção contra SQL Injection nos filtros.
- Indisponibilidade das rotas em produção
  enquanto não houver autenticação.

Executar todos os testes existentes.

Não remover ou enfraquecer testes anteriores.

---

## 29. Validação visual

Validar o painel no navegador.

Verificar:

- Header.
- Logo.
- Sidebar.
- Menu ativo.
- Indicadores.
- Matriz.
- Legenda.
- Seletor de data.
- Lista de agendamentos.
- Filtros.
- Página de detalhes.
- Estados vazios.
- Responsividade.
- Console do navegador.

Não deverão existir:

- Erros JavaScript.
- Violações inesperadas de CSP.
- Recursos não encontrados.
- Links quebrados.
- Componentes sobrepostos.
- Dados fictícios apresentados como reais.

---

## 30. Documentação

Registrar este requisito em:

    docs/requisitos/RF004.md

Atualizar:

- README.md.
- Índice de requisitos.

Documentar:

- Rotas administrativas.
- Estrutura das views.
- Layout administrativo.
- Cálculo dos indicadores.
- Construção da matriz.
- Estratégia de consultas.
- Estados visuais.
- Limitação de acesso ao desenvolvimento.
- Pendências operacionais.

Criar ADR somente quando existir uma
decisão arquitetural relevante.

---

## 31. Critérios de aceite

- [ ] Layout administrativo independente.
- [ ] Header implementado.
- [ ] Logo oficial utilizado.
- [ ] Sidebar implementada.
- [ ] Dashboard funcional.
- [ ] Lista de agendamentos funcional.
- [ ] Página de detalhes funcional.
- [ ] Dados consultados no PostgreSQL.
- [ ] Quatro indicadores operacionais.
- [ ] Indicadores calculados no backend.
- [ ] Seletor de data funcional.
- [ ] Consulta de histórico permitida.
- [ ] Matriz com oito docas.
- [ ] Matriz com dez janelas.
- [ ] Última janela termina às 17:48.
- [ ] Estados representados corretamente.
- [ ] Legenda implementada.
- [ ] Filtros funcionais.
- [ ] Consultas eficientes.
- [ ] Layout responsivo.
- [ ] Formulário /agendar preservado.
- [ ] Nenhuma migration desnecessária.
- [ ] Nenhuma autenticação provisória.
- [ ] Rotas administrativas indisponíveis
      em produção.
- [ ] Nenhuma vulnerabilidade alta ou crítica
      conhecida sem tratamento.
- [ ] Nenhum erro JavaScript no console.
- [ ] Testes automatizados aprovados.
- [ ] Testes anteriores aprovados.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.
- [ ] Documentação atualizada.

---

## 32. Fora do escopo

Não implementar:

- Cadastro de usuários.
- Autenticação.
- Autorização.
- Login.
- Logout.
- Perfis de acesso.
- Check-in.
- Liberação de veículos.
- Cancelamento.
- Reagendamento.
- Alteração de reservas.
- Exclusão de reservas.
- Bloqueio de docas.
- Desbloqueio de docas.
- No-show automático.
- QR Code.
- Exportação Excel.
- Notificações por e-mail.
- Upload de documentos.
- Active Storage.
- Atualização automática.
- WebSockets.
- Implantação em produção.

Este requisito deverá implementar somente
a estrutura visual e a consulta administrativa.

---

## 33. Entrega

Ao concluir, apresentar:

- Resumo da implementação.
- Rotas criadas.
- Controllers criados.
- Views criadas.
- Partials criados.
- Arquivos CSS.
- Arquivos JavaScript, caso existam.
- Estratégia de consulta ao banco.
- Estratégia de cálculo dos indicadores.
- Screenshots do Dashboard.
- Screenshots da lista de agendamentos.
- Screenshots dos detalhes da reserva.
- Resultados dos testes.
- Resultado do Brakeman.
- Resultado do Bundler Audit.
- Resultado do RuboCop.
- Critérios de aceite atendidos.
- Pendências identificadas.

Apresentar também:

    git status --short

Não inventar resultados de testes.

Não declarar conclusão caso existam
critérios obrigatórios pendentes.

---

## 34. Regra de parada

Ao concluir o RF004, PARE.

Não implementar ações operacionais.

Não implementar autenticação ou autorização.

Não avançar automaticamente para o RF005.

Aguardar homologação do painel administrativo.