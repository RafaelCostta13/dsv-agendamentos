# RF010 — Comprovante de Agendamento e QR Code

## 1. Objetivo

Implementar o comprovante de agendamento de veículos
da aplicação DSV Doca Agenda.

Após a confirmação bem-sucedida de um agendamento,
apresentar ao participante um comprovante contendo
as principais informações da reserva e um QR Code.

O comprovante deverá ser adequado para apresentação
através de dispositivos móveis.

Implementar:

- Comprovante de agendamento.
- Identificação visual da confirmação.
- Informações da reserva.
- QR Code funcional.
- Orientações operacionais.
- Orientação para captura de tela.
- Opção para realizar um novo agendamento.
- Visualização administrativa do comprovante.

Preservar todas as funcionalidades implementadas
até o RF009.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- docs/database/
- docs/requisitos/RF001.md até RF009.md
- docs/referencias/

Analisar a implementação atual do formulário público
e da página de confirmação criada no RF003.

Reutilizar a estrutura existente.

Não criar um segundo fluxo de confirmação.

Preservar a arquitetura monolítica Ruby on Rails.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Arquitetura

Utilizar:

- Ruby on Rails.
- Active Record.
- PostgreSQL.
- Views ERB.
- Helpers.
- Partials.
- CSS.
- Sistema de assets existente.

Gerar o conteúdo do comprovante no backend.

Gerar o QR Code no backend Ruby.

Não criar uma aplicação frontend independente.

Não introduzir:

- React.
- Vue.
- Angular.
- SPA.
- Node.js.
- TypeScript.
- Serviços externos de geração de QR Code.
- APIs externas desnecessárias.

Não utilizar JavaScript para gerar os dados
definitivos do comprovante.

---

## 4. Fluxo de confirmação

Preservar o fluxo existente de agendamento:

    Participante preenche o formulário
                |
                v
    Rails valida os dados
                |
                v
    Rails verifica disponibilidade
                |
                v
    PostgreSQL confirma a transação
                |
                v
    Comprovante de agendamento
                |
                v
    Participante salva uma captura de tela

O comprovante somente poderá representar
um agendamento efetivamente confirmado.

Não apresentar uma confirmação de sucesso
antes da conclusão da transação.

Não apresentar comprovantes para reservas
cuja criação tenha sido rejeitada.

---

## 5. Identidade visual

Utilizar a identidade visual existente
na aplicação DSV Doca Agenda.

Preservar:

- Azul institucional.
- Branco.
- Cinza claro.
- Verde para confirmação de sucesso.
- Tipografia existente.
- Bordas discretas.
- Espaçamento consistente.

Utilizar o mesmo logo oficial:

    app/assets/images/DSV_Logo.svg

Não redesenhar o logo.

Não criar cópias desnecessárias.

Utilizar o sistema de assets do Rails.

Não carregar imagens de URLs externas.

---

## 6. Estrutura visual do comprovante

Utilizar uma estrutura semelhante à seguinte:

    +---------------------------------------+
    | DSV | Doca Agenda                     |
    |       COLETAS E ENTREGAS              |
    +---------------------------------------+
    |                                       |
    |         Agendamento confirmado!       |
    |                                       |
    | Apresente este comprovante na chegada.|
    |                                       |
    | PROTOCOLO                             |
    | DA-XXXXXXXXXXXX                       |
    |                                       |
    | Operação: Entrega                     |
    | Data: 26/11/2026                      |
    | Doca: 03                              |
    | Horário: 10:00 às 11:00               |
    |                                       |
    | Empresa: Transportadora ABC           |
    | Placa: ABC1D23                        |
    |                                       |
    |              QR CODE                  |
    |                                       |
    | Salve uma captura de tela deste       |
    | comprovante.                          |
    |                                       |
    | Horário limite de check-in: 17:30     |
    |                                       |
    |    [ Realizar novo agendamento ]      |
    |                                       |
    +---------------------------------------+

A estrutura apresentada é uma referência.

Adaptar ao padrão visual existente no RF003.

Priorizar um comprovante compacto e legível.

Não realizar um redesign do formulário público.

---

## 7. Confirmação visual

