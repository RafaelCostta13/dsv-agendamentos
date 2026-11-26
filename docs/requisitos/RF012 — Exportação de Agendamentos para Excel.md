# RF012 — Exportação de Agendamentos para Excel

## 1. Objetivo

Implementar a exportação de agendamentos da aplicação
DSV Doca Agenda para arquivos Microsoft Excel.

Permitir que a equipe administrativa extraia os dados
operacionais para:

- Análises de produtividade.
- Controle de veículos.
- Análise de recebimento e expedição.
- Controle de utilização das docas.
- Análise de atrasos.
- Análise de duração das operações.
- Controle de cancelamentos.
- Controle de reagendamentos.
- Desenvolvimento de indicadores.
- Integração com Excel, Power Query e Power BI.

O arquivo deverá possuir formato XLSX.

Preservar todas as funcionalidades implementadas
até o RF011.

Preservar o layout administrativo aprovado.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/database/
- docs/requisitos/RF001.md até RF011.md
- docs/referencias/

Analisar:

- Estrutura atual da tabela bookings.
- Model de agendamentos.
- Filtros existentes.
- Definições de docas e janelas.
- Configuração de fuso horário.
- Regras de segurança.
- Estrutura das páginas administrativas.

Não assumir que os exemplos conceituais dos
requisitos anteriores correspondem exatamente
ao código atualmente implementado.

Trabalhar exclusivamente dentro do repositório atual.

Preservar a arquitetura monolítica Ruby on Rails.

---

## 3. Arquitetura

Implementar a geração da planilha no backend Ruby.

Utilizar:

- Ruby on Rails.
- Active Record.
- PostgreSQL.
- Services.
- Controllers.
- Views ERB.
- Recursos existentes da aplicação.

Não gerar a planilha através de JavaScript.

Não enviar todos os registros para o navegador
para realizar a exportação no frontend.

Não introduzir:

- Python como dependência operacional.
- Node.js.
- React.
- Vue.
- Serviços externos de conversão.
- Microsserviços.
- APIs externas.
- Redis.

A exportação deverá ser uma funcionalidade
da aplicação Rails existente.

---

## 4. Biblioteca de geração XLSX

Avaliar a utilização da gem:

    caxlsx

Antes de adicionar a dependência, verificar:

- Compatibilidade com a versão atual do Ruby.
- Compatibilidade com a versão atual do Rails.
- Compatibilidade com o ambiente Docker.
- Manutenção da biblioteca.
- Licença.
- Dependências transitivas.
- Vulnerabilidades conhecidas.
- Suporte aos tipos de dados necessários.
- Suporte a filtros e congelamento de cabeçalho.

Caso exista uma alternativa mais adequada,
documentar a justificativa técnica.

Adicionar somente as dependências necessárias.

Atualizar o Gemfile e Gemfile.lock.

Não atualizar dependências não relacionadas
ao requisito.

Não adicionar uma biblioteca exclusivamente
para gerar CSV.

O formato obrigatório será XLSX.

---

## 5. Integração com o painel administrativo

Utilizar a página existente:

    /admin/bookings

Adicionar o botão:

    Exportar Excel

Posicionar preferencialmente na parte superior
direita da página de agendamentos.

Utilizar:

- Ícone de planilha ou download.
- Cor verde compatível com a identidade visual.
- Texto legível.
- Estado de foco acessível.

Preservar:

- Header.
- Sidebar.
- Logo DSV.
- Tabela de agendamentos.
- Filtros.
- Paginação.
- Menu ativo.
- Identidade visual existente.

Não adicionar um novo menu à Sidebar.

Não criar uma página independente de relatórios
neste requisito.

Não modificar o Dashboard.

---

## 6. Filtros da exportação

A exportação deverá respeitar os filtros aplicados
na página de agendamentos.

Considerar os filtros existentes:

- Data.
- Doca.
- Tipo de operação.
- Status.

Adicionar, caso ainda não existam:

- Data inicial.
- Data final.

Permitir selecionar um intervalo de datas
para consulta e exportação.

Exemplo:

    Data inicial: 01/11/2026
    Data final: 30/11/2026
    Operação: Entrega
    Doca: Todas
    Status: Liberado

Resultado:

    Exportar todos os agendamentos de entrega
    liberados no período selecionado.

A filtragem da tabela e da exportação deverá
utilizar a mesma lógica no backend.

Não manter duas implementações independentes
das regras de filtragem.

---

## 7. Filtro por período

O filtro principal de período deverá considerar:

    bookings.booking_date

Ou seja, a data agendada para a operação.

Não confundir:

- Data agendada.
- Data de criação do registro.
- Data de check-in.
- Data de liberação.
- Data de alteração.

Exemplo:

    Criado em: 25/11/2026
    Agendado para: 27/11/2026

Ao exportar o período de 27/11/2026,
essa reserva deverá ser incluída.

Considerar as datas inicial e final inclusive.

Permitir consultar datas anteriores.

Não aplicar o horizonte de três datas
do formulário público à exportação.

Não modificar a regra de criação de reservas.

Validar:

- Formato das datas.
- Data inicial válida.
- Data final válida.
- Data inicial menor ou igual à data final.

Preservar a compatibilidade com o filtro
de data individual existente.

---

## 8. Escopo dos registros exportados

