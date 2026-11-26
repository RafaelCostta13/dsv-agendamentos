# RF009 — Atualização Automática do Painel Administrativo

## 1. Objetivo

Implementar a atualização automática das informações
do painel administrativo da aplicação DSV Doca Agenda.

Permitir que a equipe operacional acompanhe as alterações
dos agendamentos sem precisar atualizar manualmente
a página do navegador.

Atualizar automaticamente:

- Indicadores operacionais.
- Matriz de docas e horários.
- Novos agendamentos.
- Alterações de agendamentos.
- Cancelamentos.
- Reagendamentos.
- Check-ins.
- Liberações.
- Bloqueios.
- Desbloqueios.
- Alertas de chegada atrasada.
- Alertas de operações com horário excedido.
- Reagendamentos pendentes.

Preservar integralmente o layout administrativo aprovado.

Não modificar as regras de negócio implementadas
nos requisitos anteriores.

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
- docs/requisitos/RF006.md
- docs/requisitos/RF007.md
- docs/requisitos/RF008.md
- docs/referencias/

Analisar a implementação existente.

Identificar os componentes que poderão ser
atualizados individualmente.

Reutilizar os controllers, services, helpers,
partials e estilos existentes.

Preservar a arquitetura monolítica Ruby on Rails.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Estratégia de atualização

Implementar a atualização automática utilizando
Polling HTTP.

O navegador deverá solicitar periodicamente
ao servidor uma versão atualizada dos componentes
do Dashboard.

O Rails deverá:

1. Receber a solicitação.
2. Identificar a data selecionada.
3. Consultar o PostgreSQL.
4. Calcular os indicadores.
5. Determinar os estados das posições.
6. Renderizar os componentes HTML.
7. Retornar o conteúdo atualizado.

O navegador deverá atualizar somente os componentes
necessários.

Não recarregar toda a página.

Priorizar a utilização de:

- Turbo Frames.
- Stimulus.
- Partials ERB.
- Recursos nativos do Rails.

Verificar a disponibilidade desses recursos
na implementação atual.

Caso seja necessária outra abordagem, utilizar
a solução mais simples compatível com a arquitetura
existente e documentar a justificativa.

Não introduzir:

- WebSockets.
- Action Cable.
- Redis.
- Turbo Streams via WebSocket.
- Server-Sent Events.
- React.
- Vue.
- Angular.
- SPA.
- Node.js.
- Microsserviços.
- APIs REST desnecessárias.

---

## 4. Frequência de atualização

Configurar o intervalo padrão de atualização:

    5 segundos

Centralizar a definição do intervalo.

Não espalhar valores fixos de temporização
por diferentes arquivos JavaScript.

O intervalo deverá ser facilmente ajustável
no código caso seja necessário futuramente.

Não implementar uma interface administrativa
para configurar o intervalo neste requisito.

Realizar uma única consulta periódica para
atualizar os componentes dinâmicos do Dashboard.

Não criar temporizadores independentes para:

- Cada indicador.
- Cada doca.
- Cada janela.
- Cada agendamento.

A atualização automática deverá funcionar
enquanto o Dashboard estiver aberto e visível.

---

## 5. Escopo da atualização automática

Neste requisito, aplicar a atualização automática
ao Dashboard administrativo.

Atualizar:

- Cards de indicadores.
- Matriz de docas.
- Estados das posições.
- Alertas operacionais.
- Indicador de reagendamentos pendentes.

Não atualizar automaticamente:

- Header.
- Sidebar.
- Menu de navegação.
- Formulários de alteração.
- Formulários de cancelamento.
- Formulários de reagendamento.
- Formulários de check-in.
- Formulários de liberação.
- Formulários de bloqueio.
- Formulários de desbloqueio.
- Página pública de agendamento.
- Página de detalhes de uma reserva.
- Lista de agendamentos.

A atualização automática das demais páginas
poderá ser avaliada posteriormente.

---

## 6. Estrutura conceitual

Manter a estrutura existente do painel.

    +------------------------------------------------+
    |                     HEADER                     |
    +------------+-----------------------------------+
    |            | Dashboard operacional             |
    |            |                                   |
    |            | Data: 25/11/2026                  |
    |            |                                   |
    |  SIDEBAR   | Atualização automática ativa      |
    |            | Última atualização: 14:35:05      |
    |            |                                   |
    |            | +-------------------------------+ |
    |            | | Indicadores operacionais      | |
    |            | +-------------------------------+ |
    |            |                                   |
    |            | +-------------------------------+ |
    |            | | Matriz de docas e horários    | |
    |            | +-------------------------------+ |
    |            |                                   |
    +------------+-----------------------------------+

A estrutura acima é uma referência conceitual.

Não redesenhar o Dashboard existente.

Adicionar somente os componentes necessários
para comunicar o estado da atualização automática.

---

## 7. Região dinâmica do Dashboard

Organizar os componentes que precisam ser
atualizados dentro de uma região dinâmica.

Utilizar preferencialmente um Turbo Frame
contendo:

- Indicadores operacionais.
- Matriz de docas.
- Alertas associados à matriz.

Manter fora da região dinâmica:

- Header.
- Sidebar.
- Seletor de data.
- Controles de atualização.
- Elementos de navegação que não precisam
  ser substituídos periodicamente.

A substituição da região dinâmica não deverá
reinicializar continuamente o mecanismo de polling.