Apresentar a mensagem:

    Agendamento confirmado!

Utilizar:

- Ícone de confirmação.
- Cor verde.
- Texto de destaque.
- Mensagem complementar.

Mensagem complementar:

    Apresente este comprovante na chegada à DSV.

Não apresentar mensagens que indiquem:

- Check-in realizado.
- Veículo em operação.
- Doca fisicamente disponível.
- Entrada automaticamente autorizada.

A confirmação representa somente a reserva
de uma posição na agenda.

---

## 8. Protocolo

Utilizar o protocolo existente da reserva:

    bookings.protocol

Exemplo:

    DA-7F3A92B8C104

O protocolo deverá possuir destaque visual.

Garantir:

- Boa legibilidade.
- Possibilidade de seleção do texto.
- Ausência de truncamento.
- Adaptação para telas pequenas.

Não gerar um novo protocolo.

Não modificar o protocolo original.

Não utilizar o ID interno como protocolo público.

---

## 9. Informações do comprovante

Apresentar os seguintes dados:

- Protocolo.
- Tipo de operação.
- Data agendada.
- Número da doca.
- Horário inicial da janela.
- Horário final da janela.
- Empresa / transportadora.
- Placa do veículo.

Utilizar os dados efetivamente persistidos
no PostgreSQL.

Não utilizar os parâmetros originais do formulário
como fonte definitiva das informações.

Não apresentar:

- ID interno da reserva.
- Request ID.
- Lock version.
- Informações de infraestrutura.
- Motivos administrativos internos.
- Dados de outras reservas.
- Eventos internos de auditoria.

Neste requisito, não incluir no comprovante:

- Nome completo do responsável.
- Número da nota fiscal.
- Documentos pessoais.

Esses dados permanecem disponíveis internamente
no painel administrativo.

---

## 10. Formatação das informações

### Data

Utilizar o padrão brasileiro:

    DD/MM/AAAA

### Horário

Utilizar:

    HH:mm

Exemplo:

    10:00 às 11:00

### Doca

Apresentar dois dígitos:

    Doca 01
    Doca 02
    ...
    Doca 08

### Operação

Apresentar:

    entrega -> Entrega
    coleta  -> Coleta

### Placa

Utilizar a placa normalizada e persistida
no banco de dados.

Utilizar o fuso operacional:

    America/Sao_Paulo

Reutilizar os helpers e definições existentes.

---

## 11. Docas e janelas

Preservar:

    8 docas físicas
    10 janelas de horários

Reutilizar as definições fixas existentes
no backend Rails.

Preservar a última janela:

    17:00 às 17:48

Não criar tabelas de cadastro de docas.

Não criar tabelas de cadastro de janelas.

Não duplicar as definições operacionais.

---

## 12. QR Code

Gerar um QR Code funcional para cada comprovante.

O QR Code deverá ser gerado a partir das informações
operacionais da reserva.

Não utilizar uma imagem ilustrativa ou fictícia.

Não utilizar serviços externos de geração de QR Code.

Priorizar uma biblioteca Ruby compatível
com a versão instalada.

Avaliar a utilização da gem:

    rqrcode

Antes de adicionar a dependência:

- Verificar compatibilidade.
- Verificar manutenção.
- Verificar licença.
- Verificar dependências transitivas.
- Verificar vulnerabilidades conhecidas.
- Registrar a justificativa técnica.

Adicionar somente as dependências necessárias.

Preservar o Gemfile.lock.

Não atualizar dependências não relacionadas
ao requisito.

---

## 13. Conteúdo do QR Code

O QR Code deverá armazenar informações textuais
simples e legíveis.

Estrutura sugerida:

    DESTINO: DSV
    SISTEMA: DOCA AGENDA
    PROTOCOLO: DA-7F3A92B8C104
    OPERACAO: ENTREGA
    DATA: 26/11/2026
    DOCA: 03
    HORARIO: 10:00 - 11:00
    FUSO: HORARIO DE BRASILIA

O conteúdo deverá ser gerado exclusivamente
no backend.

Utilizar valores provenientes da reserva persistida
e das definições operacionais existentes.

O conteúdo deverá poder ser interpretado
por leitores de QR Code convencionais.