A exportação deverá incluir todos os registros
correspondentes aos filtros aplicados.

Não exportar somente os registros da página
atualmente visualizada.

Exemplo:

    Registros encontrados: 350
    Registros por página: 25
    Página atual: 1

Resultado esperado:

    350 registros exportados.

A paginação da interface não deverá limitar
a quantidade de registros da exportação.

Não aceitar parâmetros de paginação como
restrição implícita do arquivo exportado.

---

## 9. Estados exportáveis

Permitir exportar todos os estados existentes:

    agendado
    em_operacao
    liberado
    cancelado
    reagendamento

Apresentar os valores em português:

    agendado      -> Agendado
    em_operacao   -> Em operação
    liberado      -> Liberado
    cancelado     -> Cancelado
    reagendamento -> Reagendamento obrigatório

Não excluir reservas canceladas.

Não excluir reservas em reagendamento.

Não excluir reservas de datas anteriores.

Não exportar somente operações concluídas.

O operador poderá utilizar os filtros
para selecionar os estados desejados.

---

## 10. Estrutura do arquivo Excel

Gerar um arquivo com uma aba denominada:

    Agendamentos

A primeira linha deverá conter os cabeçalhos.

Cada linha posterior deverá representar
um único registro da tabela bookings.

Estrutura:

    Linha 1: Cabeçalhos
    Linha 2: Agendamento 1
    Linha 3: Agendamento 2
    Linha 4: Agendamento 3
    ...

Não utilizar:

- Células mescladas.
- Títulos acima do cabeçalho.
- Imagens.
- Logos dentro da tabela.
- Linhas vazias entre registros.
- Subtotais.
- Totais no final da tabela.
- Gráficos.
- Fórmulas desnecessárias.
- Cabeçalhos repetidos.

A planilha deverá possuir uma estrutura tabular
adequada para processamento automatizado.

---

## 11. Colunas obrigatórias

Utilizar a seguinte ordem:

    A  - Protocolo
    B  - Data de criação
    C  - Hora de criação
    D  - Responsável
    E  - Empresa / Transportadora
    F  - Operação
    G  - Nota fiscal
    H  - Placa
    I  - Modelo do veículo
    J  - Data agendada
    K  - Doca
    L  - Janela
    M  - Horário inicial agendado
    N  - Horário final agendado
    O  - Status
    P  - Data do check-in
    Q  - Hora do check-in
    R  - Data da liberação
    S  - Hora da liberação
    T  - Duração da operação (min)
    U  - Atraso no check-in (min)
    V  - Tempo excedido da janela (min)
    W  - Observação da liberação
    X  - Motivo da última alteração
    Y  - Data da última atualização
    Z  - Hora da última atualização

Preservar essa ordem para facilitar
integrações futuras com ferramentas de análise.

Não adicionar colunas técnicas desnecessárias.

---

## 12. Mapeamento dos atributos

Utilizar os atributos existentes da tabela bookings.

Mapeamento conceitual:

    Protocolo:
        protocol

    Data e hora de criação:
        created_at

    Responsável:
        contact_name

    Empresa / Transportadora:
        company

    Operação:
        operation

    Nota fiscal:
        invoice

    Placa:
        plate

    Modelo do veículo:
        vehicle_model

    Data agendada:
        booking_date

    Doca:
        dock_number

    Janela:
        slot_number

    Status:
        status

    Data e hora do check-in:
        checkin_at

    Data e hora da liberação:
        released_at

    Observação da liberação:
        release_remark

    Motivo da última alteração:
        change_reason

    Data e hora da última atualização:
        updated_at

Os horários agendados deverão ser obtidos
através das definições operacionais existentes.

As durações deverão ser calculadas no backend.

Não criar colunas no banco exclusivamente
para armazenar valores calculados na exportação.

---

## 13. Tipos de dados do Excel

Garantir que as células possuam os tipos
de dados corretos.

### Texto

Utilizar texto para:

- Protocolo.
- Responsável.
- Empresa.
- Operação.
- Nota fiscal.
- Placa.
- Modelo do veículo.
- Status.
- Observações.
- Motivos.

### Data

Utilizar datas nativas do Excel para:

- Data de criação.
- Data agendada.
- Data do check-in.
- Data da liberação.
- Data da última atualização.

Formato visual:

    DD/MM/AAAA

Não exportar datas exclusivamente como strings.

### Horário

Utilizar valores temporais nativos do Excel para:

- Hora de criação.
- Horário inicial agendado.
- Horário final agendado.
- Hora do check-in.
- Hora da liberação.
- Hora da última atualização.

Formato visual:

    HH:mm:ss

Os horários agendados poderão utilizar:

    HH:mm

### Número

Utilizar valores numéricos para:

- Doca.
- Janela.
- Duração da operação.
- Atraso no check-in.
- Tempo excedido da janela.

Não adicionar unidades dentro das células numéricas.

As unidades deverão estar identificadas
nos nomes das colunas.

---

## 14. Preservação da nota fiscal

A nota fiscal deverá ser exportada
obrigatoriamente como texto.

Exemplo:

    000012345678

O Excel deverá preservar:

- Todos os zeros à esquerda.
- Todos os dígitos.
- Números extensos de até 44 caracteres.

Não converter a nota fiscal para:

- Integer.
- Float.
- Notação científica.
- Fórmula.