Garantir que exista somente uma instância
ativa do controlador responsável pelas
atualizações periódicas.

Evitar a criação de múltiplos temporizadores
após cada renderização.

---

## 8. Indicador de atualização automática

Adicionar um indicador discreto na parte
superior do Dashboard.

Estado normal:

    Atualização automática ativa

Apresentar um pequeno indicador visual verde
acompanhado de texto.

Não utilizar somente cores para comunicar
o estado da conexão.

Exibir também:

    Última atualização: 14:35:05

O horário deverá representar a última
atualização concluída com sucesso.

Não apresentar como última atualização
o horário de uma tentativa que tenha falhado.

Utilizar o fuso:

    America/Sao_Paulo

Não confundir a última atualização visual
com o horário de processamento do no-show.

---

## 9. Estados da atualização

Implementar os seguintes estados visuais.

### 9.1 Atualização ativa

Quando a comunicação estiver funcionando:

    Atualização automática ativa

Utilizar indicador verde.

### 9.2 Atualizando

Durante uma solicitação:

    Atualizando...

Caso seja utilizado um indicador de carregamento,
mantê-lo discreto.

Não bloquear toda a interface.

Não remover os indicadores ou a matriz
durante o carregamento.

Evitar mudanças visuais bruscas.

### 9.3 Falha de comunicação

Quando uma atualização falhar:

    Falha na atualização.
    Exibindo os últimos dados recebidos.

Utilizar indicador vermelho ou amarelo,
conforme o padrão visual existente.

Preservar o conteúdo anteriormente carregado.

### 9.4 Atualização pausada

Quando a aba estiver oculta:

    Atualização automática pausada

Ao retornar à aba, atualizar imediatamente
as informações e retomar o polling.

Não apresentar a pausa como falha de comunicação.

---

## 10. Última atualização bem-sucedida

O servidor deverá informar o horário de referência
dos dados renderizados.

Apresentar esse horário no Dashboard após
a conclusão bem-sucedida da atualização.

Formato:

    HH:mm:ss

Exemplo:

    Última atualização: 14:35:05

Não utilizar exclusivamente o relógio
do navegador para representar a atualidade
dos dados operacionais.

Em caso de falha:

- Preservar o horário anterior.
- Preservar os últimos dados recebidos.
- Informar que os dados podem estar desatualizados.

Somente remover o alerta de falha após
uma nova atualização bem-sucedida.

---

## 11. Preservação da data selecionada

A atualização automática deverá respeitar
a data atualmente selecionada no Dashboard.

Exemplo:

    Data atual: 25/11/2026

    Data selecionada: 27/11/2026

Todas as consultas periódicas deverão utilizar:

    27/11/2026

Não retornar automaticamente para o dia atual.

Preservar a possibilidade de consultar:

- Datas anteriores.
- Dia atual.
- Datas futuras.

Não aplicar o horizonte de três datas
à consulta administrativa.

O horizonte continua sendo uma regra
para criação e alteração de reservas.

Não uma restrição para consulta histórica.

---

## 12. Alteração da data selecionada

Quando o operador alterar a data:

1. Interromper ou invalidar a atualização anterior.
2. Atualizar a referência da data selecionada.
3. Solicitar imediatamente os dados da nova data.
4. Atualizar a matriz.
5. Atualizar os indicadores.
6. Retomar as consultas periódicas.

Não aguardar obrigatoriamente cinco segundos
para carregar a nova data.

Impedir que uma resposta de uma data anterior
sobrescreva os dados da nova data selecionada.

Exemplo:

    Consulta A: 25/11/2026

    Operador seleciona 26/11/2026.

    Consulta B: 26/11/2026

    Consulta A termina depois da Consulta B.

Resultado esperado:

    O Dashboard permanece exibindo 26/11/2026.

Utilizar cancelamento de requisições ou
um mecanismo equivalente de identificação
das solicitações válidas.

Não permitir mistura de informações
de datas diferentes.

---

## 13. Preservação dos indicadores

Atualizar automaticamente todos os indicadores
já implementados.

Incluindo:

- Agendamentos.
- Horários disponíveis.
- Entregas.
- Coletas.
- Reagendamentos pendentes.

Não modificar suas regras de cálculo.

O indicador de reagendamentos pendentes deverá
continuar considerando todas as datas,
conforme definido no RF008.

Os demais indicadores deverão respeitar
a data selecionada e suas regras existentes.

Todos os cálculos deverão permanecer
no backend Rails.

Não calcular indicadores operacionais
no JavaScript.

Sempre que possível, calcular os indicadores
e a matriz a partir do mesmo conjunto
de dados consultados.

Evitar divergências entre a matriz e os cards
durante uma mesma atualização.

---

## 14. Atualização da matriz

Preservar a matriz existente:

    8 docas
    10 janelas
    80 posições nominais

Atualizar os estados das posições conforme
os registros existentes no PostgreSQL.

Não criar uma segunda implementação da matriz.

Reutilizar a estrutura ERB existente.

Preservar:

- Organização das docas.
- Organização dos horários.
- Paleta de cores.
- Legendas.
- Links para detalhes.
- Indicadores visuais.
- Responsividade.

Não modificar a quantidade de docas ou janelas.

A última janela deverá continuar encerrando
às 17:48.

---

## 15. Novos agendamentos

Quando um participante realizar um agendamento
através do formulário público, o Dashboard
deverá refletir a nova reserva automaticamente.