Não exigir aplicativo proprietário.

Não utilizar criptografia desnecessária
para representar essas informações.

---

## 14. Privacidade do QR Code

Não incluir no conteúdo do QR Code:

- Nome do responsável.
- Empresa / transportadora.
- Nota fiscal.
- Placa do veículo.
- Modelo do veículo.
- CPF.
- CNH.
- Telefone.
- E-mail.
- ID interno.
- Request ID.
- Tokens de sessão.
- Credenciais.
- Informações administrativas.

O QR Code deverá conter somente os dados
operacionais necessários para identificar
o agendamento.

A existência de um QR Code não representa
uma autorização de acesso.

O protocolo não deverá ser tratado como
uma credencial de autenticação.

---

## 15. Formato e apresentação do QR Code

Priorizar a geração em SVG ou PNG.

Utilizar um formato que preserve a qualidade
da leitura em dispositivos móveis.

Características:

- Fundo branco.
- Módulos escuros.
- Contraste elevado.
- Margem de segurança ao redor do código.
- Dimensões adequadas.
- Proporção quadrada.
- Ausência de distorção.

Utilizar inicialmente uma dimensão visual
entre 180px e 240px, ajustável conforme
os resultados dos testes de leitura.

Não inserir o logo DSV sobre o QR Code.

Não adicionar elementos decorativos
que prejudiquem sua leitura.

Não recortar a margem de segurança.

Testar a leitura do código apresentado
em diferentes tamanhos de tela.

---

## 16. Segurança na geração do QR Code

Não concatenar dados não confiáveis
diretamente em código HTML ou SVG.

Não utilizar raw ou html_safe sobre
conteúdo proveniente de participantes.

Caso seja utilizado SVG, garantir que
a imagem seja produzida exclusivamente
por uma biblioteca confiável e contenha
somente os elementos necessários.

Não incluir:

- Scripts.
- Handlers de eventos.
- Referências externas.
- Links externos.
- Conteúdo HTML incorporado.

Priorizar a apresentação através de uma
imagem gerada pelo servidor.

Preservar a Content Security Policy existente.

Não adicionar unsafe-inline ou unsafe-eval.

Não ampliar indiscriminadamente as diretivas
da CSP para permitir a exibição do QR Code.

Caso a estratégia de geração exija alguma
alteração de segurança, documentar e justificar
a alternativa mais restritiva possível.

---

## 17. Armazenamento do QR Code

Neste requisito, não armazenar arquivos
de QR Code permanentemente.

Gerar a imagem sob demanda a partir
dos dados existentes da reserva.

Não criar:

- Tabela de QR Codes.
- Coluna qr_code.
- Coluna qr_code_url.
- Diretório público de comprovantes.
- Arquivos permanentes por agendamento.

Não implementar Active Storage.

Não utilizar serviços externos de armazenamento.

Não criar novos volumes Docker exclusivamente
para armazenar imagens de QR Code.

A geração deverá ser determinística para
o mesmo conteúdo operacional.

---

## 18. Comportamento após alterações administrativas

O comprovante deverá considerar a posição
atualmente registrada na reserva.

Quando um agendamento for alterado pelo RF006:

- Preservar o protocolo.
- Atualizar a data no comprovante administrativo.
- Atualizar a doca.
- Atualizar a janela.
- Gerar um QR Code correspondente à nova posição.

Exemplo:

    Comprovante original:

        Protocolo: DA-XXXXXXXX
        Data: 26/11/2026
        Doca: 03
        Horário: 10:00 - 11:00

    Após reagendamento:

        Protocolo: DA-XXXXXXXX
        Data: 27/11/2026
        Doca: 05
        Horário: 14:00 - 15:00

O protocolo permanece igual.

As informações operacionais são atualizadas.

Uma captura de tela antiga não será
automaticamente atualizada.

O QR Code antigo não deverá ser considerado
prova de que a posição original ainda é válida.

O banco de dados será sempre a fonte
de verdade da operação.

---

## 19. Reservas canceladas

Não apresentar um comprovante de reserva
cancelada como se estivesse válido.

Ao consultar administrativamente uma
reserva cancelada, apresentar:

    Agendamento cancelado