Não utilizar mecanismos que alterem
o conteúdo original da nota fiscal.

Garantir que números extensos não sofram
perda de precisão pelo Excel.

Validar também a leitura do arquivo
através do Power Query, quando disponível.

---

## 15. Protocolo e placa

Exportar o protocolo exatamente como persistido.

Exportar a placa normalizada conforme
as regras existentes.

Não modificar o formato dos valores.

Não incluir:

- ID interno.
- Request ID.
- Lock version.
- Tokens.
- Informações de sessão.

O protocolo será a referência operacional
para identificação da reserva.

---

## 16. Tipo de operação

Traduzir os valores existentes:

    entrega -> Entrega

    coleta -> Coleta

Não modificar o valor armazenado
no PostgreSQL.

A tradução deverá ocorrer somente
na geração do arquivo.

Reutilizar os helpers ou mapeamentos
existentes quando apropriado.

---

## 17. Docas e janelas

Preservar as oito docas físicas.

    01 até 08

Preservar as dez janelas operacionais:

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

Utilizar as definições centralizadas
existentes no Rails.

Não duplicar a definição dos horários
dentro do service de exportação.

Exportar doca e janela como números.

Utilizar, quando apropriado, formatação
numérica personalizada para apresentar
dois dígitos.

---

## 18. Fuso horário

Utilizar o fuso operacional:

    America/Sao_Paulo

Converter os timestamps armazenados
para o fuso operacional antes de separar
as datas e os horários exportados.

Exemplo:

    Timestamp UTC:
        2026-11-25 17:00:00 UTC

    Horário operacional:
        25/11/2026 14:00:00

Não exportar horários UTC como se fossem
horários locais.

Não utilizar o relógio do navegador.

Preservar a configuração de armazenamento
de timestamps existente no projeto.

Documentar que as datas e horas exportadas
representam o horário de Brasília.

---

## 19. Duração da operação

Calcular a duração efetiva utilizando:

    released_at - checkin_at

Converter o resultado para minutos.

Exemplo:

    Check-in: 10:05:00

    Liberação: 10:48:00

    Duração da operação: 43 minutos

Utilizar precisão de duas casas decimais.

Não calcular a duração utilizando
somente os horários sem considerar
as datas completas.

Considerar operações encerradas
após a meia-noite.

Exemplo:

    Check-in: 25/11/2026 às 17:20

    Liberação: 26/11/2026 às 00:20

    Duração: 420 minutos

A duração somente deverá ser preenchida
quando existirem:

- Check-in registrado.
- Liberação registrada.
- Intervalo temporal válido.

Para veículos ainda em operação,
deixar a célula vazia.

Não utilizar o horário atual como
horário fictício de liberação.

Não produzir durações negativas.

---

## 20. Atraso no check-in

Calcular a diferença entre:

    Horário efetivo de check-in

e:

    Data e horário inicial agendado

Exemplo:

    Início agendado: 10:00

    Check-in: 10:15

    Atraso no check-in: 15 minutos

Utilizar a seguinte regra conceitual:

    atraso = maior valor entre:

        0

        diferença em minutos entre
        check-in e início agendado

Utilizar duas casas decimais.

Considerar a data completa.

Quando não existir check-in,
deixar a célula vazia.

Não utilizar zero para representar
um check-in inexistente.

Importante:

Esse indicador representa a diferença
entre o início previsto e o check-in efetivo.

Não representa necessariamente atraso
causado pela transportadora.

Uma doca anteriormente ocupada também
poderá provocar essa diferença.

O cálculo não deverá alterar a classificação
operacional de chegada atrasada do RF008.

---

## 21. Tempo excedido da janela

Calcular a diferença entre:

    Horário efetivo de liberação

e:

    Data e horário final agendado

Exemplo:

    Término agendado: 11:00

    Liberação: 11:20

    Tempo excedido: 20 minutos

Utilizar a seguinte regra conceitual:

    tempo_excedido = maior valor entre:

        0

        diferença em minutos entre
        liberação e término agendado

Caso a operação seja concluída antes
ou exatamente no término da janela:

    Tempo excedido = 0

Quando não existir liberação,
deixar a célula vazia.

Não utilizar o horário atual para simular
uma liberação ainda não registrada.

Considerar corretamente:

- Datas completas.
- Operações após o expediente.
- Operações após a meia-noite.
- Última janela terminando às 17:48.

O indicador não deverá alterar
as regras operacionais existentes.

---

## 22. Exemplos de indicadores calculados

### Cenário 01 — Operação dentro da janela

    Janela: 10:00 - 11:00
    Check-in: 10:05
    Liberação: 10:48

    Duração: 43
    Atraso no check-in: 5
    Tempo excedido: 0

### Cenário 02 — Operação excedida

    Janela: 10:00 - 11:00
    Check-in: 10:15
    Liberação: 11:20

    Duração: 65
    Atraso no check-in: 15
    Tempo excedido: 20

### Cenário 03 — Veículo em operação

    Janela: 10:00 - 11:00
    Check-in: 10:10
    Liberação: não registrada

    Duração: vazio
    Atraso no check-in: 10
    Tempo excedido: vazio