Exemplo:

    14:35:00
        Doca 03 / Janela 08 disponível.

    14:35:02
        Novo agendamento confirmado.

    Próxima atualização bem-sucedida:
        Doca 03 / Janela 08 agendada.

Atualizar também os indicadores correspondentes.

Não exigir que o operador clique em Atualizar.

Não implementar notificações sonoras
neste requisito.

Não implementar notificações do navegador.

---

## 16. Alterações e reagendamentos

Quando uma reserva for alterada:

- Atualizar a posição original.
- Atualizar a nova posição.
- Atualizar os indicadores correspondentes.
- Preservar o protocolo original.

Quando uma reserva em reagendamento retornar
ao estado agendado:

- Apresentar a reserva na nova posição.
- Atualizar o indicador de reagendamentos pendentes.
- Refletir os demais indicadores.

As informações deverão ser obtidas do banco
de dados na próxima atualização.

Não reproduzir as regras de alteração
ou reagendamento no frontend.

---

## 17. Cancelamentos

Quando um agendamento for cancelado:

- Atualizar a matriz.
- Atualizar os indicadores.
- Remover o consumo de capacidade correspondente.

A posição somente deverá aparecer como disponível
quando atender às regras existentes.

Considerar:

- Data.
- Horário.
- Horizonte permitido.
- Bloqueios.
- Outras reservas.

Não apresentar uma posição como disponível
apenas porque houve um cancelamento.

Preservar integralmente as regras do RF006.

---

## 18. Check-in e liberação

Quando um veículo realizar check-in,
atualizar sua representação para:

    Em operação

Quando um veículo for liberado,
atualizar sua representação para:

    Liberado

Preservar os padrões visuais implementados
no RF005.

A liberação física da doca não deverá
disponibilizar novamente a janela original.

Não modificar as regras de ocupação física.

Não executar check-in ou liberação através
do mecanismo de atualização automática.

O polling deverá ser exclusivamente
um mecanismo de consulta.

---

## 19. Bloqueios e desbloqueios

Quando uma posição for bloqueada:

- Atualizar seu estado na matriz.
- Apresentar a identificação de bloqueio.
- Atualizar a disponibilidade.
- Preservar as demais informações.

Quando uma posição for desbloqueada:

- Recalcular seu estado.
- Atualizar a matriz.
- Atualizar os indicadores.

Preservar todas as regras implementadas
no RF007.

Não realizar bloqueios ou desbloqueios
através das solicitações de atualização.

---

## 20. Atualização das condições temporais

A atualização automática deverá recalcular
as condições que dependem do horário atual.

Isso deverá ocorrer mesmo quando nenhum
registro do banco tiver sido modificado.

### 20.1 Horários iniciados

Exemplo:

    Horário anterior: 09:59:58

    Janela: 10:00 - 11:00

    Posição livre e disponível.

    Horário atual: 10:00:02

Resultado:

    A posição deixa de estar disponível
    para novos agendamentos.

### 20.2 Chegada atrasada

Quando uma reserva agendada ultrapassar
o horário final da janela:

    Agendado — Chegada atrasada

Preservar a regra do RF008.

Não alterar automaticamente o status.

### 20.3 Operação com horário excedido

Quando um veículo em operação alcançar
ou ultrapassar o término da janela:

    Em operação — Horário excedido

Preservar o status em_operacao.

Não liberar automaticamente a doca.

### 20.4 Datas futuras

Não aplicar o horário atual do dia
às janelas de datas futuras.

Preservar a correção anteriormente realizada
na lógica de disponibilidade.

Todos os cálculos deverão utilizar a data
completa e o horário correspondente.

---

## 21. Integração com o processamento de no-show

Preservar o processamento automático
implementado no RF008.

O mecanismo de no-show deverá continuar
funcionando independentemente do Dashboard.

Manter a frequência existente de processamento.

O polling deverá apenas consultar os resultados
das transições já persistidas.

Exemplo:

    17:30

    Uma reserva sem check-in torna-se elegível
    para processamento de no-show.

    A tarefa recorrente realiza a transição:

        agendado -> reagendamento

    Na próxima atualização bem-sucedida
    do Dashboard, o novo estado é refletido.

Não executar o processamento de no-show
a cada consulta do Dashboard.

Não duplicar o job existente.

Não criar uma segunda tarefa recorrente.

Não realizar transições de estado
através de requisições GET.

Não confundir o intervalo de cinco segundos
do Dashboard com o intervalo de execução
do processamento de no-show.

---

## 22. Atualização manual

Preservar o botão existente:

    Atualizar

Ao clicar nesse botão:

- Solicitar imediatamente os dados atualizados.
- Preservar a data selecionada.
- Atualizar os indicadores.
- Atualizar a matriz.
- Atualizar o horário da última atualização.
- Manter o funcionamento do polling.

Não recarregar toda a página quando
isso não for necessário.

Caso exista uma atualização em andamento,
evitar solicitações duplicadas.

Garantir que a atualização manual não crie
um segundo temporizador.

O mecanismo periódico deverá continuar
funcionando normalmente após a operação.

---

## 23. Controle de requisições concorrentes

Garantir que exista no máximo uma solicitação
periódica ativa por instância do Dashboard.

Exemplo:

    Intervalo de atualização: 5 segundos.

    Uma solicitação demora 8 segundos.

Resultado esperado:

    Não iniciar sucessivas requisições
    enquanto a anterior estiver pendente.