Não disponibilizar um comprovante com
mensagem de confirmação ativa.

Não gerar um QR Code que represente
uma reserva cancelada como agendamento válido.

Preservar o histórico da reserva.

Não alterar os registros existentes.

---

## 20. Reservas em reagendamento

Quando a reserva estiver no estado:

    reagendamento

Apresentar:

    Reagendamento obrigatório

Não apresentar a posição anterior
como uma reserva atualmente válida.

Não gerar um novo comprovante confirmado
até que a reserva seja reagendada
através do fluxo existente do RF006.

Preservar o protocolo original.

---

## 21. Reservas em operação ou liberadas

Para reservas nos estados:

    em_operacao
    liberado

Permitir a consulta administrativa das
informações da reserva.

Exibir o estado efetivamente registrado.

Não apresentar essas reservas como
aguardando uma nova entrada.

Não gerar uma nova reserva.

Não modificar os horários efetivos.

O comprovante não deverá permitir
repetir o check-in de um veículo.

Preservar as regras do RF005.

---

## 22. Orientações operacionais

Apresentar uma mensagem orientando
o participante a salvar o comprovante.

Texto sugerido:

    Salve uma captura de tela deste comprovante
    para apresentar na chegada à DSV.

Apresentar também:

    Horário limite para check-in: 17:30.

Informar que:

- O check-in não poderá ocorrer antes
  do início da janela agendada.
- A entrada dependerá da disponibilidade
  física da doca.
- O comprovante não substitui o check-in.

Não criar tolerâncias de atraso diferentes
das regras existentes.

Não prometer que o veículo será liberado
até o horário final da janela.

Não apresentar o QR Code como autorização
automática de entrada.

---

## 23. Captura de tela

O comprovante deverá ser visualmente adequado
para utilização através de capturas de tela.

Priorizar:

- Layout compacto.
- Informações organizadas.
- QR Code legível.
- Protocolo destacado.
- Ausência de elementos desnecessários.

Não implementar acesso à câmera.

Não solicitar permissões do dispositivo.

Não criar mecanismos JavaScript para
capturar automaticamente a tela.

Utilizar a funcionalidade nativa de captura
de tela do celular.

Não afirmar que todos os dispositivos
conseguirão capturar o comprovante inteiro
em uma única imagem.

---

## 24. Novo agendamento

Disponibilizar o botão:

    Realizar novo agendamento

Direcionar para a rota existente:

    /agendar

Ao iniciar um novo agendamento:

- Apresentar um formulário novo.
- Gerar um novo request_id.
- Limpar os dados da tentativa anterior.
- Preservar as regras de idempotência.

Não reutilizar o request_id da reserva anterior.

Não criar automaticamente um novo agendamento
ao clicar no botão.

---

## 25. Impressão

Preparar o comprovante para impressão
utilizando CSS de impressão.

Utilizar:

    @media print

Na impressão:

- Preservar o logo.
- Preservar o protocolo.
- Preservar os dados operacionais.
- Preservar o QR Code.
- Ocultar botões de navegação.
- Ocultar elementos desnecessários.
- Evitar cortes no conteúdo.

Utilizar fundo branco.

Garantir contraste adequado.

Não implementar geração de PDF pelo servidor.

Não adicionar bibliotecas como:

- Wicked PDF.
- Prawn.
- PDFKit.
- Ferramentas externas de conversão.

A impressão nativa do navegador deverá
ser suficiente neste requisito.

---

## 26. Integração com o painel administrativo

Na página de detalhes do agendamento,
adicionar uma ação:

    Visualizar comprovante

Permitir consultar o comprovante utilizando
os dados atualmente registrados.

Utilizar o layout administrativo existente
ou uma visualização específica de impressão.

Reutilizar o componente de comprovante
da confirmação pública.

Não duplicar a lógica de geração do QR Code.

Não duplicar as regras de formatação.

Não adicionar um novo menu à Sidebar.

Não modificar a matriz do Dashboard.

Não alterar o polling implementado no RF009.

---

## 27. Rotas

Reutilizar o mecanismo seguro de confirmação
implementado no RF003.