### Cenário 04 — Veículo não compareceu

    Janela: 10:00 - 11:00
    Check-in: não registrado
    Liberação: não registrada
    Status: Reagendamento obrigatório

    Duração: vazio
    Atraso no check-in: vazio
    Tempo excedido: vazio

Não confundir ausência de informação
com valor numérico zero.

---

## 23. Campos sem informação

Quando um atributo não possuir valor,
exportar uma célula vazia.

Não preencher automaticamente com:

- N/A.
- Não registrado.
- Null.
- None.
- Traços.
- Zero.
- 00:00:00.
- Datas fictícias.

Exemplo:

    Reserva agendada sem check-in:

        Data do check-in: vazio
        Hora do check-in: vazio
        Data da liberação: vazio
        Hora da liberação: vazio
        Duração: vazio

Essa regra deverá facilitar a utilização
dos dados no Power Query e Power BI.

---

## 24. Tratamento de reagendamentos

A tabela bookings representa a posição
atualmente registrada da reserva.

Quando uma reserva for alterada
ou reagendada:

- Exportar sua posição atual.
- Preservar seu protocolo.
- Exportar seu status atual.
- Exportar o motivo da última alteração.

Não gerar uma linha adicional para cada
alteração histórica da mesma reserva.

Exemplo:

    Reserva original:
        Doca 03
        Janela 03

    Reserva alterada:
        Doca 05
        Janela 07

Resultado:

    Uma única linha com a posição atual.

O histórico das posições anteriores
continuará disponível no RF011.

Não reconstruir o histórico completo
através da planilha de agendamentos.

Documentar que a exportação representa
o estado atual dos registros.

---

## 25. Tratamento de cancelamentos

Reservas canceladas deverão permanecer
disponíveis para exportação.

Apresentar:

- Protocolo original.
- Dados cadastrais.
- Data agendada.
- Doca.
- Janela.
- Status Cancelado.
- Motivo da última alteração.

Não excluir registros históricos.

Não criar uma segunda linha para
representar o cancelamento.

Não reativar reservas durante
a exportação.

---

## 26. Formatação visual da planilha

Utilizar formatação corporativa simples.

Cabeçalho:

- Fundo azul institucional.
- Texto branco.
- Fonte em negrito.
- Alinhamento adequado.

Cor sugerida:

    #002664

Corpo:

- Fundo branco.
- Bordas discretas, quando necessário.
- Tipografia legível.
- Larguras adequadas.

Permitir linhas alternadas com cores discretas,
desde que não prejudiquem a utilização
da planilha como fonte de dados.

Não adicionar elementos decorativos
desnecessários.

Não utilizar estilos diferentes para
cada célula sem necessidade.

---

## 27. Autofiltro e congelamento

Adicionar autofiltro na linha de cabeçalho.

O filtro deverá abranger todas as colunas
e registros exportados.

Congelar a primeira linha da planilha.

Ao navegar verticalmente, os nomes
das colunas deverão permanecer visíveis.

Não adicionar células mescladas.

Não utilizar linhas adicionais acima
dos cabeçalhos.

---

## 28. Largura das colunas

Definir larguras adequadas conforme
o tipo de informação.

Exemplos:

    Protocolo: largura média
    Data: largura compacta
    Doca: largura compacta
    Janela: largura compacta
    Empresa: largura maior
    Nota fiscal: largura suficiente
    Observações: largura maior

Permitir leitura completa da nota fiscal.

Evitar que campos extensos produzam
colunas excessivamente largas.

Limitar a largura das colunas de texto livre.

Utilizar quebra de linha quando apropriado.

Não alterar o conteúdo original para
adequá-lo à largura da coluna.

---

## 29. Ordenação dos registros

Utilizar ordenação determinística.

Ordem sugerida:

    booking_date ASC
    slot_number ASC
    dock_number ASC
    id ASC

O ID interno poderá ser utilizado como
critério de desempate da ordenação.

Não deverá ser incluído na planilha.

Preservar a ordenação em exportações
realizadas com os mesmos registros.

Não ordenar datas através de strings
formatadas no padrão brasileiro.

---

## 30. Nome do arquivo

Gerar nomes claros e identificáveis.

Quando existir filtro por período:

    agendamentos_2026-11-01_a_2026-11-30.xlsx

Quando existir filtro de uma única data:

    agendamentos_2026-11-25.xlsx

Quando não existir filtro por período:

    agendamentos_completo_2026-11-25.xlsx

Utilizar somente caracteres seguros
no nome do arquivo.

Não permitir que parâmetros fornecidos
pelo navegador determinem arbitrariamente
o nome ou caminho do arquivo.

Utilizar a data operacional do servidor.

---

## 31. Download do arquivo

Após clicar em Exportar Excel,
gerar e disponibilizar o arquivo.

Utilizar o MIME type correto:

    application/vnd.openxmlformats-officedocument.
    spreadsheetml.sheet

Utilizar o valor acima sem quebra de linha
no cabeçalho HTTP.

Utilizar Content-Disposition como attachment.

Garantir que o navegador realize
o download corretamente.

Caso a aplicação utilize Turbo,
garantir compatibilidade com downloads
de arquivos binários.

Não interpretar a resposta XLSX
como um documento HTML.

Não depender de plugins do navegador.

---

## 32. Exportação sem resultados

Quando os filtros não encontrarem registros,
apresentar uma mensagem clara:

    Nenhum agendamento encontrado para
    os filtros selecionados.