Não acumular solicitações HTTP.

Não criar filas de atualizações no navegador.

Preferir um mecanismo que programe
a próxima atualização após a conclusão
da solicitação anterior.

Caso seja utilizado setTimeout ou setInterval,
implementar controle adequado de ciclo de vida.

A estratégia escolhida deverá evitar:

- Sobreposição de requisições.
- Respostas fora de ordem.
- Atualizações duplicadas.
- Consumo desnecessário do servidor.
- Acúmulo de temporizadores.

---

## 24. Controle de timeout

Definir um limite de espera para cada
solicitação de atualização.

Utilizar como referência inicial:

    Timeout: 10 segundos

Caso a solicitação ultrapasse o limite:

- Cancelar a requisição quando possível.
- Preservar os últimos dados recebidos.
- Apresentar o indicador de falha.
- Programar uma nova tentativa.

Centralizar essa configuração.

Não deixar solicitações indefinidamente
pendentes no navegador.

Não modificar os timeouts gerais do Puma
ou do PostgreSQL exclusivamente para
implementar este comportamento.

---

## 25. Falha de comunicação

Considerar os seguintes cenários:

- Servidor temporariamente indisponível.
- PostgreSQL indisponível.
- Requisição interrompida.
- Timeout.
- Falha de conexão.
- Resposta HTTP inesperada.
- Resposta HTML incompleta.
- Turbo Frame ausente ou inválido.

Quando uma atualização falhar:

- Preservar os dados anteriormente renderizados.
- Informar a falha ao operador.
- Preservar o horário da última atualização
  bem-sucedida.
- Continuar tentando recuperar a comunicação.

Não substituir o Dashboard por uma tela vazia.

Não apresentar todos os horários como disponíveis
em consequência de uma falha de consulta.

Não interpretar falha de carregamento como
ausência de reservas.

Não apresentar mensagens internas do servidor.

---

## 26. Estratégia de recuperação

Em condições normais, manter:

    Intervalo: 5 segundos

Em caso de falhas consecutivas, utilizar
um intervalo progressivamente maior.

Referência inicial:

    Primeira falha:     5 segundos
    Segunda falha:     10 segundos
    Terceira falha:    20 segundos
    Demais falhas:     até 30 segundos

Após recuperar a comunicação:

- Atualizar os componentes.
- Remover o indicador de falha.
- Atualizar o horário da última atualização.
- Retomar o intervalo padrão de cinco segundos.

Permitir que o botão Atualizar solicite
uma nova tentativa imediatamente.

Não realizar tentativas infinitas
sem intervalo entre elas.

Não implementar bibliotecas externas
exclusivamente para controlar novas tentativas.

Documentar a estratégia adotada.

---

## 27. Controle de visibilidade da página

Utilizar os recursos nativos do navegador
para identificar se a página está visível.

Preferir a Page Visibility API.

Quando o Dashboard estiver em uma aba oculta:

- Pausar as solicitações periódicas.
- Cancelar ou invalidar uma solicitação
  que não seja mais necessária.
- Preservar os dados apresentados.

Quando o operador retornar à aba:

- Solicitar imediatamente os dados atualizados.
- Retomar o intervalo normal.
- Preservar a data selecionada.

Não continuar realizando consultas
desnecessárias em abas que não estão visíveis.

O processamento de no-show do RF008
não deverá ser afetado por essa pausa.

---

## 28. Ciclo de vida do controlador

Caso seja utilizado Stimulus, respeitar
seu ciclo de vida.

Ao conectar o controlador:

- Inicializar as configurações.
- Registrar os eventos necessários.
- Iniciar um único mecanismo de atualização.

Ao desconectar o controlador:

- Cancelar os temporizadores.
- Cancelar solicitações pendentes quando possível.
- Remover os eventos registrados.
- Impedir novas atualizações.

Considerar a navegação utilizando Turbo.

Não deixar temporizadores ativos após
o operador sair do Dashboard.

Ao retornar ao Dashboard:

- Inicializar corretamente a atualização.
- Não reutilizar solicitações obsoletas.
- Não duplicar controladores ou temporizadores.

Tratar também a restauração de páginas
pelo cache de navegação do Turbo.

Não apresentar conteúdo restaurado do cache
como se tivesse acabado de ser consultado.

---

## 29. Preservação da experiência operacional

A atualização automática não deverá:

- Alterar a posição vertical da página.
- Retornar o operador ao topo.
- Alterar a data selecionada.
- Fechar componentes interativos abertos.
- Interromper a navegação.
- Modificar formulários preenchidos.
- Cancelar ações em andamento.
- Alterar desnecessariamente o foco do teclado.
- Reinicializar a Sidebar.
- Alterar o menu ativo.

Preservar, quando possível, a posição
de scroll horizontal da matriz.

Evitar substituir elementos estáveis
que não precisam ser atualizados.

Caso o operador esteja interagindo
com um componente que possa ser substituído,
garantir que a atualização não provoque
uma ação incorreta ou perda de contexto.

Não enfraquecer o controle de concorrência
com lock_version dos requisitos anteriores.

---

## 30. Aparência durante as atualizações

As atualizações deverão ocorrer
de maneira discreta.

Não utilizar:

- Tela inteira de carregamento.
- Overlay bloqueando o Dashboard.
- Animações excessivas.
- Piscar de toda a matriz.
- Desaparecimento temporário dos indicadores.
- Mudanças bruscas de tamanho.
- Recarregamento completo da página.