Caso seja necessária uma rota administrativa,
utilizar como referência:

    GET /admin/bookings/:id/receipt

A rota deverá seguir as convenções existentes.

Não criar rotas públicas que permitam
consultar comprovantes arbitrariamente por:

- ID interno.
- Protocolo.
- Request ID.

Não utilizar o protocolo como única
proteção para acesso aos dados da reserva.

Não criar endpoints públicos de busca
por placa ou nota fiscal.

Não implementar compartilhamento público
permanente de comprovantes neste requisito.

---

## 28. Acesso ao comprovante público

O comprovante público deverá estar associado
ao fluxo legítimo de confirmação da reserva.

Preservar o padrão Post/Redirect/Get existente,
quando aplicável.

Não permitir enumeração de reservas.

Não armazenar dados pessoais completos
em cookies.

Não transmitir dados pessoais através
de parâmetros de URL.

Não armazenar dados da reserva em:

- localStorage.
- sessionStorage.

Caso a confirmação existente não possua
uma estratégia segura de acesso, corrigir
somente o necessário para este requisito.

O acesso deverá ser temporário e restrito
ao contexto da confirmação da reserva.

Documentar a estratégia adotada.

Não implementar autenticação completa.

Não criar uma rota pública permanente
de consulta de comprovantes.

Configurar proteção contra cache indevido
nas respostas que contenham dados da reserva.

---

## 29. Idempotência

Preservar integralmente o mecanismo
de idempotência existente.

Atualizar a página de comprovante
não deverá provocar:

- Novo agendamento.
- Novo protocolo.
- Novo request_id para a reserva existente.
- Novo evento de criação.
- Duplicação de registros.

O reenvio legítimo da solicitação original
deverá respeitar as regras dos RF003 e RF006.

Uma solicitação idempotente não poderá
reativar uma reserva cancelada.

Não apresentar informações antigas como
uma nova confirmação válida.

Não restaurar posições anteriores.

---

## 30. Auditoria

A geração e visualização do comprovante
são operações de consulta.

Não criar eventos de auditoria a cada
visualização ou geração do QR Code.

Preservar os eventos existentes de:

- Criação de reserva.
- Alteração.
- Cancelamento.
- Reagendamento.
- Check-in.
- Liberação.
- No-show.

Não modificar o histórico.

Não criar uma nova tabela de auditoria.

Não registrar o conteúdo integral
do comprovante nos logs.

---

## 31. Organização do backend

Manter os controllers pequenos.

Separar, quando necessário:

- Preparação dos dados do comprovante.
- Formatação das informações.
- Geração do conteúdo textual do QR Code.
- Geração da imagem do QR Code.

Estrutura sugerida:

    app/services/
        bookings/
            receipt_qr_code.rb

    app/views/
        bookings/
            confirmation.html.erb
            _receipt.html.erb

    app/views/
        admin/
            bookings/
                receipt.html.erb

A estrutura apresentada é uma sugestão.

Adaptar às convenções existentes.

Não criar abstrações genéricas
ou arquivos desnecessários.

Reutilizar um componente compartilhado
para apresentação do comprovante.

Não executar consultas diretamente nas views.

---

## 32. Responsividade

Priorizar dispositivos móveis.

Validar larguras de tela:

    320px
    375px
    390px
    414px
    430px
    768px
    1024px
    1440px

Garantir:

- Ausência de scroll horizontal.
- QR Code sem distorção.
- Protocolo legível.
- Textos sem sobreposição.
- Botões acessíveis.
- Espaçamento adequado.
- Informações organizadas.

Em computadores, centralizar o comprovante.

Não ocupar desnecessariamente toda
a largura da tela.

Preservar a identidade visual existente.

---

## 33. Acessibilidade

Utilizar:

- HTML semântico.
- Hierarquia adequada de títulos.
- Contraste suficiente.
- Textos descritivos.
- Botões e links acessíveis.
- Estados de foco visíveis.

O QR Code deverá possuir uma descrição
alternativa adequada.

As informações contidas no QR Code
também deverão estar disponíveis em texto
no comprovante.

Não tornar o QR Code a única forma
de identificar o agendamento.