Não gerar um arquivo corrompido.

Não apresentar erro interno.

Preferencialmente, informar a ausência
de registros antes do download.

Preservar os filtros selecionados.

---

## 33. Limites de exportação

A exportação deverá possuir proteção
contra solicitações excessivamente grandes.

Definir inicialmente um limite de:

    20.000 agendamentos por arquivo

Centralizar essa configuração.

Não truncar silenciosamente os registros.

Caso a quantidade encontrada ultrapasse
o limite, rejeitar a exportação e informar:

    O período selecionado possui muitos registros.
    Reduza o intervalo ou aplique filtros adicionais.

Não exportar somente os primeiros
20.000 registros sem informar o operador.

O limite inicial deverá ser avaliado
através de testes de desempenho.

Caso seja necessário utilizar outro limite,
documentar a justificativa e os resultados
observados.

---

## 34. Estratégia de processamento

Implementar inicialmente a geração síncrona
do arquivo XLSX.

O arquivo será gerado em resposta
à solicitação administrativa.

Não utilizar automaticamente o mecanismo
de jobs implementado no RF008.

Não criar filas de exportação neste requisito.

Avaliar:

- Tempo de geração.
- Consumo de memória.
- Quantidade de registros.
- Tamanho do arquivo.
- Impacto nas demais operações.

Caso a geração síncrona apresente limitações
significativas, documentar os resultados
e propor uma evolução posterior.

Não afirmar que o limite de 20.000 registros
é adequado sem realizar testes.

---

## 35. Consultas e desempenho

Utilizar consultas Active Record eficientes.

Aplicar os filtros no PostgreSQL.

Não carregar registros desnecessários
na memória.

Selecionar somente os atributos necessários
para a exportação, quando apropriado.

Evitar:

- N+1.
- Consultas individuais para cada registro.
- Consultas repetidas para docas.
- Consultas repetidas para janelas.
- Consultas individuais de auditoria.

Processar os registros em lotes quando
compatível com a biblioteca utilizada.

Preservar a ordenação definida.

Não afirmar que o processamento é streaming
se a biblioteca mantiver a planilha inteira
em memória.

Medir o consumo real de recursos.

Não adicionar Redis ou cache externo.

---

## 36. Segurança contra Formula Injection

Todos os campos provenientes de participantes
ou operadores deverão ser considerados
conteúdo não confiável.

Uma entrada fornecida pelo usuário
não poderá ser interpretada como fórmula
do Excel.

Considerar conteúdos iniciados por:

    =
    +
    -
    @

Considerar também:

- Tabulações.
- Quebras de linha.
- Espaços antes de caracteres especiais.
- Conteúdo que tente criar hyperlinks.
- Expressões DDE.
- Fórmulas com referências externas.

Exemplos de entradas que deverão
permanecer como texto:

    =1+1

    =HYPERLINK(...)

    +123456

    @SUM(...)

Aplicar tipos explícitos de string
aos campos textuais.

Não confiar apenas na detecção automática
de tipos da biblioteca XLSX.

Não utilizar entradas de usuários
como fórmulas.

Não criar hyperlinks automáticos
a partir de campos fornecidos.

Validar o XML interno do arquivo gerado
quando necessário.

Garantir que valores não confiáveis
sejam armazenados como texto, e não
como elementos de fórmula.

Preservar o conteúdo legítimo dos campos.

---

## 37. Segurança e privacidade

A exportação deverá estar disponível
exclusivamente no namespace administrativo.

Não criar endpoints públicos de exportação.

Não permitir exportação de terceiros
através do formulário público.

Não exportar:

- Senhas.
- Tokens.
- Cookies.
- Credenciais.
- Informações de sessão.
- Request ID.
- Lock version.
- Segredos de infraestrutura.
- JSON bruto de auditoria.

Os dados cadastrais exportados deverão
ser limitados às colunas previstas.

Configurar cabeçalhos de cache adequados.

Priorizar:

    Cache-Control: no-store

Não registrar o conteúdo integral
da planilha nos logs.

Não disponibilizar URLs públicas
permanentes para os arquivos.

Manter todas as rotas administrativas
restritas aos ambientes development e test.

Não disponibilizar a exportação
em produção antes da implementação
de autenticação e autorização.

---

## 38. Armazenamento dos arquivos

Não armazenar permanentemente
as planilhas exportadas.

Gerar o arquivo sob demanda.

Caso sejam utilizados arquivos temporários:

- Utilizar diretórios temporários apropriados.
- Utilizar nomes não previsíveis.
- Restringir permissões de acesso.
- Remover os arquivos após a utilização.
- Garantir limpeza em caso de falha.

Não armazenar arquivos exportados em:

    public/

Não criar um diretório público
de relatórios.

Não criar novas tabelas de exportação.

Não implementar Active Storage.

Não criar novos volumes Docker
exclusivamente para exportações.

---

## 39. Auditoria

A exportação será uma operação
administrativa de consulta.

Não modificar registros da tabela bookings.

Não modificar registros da tabela slot_blocks.

Não alterar eventos históricos.

Não criar eventos individuais de auditoria
para cada linha exportada.

Neste requisito, registrar somente
informações técnicas da geração nos logs:

- Horário da exportação.
- Quantidade de registros.
- Tempo de geração.
- Resultado da operação.
- Falha técnica, quando existente.