Preservar o conteúdo anterior enquanto
uma atualização estiver em andamento.

Substituir os dados somente após receber
uma resposta válida.

Preservar o layout administrativo aprovado.

---

## 31. Rotas administrativas

Reutilizar preferencialmente a rota
existente do Dashboard.

Caso seja necessária uma rota específica
para atualização dos componentes, utilizar:

    GET /admin/dashboard/refresh

A nomenclatura poderá ser adaptada
à estrutura atual do projeto.

Responsabilidades da rota:

- Validar a data recebida.
- Consultar os dados operacionais.
- Calcular os indicadores.
- Renderizar os partials necessários.
- Retornar o conteúdo atualizado.

Não retornar informações desnecessárias.

Não criar uma API JSON independente
exclusivamente para alimentar o Dashboard.

Priorizar HTML renderizado pelo Rails.

Não utilizar requisições POST, PATCH ou DELETE
para consultas periódicas de atualização.

Não realizar gravações no banco durante
as solicitações de polling.

---

## 32. Organização do backend

Analisar a estrutura existente do Dashboard.

Reutilizar a mesma lógica para:

- Carregamento inicial.
- Atualização manual.
- Atualização automática.
- Alteração da data selecionada.

Não manter implementações diferentes
para calcular os mesmos indicadores.

Não duplicar a lógica da matriz.

Manter os controllers pequenos.

Centralizar as consultas e regras
em métodos ou services existentes.

Criar novos componentes somente quando
isso melhorar a organização e manutenção.

A renderização inicial e a renderização
periódica deverão utilizar os mesmos
partials ERB.

---

## 33. Organização sugerida dos arquivos

Adaptar à estrutura atual do projeto.

Exemplo conceitual:

    app/
    ├── controllers/
    │   └── admin/
    │       └── dashboard_controller.rb
    │
    ├── views/
    │   └── admin/
    │       └── dashboard/
    │           ├── index.html.erb
    │           ├── _dashboard_content.html.erb
    │           ├── _indicators.html.erb
    │           ├── _dock_matrix.html.erb
    │           └── _refresh_status.html.erb
    │
    └── javascript/
        └── controllers/
            └── dashboard_refresh_controller.js

A estrutura acima é somente uma sugestão.

Não reorganizar arquivos existentes
sem necessidade.

Não duplicar partials que já estejam
implementados.

Não alterar a estrutura geral da aplicação.

---

## 34. Consultas e desempenho

O Dashboard será consultado periodicamente.

Portanto, evitar consultas desnecessárias
ao PostgreSQL.

Não executar uma consulta independente
para cada posição da matriz.

Não executar oitenta consultas para
montar as oitenta posições.

Carregar de forma agrupada:

- Agendamentos da data selecionada.
- Bloqueios da data selecionada.
- Informações necessárias aos indicadores.
- Reagendamentos pendentes.

Reutilizar os resultados das consultas
durante a renderização.

Evitar N+1.

Não carregar todo o histórico de agendamentos
para construir o Dashboard.

Não consultar dados cadastrais que não sejam
necessários à renderização.

Não adicionar cache externo.

Não adicionar Redis.

Não adicionar índices sem necessidade
demonstrada.

Avaliar o desempenho real da consulta
e registrar os resultados na entrega.

---

## 35. Volume de requisições

Considerar que cada Dashboard visível,
com atualização a cada cinco segundos,
poderá realizar aproximadamente:

    12 solicitações por minuto.

    720 solicitações por hora.

Esses valores representam uma estimativa
em condições normais, sem considerar pausas,
falhas ou duração das solicitações.

Evitar requisições adicionais para cada
indicador ou posição da matriz.

Utilizar uma única atualização agrupada.

A solução deverá permitir múltiplos
operadores acompanhando o Dashboard
simultaneamente.

Não implementar uma infraestrutura
complexa de tempo real neste momento.

Não declarar uma capacidade máxima de
operadores sem realizar testes adequados.

---

## 36. Cache e dados atualizados

A resposta periódica deverá representar
o estado atual do banco de dados.

Evitar que o navegador reutilize respostas
antigas de atualização.

Configurar os cabeçalhos HTTP apropriados
para as respostas administrativas.

Priorizar:

    Cache-Control: no-store

quando necessário para impedir armazenamento
de dados administrativos e respostas obsoletas.

Não desabilitar globalmente o cache de assets
como CSS, JavaScript e imagens.

Preservar o sistema de assets existente.

Não utilizar cache que impeça a atualização
de condições dependentes do horário atual.

---

## 37. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Manter as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

A nova rota de atualização, caso exista,
deverá possuir as mesmas restrições
das demais rotas administrativas.

Não disponibilizar informações administrativas
em uma rota pública de disponibilidade.

Não criar exceções nas restrições existentes
para facilitar o polling.

Não implementar autenticação provisória.

Não criar usuários ou credenciais fixas.

Preservar:

- Proteção CSRF.
- Content Security Policy.
- Escaping padrão do ERB.
- Consultas parametrizadas.
- Validação dos parâmetros.
- Proteção de informações internas.

Não utilizar raw ou html_safe para
apresentar informações fornecidas por usuários.

Não transmitir dados pessoais ou fiscais
que não sejam necessários ao Dashboard.