Não desabilitar o zoom do navegador.

---

## 34. JavaScript

Priorizar uma implementação sem
JavaScript adicional.

A geração e apresentação do comprovante
deverão funcionar através do Rails.

Não utilizar JavaScript para:

- Gerar o protocolo.
- Definir o estado da reserva.
- Consultar diretamente o banco.
- Gerar os dados operacionais definitivos.
- Alterar horários.
- Executar check-in.
- Liberar docas.

Não adicionar bibliotecas JavaScript
de geração de QR Code.

Não utilizar:

- eval.
- new Function.
- document.write.
- innerHTML com conteúdo não confiável.
- Handlers inline.
- Scripts de CDNs.

Preservar a Content Security Policy.

---

## 35. Banco de dados

Utilizar a estrutura existente:

    bookings
    slot_blocks
    audit_events

Não criar novas tabelas de negócio.

Não criar migrations neste requisito,
salvo necessidade indispensável
e devidamente justificada.

Não adicionar campos para armazenar
o QR Code.

Não duplicar os dados da reserva
em uma tabela de comprovantes.

Não modificar migrations existentes.

Não alterar os índices e constraints
implementados anteriormente.

---

## 36. Segurança

Preservar todas as proteções implementadas
nos requisitos anteriores.

Utilizar:

- Escaping padrão do ERB.
- Validação de parâmetros.
- Consultas parametrizadas.
- Proteção CSRF nas operações de escrita.
- Content Security Policy.
- Controle adequado de cache.

Não utilizar raw ou html_safe para exibir
dados fornecidos por participantes.

Não permitir consulta arbitrária
de comprovantes de terceiros.

Não considerar o QR Code um mecanismo
de autenticação.

Manter as rotas administrativas restritas
aos ambientes de desenvolvimento e teste.

Não implementar:

- Cadastro de usuários.
- Login.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.

Não disponibilizar o painel administrativo
em produção enquanto essas proteções
não estiverem implementadas.

---

## 37. Testes automatizados

Utilizar Minitest e PostgreSQL.

### 37.1 Confirmação

Validar:

- Agendamento criado com sucesso.
- Comprovante apresentado após confirmação.
- Protocolo correto.
- Operação correta.
- Data correta.
- Doca correta.
- Janela correta.
- Empresa correta.
- Placa correta.
- Logo oficial apresentado.

### 37.2 QR Code

Validar:

- Geração de uma imagem válida.
- Conteúdo correspondente à reserva.
- Protocolo correto.
- Destino DSV.
- Operação correta.
- Data correta.
- Doca correta.
- Horário correto.
- Fuso operacional correto.
- Ausência de informações pessoais.
- Ausência de credenciais.
- Ausência de IDs internos.
- Ausência de referências externas.

Validar a decodificação efetiva do QR Code.

Não considerar suficiente apenas verificar
a existência de uma imagem na página.

Caso seja necessária uma ferramenta de
decodificação para testes, justificar
sua utilização.

Restringir dependências adicionais
ao ambiente de teste quando possível.

### 37.3 Formatação

Validar:

- Datas no padrão brasileiro.
- Horários no formato HH:mm.
- Docas com dois dígitos.
- Última janela encerrando às 17:48.
- Operações apresentadas em português.

### 37.4 Alterações administrativas

Validar:

- Preservação do protocolo.
- Atualização da data.
- Atualização da doca.
- Atualização da janela.
- Novo conteúdo de QR Code correspondente
  à posição atual.
- Ausência de criação de uma nova reserva.

### 37.5 Estados

Validar:

- Reserva agendada.
- Reserva em operação.
- Reserva liberada.
- Reserva cancelada.
- Reserva em reagendamento.

Garantir que reservas canceladas ou
em reagendamento não sejam apresentadas
como reservas confirmadas e válidas.

### 37.6 Idempotência

Validar:

- Atualização da página.
- Reenvio da solicitação original.
- Ausência de novos agendamentos.
- Ausência de protocolos duplicados.
- Ausência de eventos de auditoria duplicados.
- Preservação de alterações administrativas.

### 37.7 Segurança

Validar:

- Tentativa de consultar comprovante de terceiro.
- Tentativa de acesso por ID manipulado.
- Tentativa de acesso por protocolo.
- Ausência de dados pessoais no QR Code.
- Ausência de dados sensíveis na URL.
- Escaping de informações da empresa.
- Proteção contra XSS.
- Preservação da CSP.
- Restrições administrativas em produção.
- Ausência de referências externas
  na imagem gerada.

### 37.8 Regressão

Executar todos os testes existentes
dos RF001 até RF009.

Garantir que continuam funcionando:

- Formulário público.
- Disponibilidade.
- Criação de reservas.
- Idempotência.
- Painel administrativo.
- Check-in.
- Liberação.
- Cancelamento.
- Reagendamento.
- Bloqueios.
- No-show.
- Atualização automática.

Não remover ou enfraquecer testes anteriores.

---

## 38. Validação manual

### Cenário 01 — Agendamento

1. Acessar /agendar.
2. Preencher o formulário.
3. Selecionar uma posição disponível.
4. Confirmar o agendamento.
5. Verificar a apresentação do comprovante.
6. Conferir o protocolo.
7. Conferir os dados da reserva.
8. Confirmar a presença do QR Code.

### Cenário 02 — Leitura do QR Code

1. Exibir o comprovante no computador.
2. Utilizar um leitor de QR Code convencional.
3. Realizar a leitura.
4. Conferir o conteúdo textual.
5. Confirmar a ausência de dados pessoais.

### Cenário 03 — Dispositivo móvel

1. Abrir o comprovante no celular.
2. Verificar a responsividade.
3. Realizar uma captura de tela.
4. Abrir a imagem capturada.
5. Testar a leitura do QR Code na imagem.

### Cenário 04 — Alteração

1. Criar um agendamento.
2. Registrar o protocolo original.
3. Alterar a data, doca ou janela
   pelo painel administrativo.
4. Visualizar o comprovante administrativo.
5. Confirmar os dados atualizados.
6. Confirmar a preservação do protocolo.
7. Decodificar o QR Code atualizado.

### Cenário 05 — Cancelamento

1. Cancelar uma reserva.
2. Consultar seus detalhes administrativos.
3. Verificar a indicação de cancelamento.
4. Confirmar que não existe comprovante
   apresentado como válido.

### Cenário 06 — Novo agendamento

1. Confirmar uma reserva.
2. Selecionar Realizar novo agendamento.
3. Verificar a abertura de um formulário novo.
4. Confirmar a utilização de outro request_id.

### Cenário 07 — Impressão

1. Abrir o comprovante.
2. Utilizar a impressão do navegador.
3. Verificar o layout de impressão.
4. Confirmar a ausência de cortes.
5. Verificar o QR Code impresso ou renderizado
   na pré-visualização.
6. Confirmar que os botões estão ocultos.

Caso não seja possível realizar testes
com um dispositivo físico, informar essa
limitação na entrega.

Não declarar leitura física validada
sem efetivamente realizar o teste.

---

## 39. Ferramentas de qualidade

Executar:

- Suíte completa de testes Minitest.
- RuboCop.
- Brakeman.
- Bundler Audit.

Verificar também:

- Console do navegador.
- Carregamento dos assets.
- Renderização do comprovante.
- Ausência de violações inesperadas de CSP.
- Ausência de solicitações externas
  para gerar QR Code.
- Funcionamento da página de impressão.

Não declarar testes aprovados
sem efetivamente executá-los.

---

## 40. Documentação

Registrar este requisito em:

    docs/requisitos/RF010.md

Atualizar o índice de requisitos.

Documentar:

- Fluxo de confirmação.
- Estrutura do comprovante.
- Campos apresentados.
- Campos excluídos por privacidade.
- Conteúdo do QR Code.
- Biblioteca utilizada.
- Estratégia de geração.
- Estratégia de acesso ao comprovante.
- Proteções de segurança.
- Comportamento após reagendamento.
- Comportamento após cancelamento.
- Impressão.
- Limitações existentes.

Registrar uma ADR somente quando existir
uma nova decisão arquitetural relevante.

---

## 41. Critérios de aceite

### Comprovante