Não registrar:

- Nomes de responsáveis.
- Notas fiscais.
- Placas.
- Empresas.
- Observações.
- Conteúdo integral do arquivo.

A identificação individual de quem
realizou uma exportação deverá ser
avaliada após a implementação de usuários
e autenticação.

---

## 40. Rotas administrativas

Criar uma rota administrativa específica
para exportação.

Estrutura sugerida:

    GET /admin/bookings/export.xlsx

A nomenclatura poderá ser adaptada
às convenções existentes.

Garantir que a rota não seja interpretada
como um identificador de reserva.

A rota deverá:

1. Validar os filtros.
2. Construir a consulta.
3. Verificar a quantidade de registros.
4. Gerar a planilha.
5. Retornar o arquivo XLSX.

Utilizar GET exclusivamente para consulta
e geração do arquivo.

Não modificar registros de negócio.

Preservar as rotas existentes.

---

## 41. Organização do backend

Manter os controllers pequenos.

Centralizar a geração da planilha
em um service específico.

Estrutura sugerida:

    app/
    ├── controllers/
    │   └── admin/
    │       └── bookings_controller.rb
    │
    └── services/
        └── bookings/
            export_xlsx.rb

Reutilizar a lógica de filtros existente.

Caso seja necessário, extrair a consulta
compartilhada para um objeto específico.

Exemplo conceitual:

    BookingQuery
        |
        +-- Lista de agendamentos
        |
        +-- Exportação XLSX

Não criar abstrações genéricas
desnecessárias.

Não duplicar consultas.

Não executar regras de cálculo
diretamente nas views ERB.

---

## 42. Tratamento de erros

Apresentar mensagens claras em português.

### Período inválido

    A data inicial deve ser menor ou igual
    à data final.

### Nenhum resultado

    Nenhum agendamento encontrado para
    os filtros selecionados.

### Limite excedido

    A quantidade de agendamentos ultrapassa
    o limite permitido para exportação.
    Reduza o período selecionado.

### Falha de geração

    Não foi possível gerar o arquivo Excel.
    Tente novamente.

Não apresentar:

- Stack traces.
- Mensagens SQL.
- Caminhos internos de arquivos.
- Informações de infraestrutura.
- Detalhes de dependências.

Não disponibilizar arquivos parciais
ou corrompidos como exportações válidas.

---

## 43. JavaScript

Priorizar implementação sem JavaScript adicional.

Utilizar os recursos nativos do Rails
para realizar o download.

JavaScript poderá ser utilizado somente
quando necessário para:

- Melhorar o feedback visual do botão.
- Evitar cliques repetidos durante a geração.
- Preservar a experiência de navegação.

Não utilizar JavaScript para:

- Gerar o XLSX.
- Consultar diretamente o PostgreSQL.
- Calcular indicadores definitivos.
- Manipular regras de filtragem.
- Processar todos os registros no navegador.

Não introduzir bibliotecas como:

- SheetJS.
- ExcelJS.

Não utilizar:

- eval.
- new Function.
- Handlers JavaScript inline.
- Scripts de CDNs.
- innerHTML com conteúdo não confiável.

Preservar a Content Security Policy.

---

## 44. Banco de dados

Utilizar as tabelas existentes.

Principalmente:

    bookings

Não criar novas tabelas.

Não criar migrations exclusivamente
para armazenar indicadores calculados.

Não criar colunas para:

- Duração da operação.
- Atraso no check-in.
- Tempo excedido.
- Nome do arquivo exportado.
- Caminho do arquivo.

Não modificar migrations já aplicadas.

Preservar índices e constraints existentes.

Avaliar índices adicionais somente quando
houver uma necessidade demonstrável
de desempenho.

---

## 45. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 45.1 Geração do arquivo

Validar:

- Geração de arquivo XLSX válido.
- MIME type correto.
- Content-Disposition correto.
- Nome do arquivo.
- Nome da aba.
- Abertura do arquivo por um leitor XLSX.
- Cabeçalhos corretos.
- Ordem das colunas.
- Quantidade de registros.

Não considerar suficiente verificar
apenas a extensão do arquivo.

### 45.2 Filtros

Validar:

- Exportação por data.
- Exportação por período.
- Exportação por doca.
- Exportação por operação.
- Exportação por status.
- Combinação de filtros.
- Período histórico.
- Datas futuras.
- Período invertido.
- Data inválida.
- Exportação sem filtros.

### 45.3 Paginação

Validar:

- Exportação de todos os resultados.
- Ausência de restrição à página atual.
- Preservação dos filtros.
- Ordenação determinística.

### 45.4 Tipos de dados

Validar:

- Datas nativas do Excel.
- Horários nativos do Excel.
- Campos numéricos.
- Campos textuais.
- Células vazias.
- Preservação de zeros à esquerda.
- Nota fiscal de 44 dígitos.
- Ausência de notação científica.
- Preservação dos caracteres acentuados.

### 45.5 Duração da operação

Validar:

- Operação concluída.
- Operação inferior a uma hora.
- Operação superior a uma hora.
- Operação após expediente.
- Operação após meia-noite.
- Ausência de check-in.
- Ausência de liberação.
- Intervalo temporal inconsistente.
- Precisão de duas casas decimais.