Não registrar informações sensíveis
nos logs das solicitações periódicas.

Não expor a aplicação administrativa
em produção antes da implementação
de autenticação e autorização.

---

## 38. JavaScript

Utilizar o mínimo necessário de JavaScript.

Responsabilidades permitidas:

- Controlar o intervalo de atualização.
- Solicitar a atualização dos componentes.
- Controlar solicitações em andamento.
- Cancelar solicitações obsoletas.
- Detectar visibilidade da página.
- Controlar indicadores de comunicação.
- Controlar novas tentativas.
- Preservar estados visuais necessários.

Não utilizar JavaScript para:

- Calcular disponibilidade.
- Calcular indicadores operacionais.
- Determinar status de reservas.
- Executar no-show.
- Executar cancelamentos.
- Executar check-in.
- Liberar docas.
- Alterar registros do banco.
- Definir regras de negócio.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- outerHTML com conteúdo não confiável.
- insertAdjacentHTML com conteúdo não confiável.
- Handlers JavaScript inline.
- Scripts de CDNs.

Preferir os mecanismos de atualização
de HTML disponibilizados pelo Turbo.

Não enfraquecer a Content Security Policy.

Não utilizar unsafe-eval.

Não adicionar unsafe-inline para scripts.

Não introduzir dependências frontend
desnecessárias.

---

## 39. Banco de dados

Utilizar as tabelas existentes:

    bookings
    slot_blocks
    audit_events

Preservar também as estruturas técnicas
existentes do processamento em segundo plano.

Não criar tabelas para:

- Atualização do Dashboard.
- Controle de polling.
- Controle de conexões.
- Sessões de atualização.
- Indicadores operacionais.

Não criar migrations neste requisito,
salvo necessidade indispensável e justificada.

Não registrar eventos de auditoria
para simples consultas do Dashboard.

Não modificar registros durante
as atualizações periódicas.

Não alterar a estrutura de persistência
dos requisitos anteriores.

---

## 40. Infraestrutura

Preservar a infraestrutura Docker existente.

Não adicionar novos containers
exclusivamente para atualização do Dashboard.

Preservar:

- Rails.
- Puma.
- PostgreSQL.
- Processamento em segundo plano do RF008.
- Configurações de rede.
- Configurações de segurança.
- Volumes existentes.

Não modificar a arquitetura monolítica.

Não introduzir serviços externos.

Não alterar a configuração do Nginx.

Não alterar a publicação de portas.

Não aumentar recursos de infraestrutura
sem necessidade comprovada.

---

## 41. Testes automatizados

Utilizar Minitest e PostgreSQL.

Reutilizar os mecanismos de testes de sistema
e navegador existentes.

Caso seja necessário adicionar suporte
a testes de navegador, justificar a necessidade
e restringir as dependências ao ambiente de teste.

### 41.1 Carregamento inicial

Validar:

- Dashboard continua funcionando.
- Indicadores corretos.
- Matriz correta.
- Data inicial correta.
- Estado da atualização automática apresentado.

### 41.2 Atualização periódica

Validar:

- Intervalo padrão de cinco segundos.
- Atualização sem recarregar toda a página.
- Atualização dos componentes necessários.
- Header preservado.
- Sidebar preservada.
- Ausência de temporizadores duplicados.

### 41.3 Novos agendamentos

Validar:

- Criação de uma reserva após o Dashboard
  já estar aberto.
- Atualização automática da matriz.
- Atualização dos indicadores.
- Reserva apresentada na posição correta.

### 41.4 Alterações operacionais

Validar atualização após:

- Check-in.
- Liberação.
- Cancelamento.
- Alteração.
- Reagendamento.
- Bloqueio.
- Desbloqueio.
- Processamento de no-show.

### 41.5 Condições temporais

Validar:

- Janela que passa a ficar indisponível
  ao alcançar seu horário inicial.
- Chegada atrasada identificada.
- Operação com horário excedido identificada.
- Última janela terminando às 17:48.
- Datas futuras não afetadas pelo horário atual.
- Virada de dia no fuso America/Sao_Paulo.

### 41.6 Data selecionada

Validar:

- Preservação do dia atual.
- Preservação de datas futuras.
- Preservação de datas anteriores.
- Atualização imediata após troca de data.
- Ausência de retorno indevido para hoje.
- Respostas antigas não sobrescrevem
  a data selecionada.

### 41.7 Concorrência de requisições

Validar:

- Solicitação mais lenta que o intervalo.
- Ausência de solicitações sobrepostas.
- Ausência de filas crescentes de consultas.
- Cancelamento de solicitações obsoletas.
- Atualização manual durante polling ativo.
- Ausência de respostas fora de ordem.

### 41.8 Falhas de comunicação

Validar:

- Timeout.
- Falha HTTP.
- Resposta inesperada.
- Servidor indisponível.
- Preservação dos últimos dados válidos.
- Preservação da última atualização.
- Apresentação do indicador de falha.
- Intervalo progressivo de novas tentativas.
- Recuperação automática da comunicação.
- Retorno ao intervalo normal.

### 41.9 Visibilidade e navegação

Validar:

- Pausa quando a aba estiver oculta.
- Atualização imediata ao retornar à aba.
- Retomada do polling.
- Encerramento dos temporizadores
  ao sair do Dashboard.
- Ausência de polling em outras páginas.
- Ausência de duplicação após retornar.
- Compatibilidade com navegação Turbo.