- [ ] Apresentado após criação bem-sucedida.
- [ ] Logo oficial utilizado.
- [ ] Identidade visual preservada.
- [ ] Protocolo destacado.
- [ ] Operação apresentada.
- [ ] Data apresentada.
- [ ] Doca apresentada.
- [ ] Janela apresentada.
- [ ] Empresa apresentada.
- [ ] Placa apresentada.
- [ ] Layout responsivo.
- [ ] Orientação para captura de tela.
- [ ] Orientações operacionais.
- [ ] Novo agendamento funcional.
- [ ] Layout de impressão funcional.

### QR Code

- [ ] Gerado no backend Ruby.
- [ ] Biblioteca compatível utilizada.
- [ ] Imagem funcional.
- [ ] Conteúdo textual correto.
- [ ] Leitura efetivamente validada.
- [ ] Ausência de dados pessoais.
- [ ] Ausência de IDs internos.
- [ ] Ausência de credenciais.
- [ ] Ausência de dependência externa.
- [ ] Ausência de armazenamento permanente.

### Integração

- [ ] Confirmação do RF003 reutilizada.
- [ ] Consulta administrativa implementada.
- [ ] Protocolo preservado.
- [ ] Reagendamentos refletidos.
- [ ] Reservas canceladas tratadas.
- [ ] Reservas em reagendamento tratadas.
- [ ] Estados operacionais preservados.
- [ ] Idempotência preservada.
- [ ] Auditoria existente preservada.
- [ ] Dashboard preservado.
- [ ] Polling do RF009 preservado.

### Segurança

- [ ] Nenhuma consulta pública arbitrária.
- [ ] Nenhuma exposição de reservas de terceiros.
- [ ] Nenhum dado pessoal na URL.
- [ ] Escaping padrão preservado.
- [ ] Content Security Policy preservada.
- [ ] Cache administrativo tratado.
- [ ] Rotas administrativas indisponíveis em produção.
- [ ] Nenhuma autenticação provisória criada.
- [ ] Nenhuma vulnerabilidade alta ou crítica
      conhecida sem tratamento.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Decodificação do QR Code validada.
- [ ] Testes de responsividade executados.
- [ ] Testes de regressão aprovados.
- [ ] RuboCop executado.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] Documentação atualizada.

---

## 42. Fora do escopo

Não implementar neste requisito:

- Leitor de QR Code no painel administrativo.
- Leitura através da câmera do navegador.
- Check-in automático por QR Code.
- Liberação automática por QR Code.
- Aplicativo mobile.
- Geolocalização.
- Assinatura digital.
- Comprovante como credencial de acesso.
- Consulta pública de reservas por protocolo.
- Geração de PDF no servidor.
- Armazenamento permanente do QR Code.
- Envio de comprovante por e-mail.
- Envio de comprovante por WhatsApp.
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

Implementar exclusivamente o comprovante
de agendamento e a geração do QR Code.

---

## 43. Entrega

Ao concluir o RF010, apresentar:

### Resumo

- Funcionalidades implementadas.
- Decisões técnicas tomadas.

### Interface

- Screenshot do comprovante em desktop.
- Screenshot do comprovante em mobile.
- Screenshot da visualização administrativa.
- Screenshot da versão de impressão.

### QR Code

- Biblioteca utilizada.
- Versão instalada.
- Justificativa da escolha.
- Conteúdo textual gerado.
- Formato da imagem.
- Estratégia de geração.
- Resultado dos testes de decodificação.
- Resultado dos testes de leitura física,
  quando realizados.

### Backend

- Controllers modificados.
- Services criados ou reutilizados.
- Helpers criados ou reutilizados.
- Rotas criadas ou reutilizadas.
- Views e partials.
- Estratégia de acesso ao comprovante.

### Banco de dados

- Tabelas utilizadas.
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
- Resultado do RuboCop.
- Testes não executados e motivos.

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

## 44. Regra de parada

Ao concluir o RF010, PARE.

Não implementar o RF011.

Não implementar leitura de QR Code.

Não implementar envio de e-mails.

Não implementar geração de PDF.

Não implementar autenticação ou autorização.

Preservar o layout administrativo aprovado.

Deixar a aplicação operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.