### 45.6 Atraso no check-in

Validar:

- Check-in no horário inicial.
- Check-in posterior ao horário inicial.
- Ausência de check-in.
- Check-in anterior ao início em registro
  histórico inconsistente.
- Ausência de valores negativos.

### 45.7 Tempo excedido

Validar:

- Liberação antes do término.
- Liberação exatamente no término.
- Liberação após o término.
- Ausência de liberação.
- Última janela terminando às 17:48.
- Operação encerrada no dia seguinte.

### 45.8 Estados

Validar a exportação de:

- Agendado.
- Em operação.
- Liberado.
- Cancelado.
- Reagendamento obrigatório.

### 45.9 Alterações e histórico

Validar:

- Protocolo preservado após alteração.
- Exportação da posição atual.
- Motivo da última alteração.
- Uma linha por reserva.
- Ausência de duplicações por auditoria.
- Preservação dos registros cancelados.

### 45.10 Fuso horário

Validar:

- Conversão UTC para America/Sao_Paulo.
- Separação correta de data e hora.
- Registros próximos à meia-noite.
- Duração utilizando timestamps completos.

### 45.11 Formula Injection

Validar entradas contendo:

- Sinal de igualdade.
- Sinal de adição.
- Sinal de subtração.
- Arroba.
- Tabulações.
- Espaços iniciais.
- Quebras de linha.
- Expressões semelhantes a fórmulas.

Confirmar que as células são textuais.

Inspecionar a estrutura interna do XLSX
para confirmar a ausência de fórmulas
provenientes de entradas de usuários.

### 45.12 Segurança

Validar:

- Ausência de rota pública.
- Restrições administrativas em produção.
- Validação dos filtros.
- Proteção contra SQL Injection.
- Ausência de campos técnicos.
- Cabeçalhos HTTP adequados.
- Limpeza de arquivos temporários.
- Ausência de modificações nos registros.

### 45.13 Limites

Validar:

- Exportação sem registros.
- Exportação abaixo do limite.
- Exportação exatamente no limite.
- Rejeição acima do limite.
- Ausência de truncamento silencioso.

### 45.14 Regressão

Executar todos os testes existentes
dos RF001 até RF011.

Não remover ou enfraquecer testes anteriores.

---

## 46. Testes de desempenho

Realizar testes utilizando volumes
representativos de dados.

Volumes sugeridos:

    100 registros
    1.000 registros
    5.000 registros
    10.000 registros
    20.000 registros

Para cada cenário, registrar:

- Tempo de consulta.
- Tempo de geração do arquivo.
- Tempo total da operação.
- Consumo aproximado de memória.
- Tamanho do arquivo.
- Quantidade de consultas SQL.
- Impacto observado na aplicação.

Utilizar banco de teste ou ambiente
isolado de desenvolvimento.

Não inserir grandes volumes de dados
fictícios no banco operacional existente.

Não realizar testes destrutivos.

Não declarar resultados estimados
como resultados efetivamente medidos.

---

## 47. Validação manual

### Cenário 01 — Exportação simples

1. Acessar o painel administrativo.
2. Abrir a página Agendamentos.
3. Selecionar uma data.
4. Clicar em Exportar Excel.
5. Abrir o arquivo.
6. Conferir os dados exportados.

### Cenário 02 — Exportação por período

1. Selecionar uma data inicial.
2. Selecionar uma data final.
3. Aplicar os filtros.
4. Exportar o arquivo.
5. Confirmar que todos os resultados
   foram incluídos.

### Cenário 03 — Nota fiscal

1. Criar um registro de teste com
   nota fiscal contendo zeros à esquerda.
2. Exportar o arquivo.
3. Abrir no Excel.
4. Confirmar a preservação dos zeros.
5. Confirmar a ausência de notação científica.

### Cenário 04 — Indicadores

1. Localizar uma operação concluída.
2. Exportar o arquivo.
3. Conferir o check-in.
4. Conferir a liberação.
5. Calcular manualmente a duração.
6. Comparar com a coluna exportada.
7. Conferir o atraso no check-in.
8. Conferir o tempo excedido.

### Cenário 05 — Estados

1. Exportar reservas em estados diferentes.
2. Conferir reservas canceladas.
3. Conferir reservas em reagendamento.
4. Conferir reservas em operação.
5. Confirmar que campos ausentes
   permanecem vazios.

### Cenário 06 — Power Query

Quando disponível:

1. Importar a planilha no Power Query.
2. Verificar os cabeçalhos.
3. Conferir os tipos de dados.
4. Conferir as notas fiscais.
5. Conferir as colunas numéricas.
6. Confirmar a facilidade de tratamento.

Caso o Excel ou Power Query não esteja
disponível no ambiente do Codex,
informar essa limitação.

Validar programaticamente a estrutura
e os tipos de dados do arquivo.

Não declarar homologação no Microsoft Excel
sem ter realizado essa verificação.

---

## 48. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Verificar também:

- Dependência adicionada.
- Gemfile.lock.
- Funcionamento do Docker.
- Download do arquivo.
- Console do navegador.
- Ausência de erros inesperados.
- Preservação das funcionalidades anteriores.

Não desabilitar verificações para
obter resultados positivos.

---

## 49. Documentação

Registrar o requisito em:

    docs/requisitos/RF012.md