### 41.10 Experiência do usuário

Validar:

- Preservação da posição de scroll.
- Ausência de recarregamento completo.
- Ausência de tela vazia durante atualização.
- Preservação do seletor de data.
- Ausência de interrupção de formulários.
- Ausência de mudanças visuais bruscas.

### 41.11 Segurança

Validar:

- Data inválida rejeitada adequadamente.
- Consultas parametrizadas.
- Escaping de conteúdo externo.
- Proteção contra XSS armazenado.
- Content Security Policy preservada.
- Rotas administrativas indisponíveis
  em produção.
- Ausência de exposição pública
  dos dados administrativos.
- Requisições periódicas não alteram
  registros de negócio.

### 41.12 Desempenho

Validar:

- Ausência de consultas individuais por célula.
- Ausência de consultas N+1.
- Quantidade de consultas por atualização.
- Tempo de resposta observado.
- Funcionamento com múltiplos Dashboards abertos.
- Ausência de acúmulo de requisições.

Registrar os resultados efetivamente observados.

### 41.13 Regressão

Executar todos os testes existentes dos:

- RF001.
- RF002.
- RF003.
- RF004.
- RF005.
- RF006.
- RF007.
- RF008.

Não remover ou enfraquecer testes anteriores.

Não declarar como aprovado um cenário de navegador
que tenha sido validado somente em teste de model
ou controller.

---

## 42. Validação manual

### Cenário 01 — Novo agendamento

1. Abrir o Dashboard em um navegador.
2. Abrir o formulário público em outra aba.
3. Criar um agendamento para a data visualizada.
4. Retornar ou manter o Dashboard visível.
5. Verificar a atualização automática.
6. Verificar os indicadores.
7. Confirmar que não houve recarregamento
   completo da página.

### Cenário 02 — Operações simultâneas

1. Abrir o Dashboard em dois navegadores.
2. Registrar uma operação administrativa
   em um dos navegadores.
3. Verificar a atualização automática
   no outro navegador.
4. Repetir com check-in e liberação.
5. Repetir com cancelamento e reagendamento.
6. Repetir com bloqueio e desbloqueio.

### Cenário 03 — Alteração de data

1. Selecionar uma data futura.
2. Aguardar várias atualizações.
3. Confirmar que a data permanece selecionada.
4. Alternar rapidamente entre datas.
5. Confirmar que a matriz corresponde
   exclusivamente à última data selecionada.

### Cenário 04 — Falha de comunicação

1. Abrir o Dashboard.
2. Aguardar uma atualização bem-sucedida.
3. Simular uma falha de comunicação.
4. Verificar o indicador de falha.
5. Confirmar que os últimos dados
   permanecem visíveis.
6. Restaurar a comunicação.
7. Confirmar a recuperação automática.
8. Verificar o horário da última atualização.

Realizar a simulação utilizando mecanismos
controlados de desenvolvimento.

Não interromper ambientes produtivos.

### Cenário 05 — Aba oculta

1. Abrir o Dashboard.
2. Monitorar as solicitações de rede.
3. Alternar para outra aba.
4. Confirmar a interrupção do polling.
5. Retornar ao Dashboard.
6. Confirmar a atualização imediata.
7. Confirmar a retomada do intervalo normal.

### Cenário 06 — Navegação

1. Abrir o Dashboard.
2. Acessar a lista de agendamentos.
3. Confirmar que o polling foi encerrado.
4. Abrir uma reserva.
5. Preencher um formulário administrativo.
6. Confirmar que o formulário não é interrompido.
7. Retornar ao Dashboard.
8. Confirmar que somente um mecanismo
   de atualização foi iniciado.

### Cenário 07 — No-show

1. Preparar uma reserva elegível em ambiente
   isolado de teste.
2. Manter o Dashboard aberto.
3. Executar o processamento do RF008
   utilizando tempo controlado.
4. Confirmar a transição para reagendamento.
5. Verificar a atualização automática
   do indicador de pendências.
6. Confirmar que não houve auditoria duplicada.

Não alterar o relógio do sistema operacional.

---

## 43. Validação no navegador

Utilizar as ferramentas de desenvolvimento
do navegador para verificar:

- Console.
- Aba Network.
- Frequência das solicitações.
- Tempo das solicitações.
- Respostas HTTP.
- Solicitações canceladas.
- Ausência de solicitações sobrepostas.
- Ausência de requisições em abas ocultas.
- Ausência de recarregamento completo.

Não deverão existir:

- Erros JavaScript inesperados.
- Violações de CSP.
- Erros de carregamento de assets.
- Temporizadores duplicados.
- Solicitações infinitamente pendentes.
- Crescimento contínuo de solicitações.
- Atualizações de componentes incorretos.
- Links quebrados.

Registrar evidências da validação.

---

## 44. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Utilizar os procedimentos estabelecidos
nos requisitos anteriores.

Não adicionar ferramentas desnecessárias.

Não desabilitar verificações para obter
resultados positivos.

Não declarar testes aprovados
sem efetivamente executá-los.

---

## 45. Documentação

Registrar este requisito em:

    docs/requisitos/RF009.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação operacional.

Documentar:

- Estratégia de polling.
- Intervalo de atualização.
- Timeout.
- Estratégia de recuperação.
- Controle de visibilidade.
- Controle de concorrência das solicitações.
- Rotas utilizadas.
- Componentes atualizados.
- Componentes preservados.
- Organização dos partials.
- Indicador de última atualização.
- Tratamento de falhas.
- Integração com RF008.
- Desempenho observado.
- Limitações existentes.