Atualizar:

- README.md.
- Índice de requisitos.
- Documentação operacional.

Documentar:

- Formato do arquivo.
- Biblioteca utilizada.
- Versão da biblioteca.
- Rota de exportação.
- Filtros disponíveis.
- Estrutura das colunas.
- Tipos de dados.
- Fuso horário.
- Fórmula conceitual da duração.
- Fórmula conceitual do atraso.
- Fórmula conceitual do tempo excedido.
- Limite de registros.
- Estratégia de processamento.
- Proteção contra Formula Injection.
- Estratégia de arquivos temporários.
- Resultados dos testes de desempenho.
- Limitações existentes.

Documentar que o arquivo representa
o estado atual das reservas.

Documentar que os indicadores calculados
não determinam responsabilidade pelo atraso.

Criar ADR somente quando existir uma
decisão arquitetural relevante.

---

## 50. Critérios de aceite

### Interface

- [ ] Botão Exportar Excel implementado.
- [ ] Layout administrativo preservado.
- [ ] Filtros existentes reutilizados.
- [ ] Filtro por período funcional.
- [ ] Download funcional.
- [ ] Mensagens de erro adequadas.

### Arquivo

- [ ] Formato XLSX válido.
- [ ] Nome do arquivo adequado.
- [ ] Aba Agendamentos criada.
- [ ] Cabeçalho na primeira linha.
- [ ] Colunas na ordem especificada.
- [ ] Uma linha por agendamento.
- [ ] Ausência de células mescladas.
- [ ] Autofiltro funcional.
- [ ] Primeira linha congelada.
- [ ] Formatação corporativa aplicada.

### Dados

- [ ] Todos os resultados filtrados exportados.
- [ ] Exportação independente da paginação.
- [ ] Datas nativas do Excel.
- [ ] Horários nativos do Excel.
- [ ] Campos numéricos corretos.
- [ ] Notas fiscais armazenadas como texto.
- [ ] Zeros à esquerda preservados.
- [ ] Números extensos preservados.
- [ ] Campos ausentes representados por células vazias.
- [ ] Todos os estados exportáveis.
- [ ] Protocolo original preservado.
- [ ] Posição atual da reserva exportada.
- [ ] Fuso America/Sao_Paulo aplicado.

### Indicadores

- [ ] Duração da operação calculada corretamente.
- [ ] Atraso no check-in calculado corretamente.
- [ ] Tempo excedido calculado corretamente.
- [ ] Operações após meia-noite consideradas.
- [ ] Última janela terminando às 17:48.
- [ ] Ausência de valores negativos indevidos.
- [ ] Ausência de dados fictícios.

### Segurança

- [ ] Exportação exclusivamente administrativa.
- [ ] Proteção contra Formula Injection.
- [ ] Campos textuais com tipos explícitos.
- [ ] Ausência de dados técnicos desnecessários.
- [ ] Ausência de arquivos públicos permanentes.
- [ ] Cache administrativo tratado.
- [ ] Arquivos temporários removidos.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma autenticação provisória criada.

### Desempenho

- [ ] Limite de registros implementado.
- [ ] Ausência de truncamento silencioso.
- [ ] Consultas eficientes.
- [ ] Ausência de N+1.
- [ ] Testes de desempenho realizados.
- [ ] Consumo de memória avaliado.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Estrutura XLSX validada.
- [ ] Testes de segurança executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 51. Fora do escopo

Não implementar neste requisito:

- Exportação CSV.
- Exportação PDF.
- Exportação completa da auditoria.
- Exportação dos bloqueios.
- Relatórios consolidados.
- Gráficos no Excel.
- Tabelas dinâmicas.
- Dashboards Excel.
- Integração automática com Power BI.
- Envio de planilhas por e-mail.
- Exportações recorrentes.
- Exportações agendadas.
- Filas de exportação.
- Armazenamento permanente dos arquivos.
- Upload de documentos.
- Active Storage.
- Cadastro de usuários.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Implantação na VPS.
- Redesign do painel administrativo.

Implementar exclusivamente a exportação
dos agendamentos para arquivos XLSX.

---

## 52. Entrega

Ao concluir o RF012, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Interface

- Screenshot do botão Exportar Excel.
- Screenshot dos filtros.
- Screenshot da planilha gerada.

### Arquivo Excel

- Exemplo de arquivo XLSX com dados de teste.
- Estrutura das colunas.
- Tipos de dados utilizados.
- Formatação aplicada.
- Validação das notas fiscais.
- Validação dos indicadores calculados.

### Backend

- Rotas criadas.
- Controllers modificados.
- Services criados ou reutilizados.
- Estratégia de filtragem.
- Estratégia de geração.
- Biblioteca utilizada.

### Desempenho

- Quantidade de registros testados.
- Tempo de geração.
- Tempo de resposta.
- Consumo de memória observado.
- Tamanho dos arquivos.
- Limitações encontradas.

### Segurança

- Proteção contra Formula Injection.
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
ou decisão técnica que necessite
de homologação.

---

## 53. Regra de parada

Ao concluir o RF012, PARE.

Não implementar o RF013.

Não implementar upload de documentos.

Não implementar envio de e-mails.

Não implementar cadastro de usuários.

Não implementar autenticação ou autorização.

Não modificar desnecessariamente
o layout administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.