Criar ADR somente caso exista uma nova
decisão arquitetural relevante.

---

## 46. Critérios de aceite

### Atualização automática

- [ ] Dashboard atualizado automaticamente.
- [ ] Intervalo padrão de cinco segundos.
- [ ] Nenhum recarregamento completo da página.
- [ ] Uma única atualização agrupada.
- [ ] Atualização dos indicadores.
- [ ] Atualização da matriz.
- [ ] Atualização dos alertas operacionais.
- [ ] Atualização manual preservada.

### Integração operacional

- [ ] Novos agendamentos refletidos.
- [ ] Alterações refletidas.
- [ ] Cancelamentos refletidos.
- [ ] Reagendamentos refletidos.
- [ ] Check-ins refletidos.
- [ ] Liberações refletidas.
- [ ] Bloqueios refletidos.
- [ ] Desbloqueios refletidos.
- [ ] No-shows refletidos.
- [ ] Horários iniciados recalculados.
- [ ] Alertas temporais atualizados.
- [ ] Reagendamentos pendentes atualizados.

### Controle de solicitações

- [ ] Ausência de solicitações sobrepostas.
- [ ] Ausência de temporizadores duplicados.
- [ ] Timeout implementado.
- [ ] Respostas obsoletas descartadas.
- [ ] Troca de data segura.
- [ ] Polling pausado em abas ocultas.
- [ ] Retomada automática ao retornar à aba.
- [ ] Polling encerrado ao sair do Dashboard.

### Comunicação

- [ ] Indicador de atualização ativa.
- [ ] Horário da última atualização bem-sucedida.
- [ ] Indicador de falha de comunicação.
- [ ] Últimos dados válidos preservados.
- [ ] Recuperação automática após falha.
- [ ] Intervalo progressivo de novas tentativas.
- [ ] Retorno ao intervalo normal.

### Interface

- [ ] Layout administrativo aprovado preservado.
- [ ] Header preservado.
- [ ] Sidebar preservada.
- [ ] Data selecionada preservada.
- [ ] Posição de scroll preservada.
- [ ] Formulários não interrompidos.
- [ ] Nenhuma mudança visual brusca.
- [ ] Responsividade preservada.

### Desempenho

- [ ] Consultas agrupadas.
- [ ] Ausência de consultas individuais por célula.
- [ ] Ausência de N+1.
- [ ] Ausência de acúmulo de solicitações.
- [ ] Desempenho observado documentado.
- [ ] Nenhum Redis introduzido.
- [ ] Nenhum WebSocket introduzido.

### Segurança

- [ ] Content Security Policy preservada.
- [ ] Proteção CSRF preservada.
- [ ] Escaping padrão do ERB preservado.
- [ ] Dados administrativos protegidos.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma autenticação provisória criada.
- [ ] Consultas periódicas não modificam reservas.
- [ ] Nenhuma regra de negócio transferida
      para o JavaScript.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de navegador executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Console sem erros inesperados.
- [ ] Documentação atualizada.

---

## 47. Fora do escopo

Não implementar neste requisito:

- WebSockets.
- Action Cable.
- Redis.
- Server-Sent Events.
- Notificações sonoras.
- Notificações do navegador.
- Notificações por e-mail.
- Atualização automática do formulário público.
- Atualização automática da lista de agendamentos.
- Atualização automática da página de detalhes.
- Alterações nas regras de disponibilidade.
- Alterações nas regras de check-in.
- Alterações nas regras de liberação.
- Alterações no processamento de no-show.
- Novos indicadores operacionais.
- Novas tabelas de negócio.
- QR Code.
- Exportação Excel.
- Upload de documentos.
- Active Storage.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente a atualização
automática do Dashboard administrativo.

---

## 48. Entrega

Ao concluir o RF009, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.
- Estratégia de atualização adotada.

### Interface

- Componentes atualizados.
- Componentes preservados.
- Screenshot do estado normal.
- Screenshot do indicador de falha.
- Screenshot da última atualização.

### Backend

- Rotas criadas ou reutilizadas.
- Controllers modificados.
- Services modificados.
- Partials criados ou reutilizados.
- Estratégia de consulta ao PostgreSQL.

### Frontend

- Arquivos JavaScript criados ou modificados.
- Justificativa para utilização de JavaScript.
- Controle de temporizadores.
- Controle de solicitações.
- Controle de visibilidade.
- Estratégia de recuperação.

### Desempenho

- Quantidade de consultas ao PostgreSQL
  por atualização.
- Tempo de resposta observado.
- Frequência efetiva das solicitações.
- Resultado dos testes com múltiplos Dashboards.
- Limitações identificadas.

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
- Resultado dos testes de navegador.
- Resultado dos testes de recuperação.
- Resultado do RuboCop.
- Testes não executados e respectivos motivos.

### Documentação

- Arquivos criados.
- Arquivos modificados.
- Decisões registradas.

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

Informar qualquer problema, limitação ou
decisão técnica que necessite de homologação.

---

## 49. Regra de parada

Ao concluir o RF009, PARE.

Não implementar o RF010.

Não implementar QR Code.

Não implementar notificações.

Não implementar autenticação ou autorização.

Não modificar desnecessariamente o layout
administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.