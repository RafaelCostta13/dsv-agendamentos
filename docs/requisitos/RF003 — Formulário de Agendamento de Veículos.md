# RF003 — Formulário de Agendamento de Veículos

## 1. Objetivo

Implementar a página pública de agendamento de veículos
da aplicação DSV Doca Agenda.

A página deverá permitir que transportadoras e demais
participantes realizem agendamentos de entrega ou coleta,
selecionando uma data, uma doca e uma janela de horário.

O formulário deverá utilizar a estrutura de banco de dados
criada no RF002.

A implementação deverá ser funcional, persistindo os
agendamentos no PostgreSQL.

Utilizar as imagens disponibilizadas como referência visual.

Priorizar:

- Simplicidade.
- Segurança.
- Integridade dos dados.
- Responsividade.
- Facilidade de preenchimento.
- Recursos nativos do Ruby on Rails.
- Manutenibilidade.

---

## 2. Documentação obrigatória

Antes de iniciar, consultar:

- AGENTS.md
- README.md
- .agents/skills/
- docs/adr/
- Especificações RF001 e RF002 em docs/requisitos/
- docs/adr/0005-registro-objetivo-das-entregas.md
- docs/database/
- docs/referencias/

Analisar as migrations e os models implementados no RF002.

Não recriar estruturas que já existem.

Não modificar a arquitetura monolítica da aplicação.

Trabalhar exclusivamente dentro do repositório atual.

---

## 3. Referências visuais

Utilizar como referência os arquivos:

- docs/referencias/layout/Image (5).jpg
- docs/referencias/layout/Image (6).jpg
- docs/referencias/layout/Image (7).jpg
- docs/referencias/layout/Image (8).jpg

As imagens representam o formulário do protótipo original.

Utilizar as referências para compreender:

- Identidade visual.
- Cabeçalho.
- Tipografia.
- Paleta de cores.
- Organização dos campos.
- Separação das seções.
- Seleção da operação.
- Seleção da data.
- Seleção da doca.
- Seleção dos horários.
- Botão de confirmação.
- Responsividade mobile.

Não copiar o código da aplicação anterior.

Não utilizar as imagens como componentes da interface.

Reconstruir o layout utilizando HTML, ERB e CSS.

O Codex terá liberdade para realizar melhorias visuais,
desde que preserve a identidade corporativa e a organização
conceitual apresentada nas referências.

Caso algum arquivo de referência não seja encontrado,
informar na entrega.

---

## 4. Arquitetura da implementação

Manter a arquitetura MVC tradicional do Rails.

Utilizar:

- Routes.
- Controllers.
- Models.
- Views ERB.
- Helpers.
- Partials, quando necessário.
- Active Record.
- CSS.
- JavaScript somente quando necessário.

O fluxo deverá seguir:

    Navegador
        |
        v
    Routes
        |
        v
    Controller
        |
        v
    Model / Regras de negócio
        |
        v
    PostgreSQL

As páginas deverão ser renderizadas pelo servidor.

Não criar uma aplicação frontend independente.

Não criar uma API REST apenas para alimentar
o próprio formulário Rails.

Não introduzir:

- React.
- Vue.
- Angular.
- SPA.
- Node.js.
- TypeScript.
- Frameworks frontend adicionais.
- Bibliotecas JavaScript desnecessárias.

---

## 5. Rota de agendamento

Disponibilizar a página através da rota:

    GET /agendar

A criação do agendamento deverá utilizar uma
requisição POST.

Utilizar os mecanismos nativos de formulários Rails.

Preferir form_with e os helpers disponíveis no
framework.

A página deverá funcionar sem autenticação.

Neste momento, não implementar:

- Login.
- Sessões de usuários autenticados.
- Cadastro de usuários.
- Perfis.
- Permissões.
- Autorização.
- Links temporários.

A aplicação permanecerá restrita ao ambiente de
desenvolvimento até que os controles necessários
para produção sejam implementados.

---

## 6. Identidade visual

Utilizar a identidade visual da DSV.

Priorizar:

- Azul institucional.
- Azul escuro.
- Branco.
- Cinza claro.
- Bordas discretas.
- Sombras suaves.
- Tipografia legível.
- Aparência corporativa.

Utilizar como referência inicial:

    Azul institucional: #002664
    Fundo da página:    #F3F6FA
    Fundo dos cards:    #FFFFFF
    Texto principal:    #10243E
    Texto secundário:   #64748B
    Bordas:             #D5DFEC

Os valores são referências visuais e poderão ser
ajustados pelo Codex conforme o logo oficial e
o resultado do layout.

Não utilizar gradientes ou elementos decorativos
desnecessários.

---

## 7. Logo oficial

Utilizar exclusivamente o arquivo fornecido:

    DSV_Logo.svg

Armazenar o arquivo em:

    app/assets/images/DSV_Logo.svg

Utilizar o sistema de assets do Rails para carregar
a imagem.

Preferir o helper image_tag.

Preservar:

- Proporções originais.
- Cores originais.
- Formato original.
- Qualidade visual.

Não redesenhar o logo.

Não utilizar imagens externas como substituição.

Não carregar o logo através de uma URL externa.

Verificar se o SVG não contém scripts, referências
externas ou conteúdo ativo inesperado.

Não inserir o conteúdo do SVG diretamente no HTML
através de raw ou html_safe.

Caso exista conteúdo ativo inesperado, informar
o problema antes de utilizar o arquivo.

---

## 8. Estrutura geral da página

A página deverá possuir:

- Header.
- Apresentação.
- Formulário de agendamento.
- Footer.

Estrutura conceitual:

    +----------------------------------------+
    |               HEADER                   |
    | DSV | Doca Agenda                      |
    +----------------------------------------+
    |                                        |
    | Agendar coleta ou entrega              |
    |                                        |
    | +------------------------------------+ |
    | | 01 - Quem está agendando?          | |
    | |                                    | |
    | | Nome                               | |
    | | Empresa                            | |
    | | Tipo de operação                   | |
    | +------------------------------------+ |
    |                                        |
    | +------------------------------------+ |
    | | 02 - Nota fiscal e veículo         | |
    | |                                    | |
    | | Número da nota fiscal              | |
    | | Placa                              | |
    | | Modelo do veículo                  | |
    | +------------------------------------+ |
    |                                        |
    | +------------------------------------+ |
    | | 03 - Quando e em qual doca?        | |
    | |                                    | |
    | | Data                               | |
    | | Doca                               | |
    | | Janela de horário                  | |
    | +------------------------------------+ |
    |                                        |
    |       Confirmar agendamento           |
    |                                        |
    +----------------------------------------+
    |               FOOTER                   |
    +----------------------------------------+

Utilizar um único formulário para a confirmação
do agendamento.

Não criar um wizard com múltiplas páginas.

As três etapas deverão representar seções visuais
de um mesmo formulário.

---

## 9. Header

Criar um cabeçalho simples e responsivo.

Exibir:

    DSV | Doca Agenda
          COLETAS E ENTREGAS

Utilizar o logo oficial ao lado do nome da aplicação.

Características:

- Fundo branco.
- Alinhamento horizontal.
- Espaçamento adequado.
- Separador visual discreto.
- Altura compacta.
- Logo proporcional.

Não adicionar neste momento:

- Menu de navegação.
- Sidebar.
- Botão de login.
- Perfil de usuário.
- Menu administrativo.
- Notificações.

---

## 10. Apresentação da página

Exibir:

    RESERVE SEU HORÁRIO

    Agendar coleta ou entrega

    Agende para hoje ou para um dos próximos dois dias.

Utilizar uma hierarquia visual clara.

Não apresentar mensagens que afirmem que somente
o gestor possui acesso aos dados, pois o sistema
de autenticação e autorização ainda não existe.

Não prometer controles de segurança que ainda
não foram implementados.

---

## 11. Seção 01 — Quem está agendando?

Criar a primeira seção do formulário.

Título:

    01 — Quem está agendando?

Campos:

- Seu nome.
- Empresa / transportadora.
- Tipo de operação.

---

## 12. Campo nome

Label:

    Seu nome

Placeholder:

    Ex.: João Silva

Mapear para:

    bookings.contact_name

Regras:

- Obrigatório.
- Mínimo de 2 caracteres.
- Máximo de 80 caracteres.
- Remover espaços desnecessários nas extremidades.
- Aceitar caracteres acentuados.

Utilizar input do tipo text.

Não interpretar o conteúdo informado como HTML.

O campo representa o responsável pelo agendamento.

Não representa necessariamente o motorista.

---

## 13. Campo empresa / transportadora

Label:

    Empresa / transportadora

Placeholder:

    Nome da empresa

Mapear para:

    bookings.company

Regras:

- Obrigatório.
- Mínimo de 2 caracteres.
- Máximo de 100 caracteres.
- Remover espaços desnecessários nas extremidades.
- Aceitar caracteres acentuados.

Não criar uma tabela independente de transportadoras.

---

## 14. Tipo de operação

Label:

    Tipo de operação

Disponibilizar duas opções:

    Entrega
    Coleta

Valores persistidos:

    entrega
    coleta

Mapear para:

    bookings.operation

Apresentar as opções utilizando cards selecionáveis,
conforme as imagens de referência.

Estrutura conceitual:

    +---------------+  +---------------+
    |    Entrega    |  |    Coleta     |
    +---------------+  +---------------+

Utilizar radio buttons nativos do HTML.

Associar os respectivos labels aos inputs.

Permitir clicar em toda a área do card.

O estado selecionado deverá possuir:

- Fundo azul claro.
- Borda azul.
- Texto destacado.
- Indicador de seleção.

Preferir CSS utilizando os estados nativos
dos inputs para controlar a aparência.

Não utilizar JavaScript apenas para alterar
a cor de um radio button selecionado.

---

## 15. Seção 02 — Nota fiscal e veículo

Criar a segunda seção.

Título:

    02 — Nota fiscal e veículo

Campos:

- Número da nota fiscal.
- Placa do veículo.
- Modelo do veículo.

---

## 16. Número da nota fiscal

Label:

    Número da nota fiscal

Placeholder:

    Ex.: 000123456

Mapear para:

    bookings.invoice

Regras:

- Obrigatório.
- Aceitar somente dígitos de 0 a 9.
- Mínimo de 1 dígito.
- Máximo de 44 dígitos.
- Preservar zeros à esquerda.

Utilizar input do tipo text.

Configurar inputmode="numeric" para facilitar
o preenchimento em dispositivos móveis.

Não utilizar input do tipo number.

Não converter o valor para integer.

Realizar a validação obrigatoriamente no Rails.

Preservar a constraint existente no PostgreSQL.

Não implementar validação fiscal da NF-e.

Não implementar múltiplas notas fiscais.

---

## 17. Placa do veículo

Label:

    Placa do veículo

Placeholder:

    ABC1D23 ou ABC1234

Mapear para:

    bookings.plate

Aceitar os padrões brasileiros:

    ABC1234
    ABC1D23

Realizar a normalização no backend:

- Converter para maiúsculas.
- Remover espaços.
- Remover hífens.

Após a normalização, validar o formato.

Padrões aceitos:

- Três letras seguidas de quatro números.
- Três letras, um número, uma letra e dois números.

A placa deverá ser obrigatória.

Não implementar consultas externas de veículos.

Não depender de máscaras JavaScript para garantir
a validade da placa.

---

## 18. Modelo do veículo

Label:

    Modelo do veículo

Placeholder:

    Ex.: Mercedes-Benz Atego 1719

Mapear para:

    bookings.vehicle_model

Regras:

- Obrigatório.
- Mínimo de 2 caracteres.
- Máximo de 80 caracteres.
- Remover espaços desnecessários nas extremidades.

Utilizar input do tipo text.

Não criar um cadastro independente de veículos.

---

## 19. Seção 03 — Quando e em qual doca?

Criar a terceira seção.

Título:

    03 — Quando e em qual doca?

Componentes:

- Data do agendamento.
- Seleção da doca.
- Seleção da janela de horário.
- Aviso sobre horário operacional.

---

## 20. Seleção da data

Disponibilizar exclusivamente três datas:

- Hoje.
- Amanhã.
- Depois de amanhã.

As datas deverão ser calculadas pelo Rails utilizando:

    America/Sao_Paulo

Utilizar o relógio do servidor.

Não utilizar o relógio do navegador como referência
para definir as datas permitidas.

Exemplo visual:

    +----------+ +----------+ +-------------+
    | Hoje     | | Amanhã   | | Depois de   |
    | 25/11    | | 26/11    | | amanhã      |
    |          | |          | | 27/11       |
    +----------+ +----------+ +-------------+

Utilizar radio buttons e labels estilizados como cards.

Mapear para:

    bookings.booking_date

Não disponibilizar um calendário que permita
selecionar datas arbitrárias.

Não exibir um segundo campo apenas para repetir
a data selecionada.

Validar no backend que a data informada pertence
ao horizonte permitido.

Rejeitar:

- Datas anteriores ao dia atual.
- Datas posteriores a dois dias após o dia atual.
- Datas inválidas.
- Valores manipulados pelo navegador.

Não implementar regras de feriados ou fins de semana
neste requisito.

---

## 21. Docas físicas

A aplicação possui oito docas físicas fixas:

    01
    02
    03
    04
    05
    06
    07
    08

Não criar tabela de cadastro de docas.

Não criar migrations para docas.

Mapear a seleção para:

    bookings.dock_number

Os valores persistidos deverão ser numéricos:

    1 a 8

Apresentar os zeros à esquerda somente na interface.

Disponibilizar os números das docas através de
uma definição centralizada no Rails.

Não duplicar a lista de docas em:

- Controllers.
- Views.
- JavaScript.
- Arquivos CSS.

A distribuição definitiva das oito docas entre
recebimento e expedição ainda não foi definida.

Neste ambiente de desenvolvimento, disponibilizar
provisoriamente as oito docas para ambas as operações.

Documentar que esse comportamento é provisório.

Não considerar essa distribuição homologada
para produção.

Não utilizar a distribuição antiga de sete docas
presente no protótipo.

---

## 22. Layout da seleção de docas

Apresentar as docas como cards selecionáveis.

Exemplo:

    +------+ +------+ +------+ +------+
    |  01  | |  02  | |  03  | |  04  |
    +------+ +------+ +------+ +------+

    +------+ +------+ +------+ +------+
    |  05  | |  06  | |  07  | |  08  |
    +------+ +------+ +------+ +------+

Utilizar CSS Grid ou Flexbox.

Garantir adaptação para telas menores.

Cada card deverá possuir:

- Número da doca.
- Indicador de seleção.
- Estado selecionado.
- Área de toque adequada.

O card inteiro deverá ser clicável.

Utilizar radio buttons nativos do HTML.

Não implementar componentes personalizados
complexos para substituir o comportamento
nativo dos inputs.

---

## 23. Janelas de horários

Utilizar as dez janelas fixas:

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

Não criar tabela de cadastro de janelas.

Não criar migrations de horários.

Centralizar as definições no backend Rails.

Mapear a seleção para:

    bookings.slot_number

Persistir somente o número da janela:

    1 a 10

A última janela deverá possuir 48 minutos.

Não alterar seu encerramento para 18:00.

---

## 24. Layout das janelas

Apresentar os horários conforme as imagens
de referência.

Utilizar cards organizados preferencialmente
em duas colunas no mobile.

Exemplo:

    Horários disponíveis — Doca 01

    +------------------+ +------------------+
    | 08:00 - 09:00    | | 09:00 - 10:00    |
    | Janela 1         | | Janela 2         |
    +------------------+ +------------------+

    +------------------+ +------------------+
    | 10:00 - 11:00    | | 11:00 - 12:00    |
    | Janela 3         | | Janela 4         |
    +------------------+ +------------------+

A informação principal deverá ser o horário.

O número da janela será a informação secundária.

Garantir:

- Cards de tamanhos consistentes.
- Espaçamento adequado.
- Boa legibilidade.
- Área de toque confortável.
- Estado selecionado claramente visível.
- Estado indisponível claramente visível.

Em dispositivos muito estreitos, adaptar
a quantidade de colunas.

Não permitir scroll horizontal.

---

## 25. Disponibilidade

Ao selecionar uma data e uma doca, consultar
a disponibilidade das respectivas janelas.

Considerar os registros existentes em:

    bookings
    slot_blocks

Uma janela estará indisponível quando existir
uma reserva na combinação de:

- booking_date.
- dock_number.
- slot_number.

Com um dos seguintes estados:

    agendado
    em_operacao
    liberado

Reservas nos estados:

    cancelado
    reagendamento

não deverão consumir capacidade.

Também considerar os bloqueios existentes
na tabela slot_blocks.

Não implementar a interface administrativa de
bloqueios neste requisito.

---

## 26. Horários passados

Para agendamentos realizados no dia atual,
permitir somente janelas cujo horário inicial
seja estritamente posterior ao horário atual.

Exemplos:

    Horário atual: 10:00

    10:00 - 11:00: indisponível
    11:00 - 12:00: disponível, se livre

    Horário atual: 17:00

    17:00 - 17:48: indisponível

A validação deverá utilizar o relógio do servidor.

Não utilizar JavaScript como única proteção
contra agendamento em horário passado.

Revalidar a regra no momento da confirmação.

---

## 27. Atualização da disponibilidade

Priorizar recursos nativos do Rails.

A troca da data ou da doca deverá permitir
atualizar as janelas disponíveis.

Utilizar preferencialmente:

- Renderização no servidor.
- Partials ERB.
- Turbo Frames, caso já estejam disponíveis
  e sejam adequados à implementação.

Stimulus poderá ser utilizado exclusivamente
quando necessário para solicitar a atualização
ou controlar estados visuais.

Manter a solução simples.

Não criar uma API JSON independente apenas
para alimentar o formulário.

Não enviar dados pessoais do formulário em
parâmetros de URL.

Ao atualizar a disponibilidade:

- Preservar nome.
- Preservar empresa.
- Preservar nota fiscal.
- Preservar placa.
- Preservar modelo do veículo.
- Preservar a operação selecionada.
- Limpar uma janela selecionada quando ela
  deixar de ser válida.

Impedir que uma resposta antiga de disponibilidade
sobrescreva uma seleção mais recente.

Exibir uma mensagem clara em caso de falha.

Não apresentar dados desatualizados como
disponibilidade confirmada.

---

## 28. Estados visuais das janelas

Cada janela poderá apresentar:

### Disponível

- Fundo branco.
- Borda neutra.
- Texto legível.
- Seleção habilitada.

### Selecionada

- Fundo azul claro.
- Borda azul.
- Indicador de seleção.

### Indisponível

- Aparência desabilitada.
- Texto indicando indisponibilidade.
- Seleção desabilitada.

Não revelar ao participante:

- Nome de outra transportadora.
- Nome de outro responsável.
- Nota fiscal.
- Placa.
- Dados de outros agendamentos.
- Motivos internos dos bloqueios.

---

## 29. Aviso operacional

Exibir abaixo das janelas:

    Operação das 08:00 às 17:48.
    Na última janela, a entrada deve ocorrer
    antes das 17:30.

Utilizar um componente visual discreto.

Preferir fundo amarelo claro e texto com
contraste adequado.

O corte de check-in às 17:30 não deverá ser
confundido com o horário limite para realizar
um novo agendamento.

Não implementar check-in neste requisito.

---

## 30. Botão de confirmação

Disponibilizar o botão:

    Confirmar agendamento

No mobile, ocupar toda a largura disponível.

Utilizar:

- Azul institucional.
- Texto branco.
- Altura confortável.
- Bordas arredondadas discretas.
- Estado de foco visível.
- Feedback de envio.

Durante o processamento, impedir múltiplos
cliques acidentais quando possível.

Utilizar mecanismos nativos do Rails e Turbo
quando disponíveis.

O bloqueio visual do botão não substitui
a proteção de idempotência no backend.

---

## 31. Criação do agendamento

Ao confirmar o formulário, o Rails deverá:

1. Receber os parâmetros permitidos.
2. Normalizar os dados.
3. Validar os campos obrigatórios.
4. Validar o tipo de operação.
5. Validar a data selecionada.
6. Validar o número da doca.
7. Validar a janela.
8. Validar se o horário ainda é futuro.
9. Consultar novamente a disponibilidade.
10. Verificar a existência de bloqueios.
11. Gerar o protocolo.
12. Persistir o agendamento.
13. Registrar a auditoria de criação.
14. Confirmar o sucesso ao participante.

Executar as operações críticas de persistência
dentro de uma transação.

Não aceitar como confirmação apenas o fato de
a janela ter aparecido disponível na interface.

Persistir o estado inicial:

    agendado

Não permitir que o participante escolha o
status inicial.

Não receber valores de check-in ou liberação
através do formulário público.

---

## 32. Protocolo

Gerar o protocolo no servidor.

Utilizar um identificador aleatório com
entropia suficiente.

Exemplo de apresentação:

    DA-7F3A92B8C104

O formato apresentado é uma referência.

Garantir:

- Unicidade.
- Compatibilidade com a coluna existente.
- Independência do ID interno.
- Ausência de dados pessoais.
- Ausência de informações sensíveis.

Não utilizar IDs sequenciais como protocolo.

Preservar o índice único criado no RF002.

Tratar colisões de protocolo de forma segura.

O protocolo não deverá conceder acesso
aos dados privados de uma reserva.

---

## 33. Idempotência

Utilizar o atributo:

    request_id

Gerar um UUID para representar a tentativa
de criação do agendamento.

O identificador deverá permanecer consistente
durante as atualizações do formulário e
reenvios da mesma tentativa.

Utilizar mecanismos nativos do Ruby, como:

    SecureRandom.uuid

Preservar o índice único criado no RF002.

Comportamento esperado:

- Mesmo request_id e mesmos dados normalizados:
  não criar outra reserva.

- Mesmo request_id e dados incompatíveis:
  retornar conflito.

- Novo agendamento:
  utilizar um novo request_id.

Não utilizar somente o botão desabilitado
como proteção contra duplicidade.

Não armazenar informações sensíveis no
localStorage para controlar idempotência.

Tratar corretamente requisições concorrentes.

Não expor dados pessoais ou fiscais ao responder
uma tentativa de idempotência.

---

## 34. Concorrência

O banco de dados já possui um índice único
parcial para proteger a capacidade dos slots.

Preservar essa proteção.

Cenário:

    Participante A seleciona uma janela.
    Participante B seleciona a mesma janela.

    Ambos confirmam simultaneamente.

    Apenas um agendamento poderá ser criado.

Tratar a violação de unicidade do PostgreSQL
sem apresentar uma página de erro interno.

Retornar uma mensagem compreensível:

    Este horário acabou de ser reservado.
    Selecione outro horário disponível.

Preservar os demais dados preenchidos.

Atualizar a disponibilidade.

A transação que falhar deverá ser revertida
integralmente.

Não criar auditoria de sucesso para uma
reserva que não foi confirmada.

---

## 35. Integridade entre reservas e bloqueios

O RF002 não implementou a proteção concorrente
entre bookings e slot_blocks.

Neste requisito, utilizar uma estratégia
transacional compartilhada para proteger
as alterações de capacidade.

Uma opção é utilizar uma trava transacional
do PostgreSQL associada à combinação de:

- Data.
- Doca.
- Janela.

A estratégia adotada deverá:

- Ser determinística.
- Funcionar com conexões concorrentes.
- Ser utilizada durante a confirmação da reserva.
- Revalidar reservas e bloqueios após obter a trava.
- Ser documentada para utilização futura pelo
  serviço de bloqueios e reagendamentos.

Manter o índice único parcial existente.

Não introduzir Redis.

Não utilizar travas exclusivamente em memória.

Não utilizar mutex Ruby como única proteção.

Enquanto não existir o fluxo de bloqueios,
não declarar que a concorrência entre todos
os escritores da agenda está integralmente
protegida.

A proteção deverá ser reutilizada
obrigatoriamente pelos próximos RFs que
alterarem a capacidade.

---

## 36. Auditoria de criação

Utilizar a tabela audit_events criada no RF002.

Registrar um evento para cada agendamento
confirmado com sucesso.

Utilizar:

    entity_type: Booking
    entity_id: ID interno da reserva
    action: create

Registrar somente os atributos operacionais
necessários para rastreabilidade.

Não copiar indiscriminadamente todos os
atributos recebidos pelo formulário.

Não armazenar tokens ou credenciais.

Gravar a auditoria na mesma transação
da criação do agendamento.

A repetição idempotente de uma solicitação
não deverá criar outro evento de criação.

Não implementar identificação de usuários
ou operadores autenticados neste requisito.

---

## 37. Confirmação do agendamento

Após a criação bem-sucedida, apresentar
uma confirmação simples.

Exibir:

    Agendamento realizado com sucesso!

    Protocolo
    Tipo de operação
    Data
    Doca
    Horário

Exemplo:

    Agendamento realizado com sucesso!

    Protocolo: DA-7F3A92B8C104

    Operação: Entrega
    Data: 26/11/2026
    Doca: 03
    Horário: 10:00 às 11:00

Disponibilizar uma opção:

    Realizar novo agendamento

Utilizar o padrão Post/Redirect/Get ou
mecanismo equivalente para evitar reenvio
acidental ao atualizar a página.

Não disponibilizar uma rota pública que permita
consultar qualquer agendamento pelo ID interno.

Não utilizar o protocolo como credencial
de acesso a informações privadas.

Não implementar QR Code neste requisito.

Não enviar notificações por e-mail.

---

## 38. Mensagens de validação

Exibir mensagens em português do Brasil.

Exemplos:

    Informe seu nome.

    Informe a empresa ou transportadora.

    Informe uma nota fiscal válida.

    Informe uma placa válida.

    Selecione o tipo de operação.

    Selecione uma data.

    Selecione uma doca.

    Selecione um horário.

    Este horário não está mais disponível.

Apresentar mensagens próximas aos campos
correspondentes.

Utilizar também um resumo dos erros quando
apropriado.

Não exibir:

- Stack traces.
- SQL.
- Mensagens internas do PostgreSQL.
- Nomes de classes.
- Detalhes de exceções.
- Informações de infraestrutura.

Preservar os dados preenchidos quando
ocorrer um erro de validação.

---

## 39. Footer

Criar um rodapé simples.

Exibir:

    DSV · Doca Agenda

    Horário de Brasília

Não incluir:

- Links administrativos.
- Informações internas do servidor.
- Versões de dependências.
- Dados de infraestrutura.
- Mensagens permanentes de teste.

A indicação de ambiente de desenvolvimento,
quando necessária, deverá ser controlada
pelo ambiente Rails.

---

## 40. Responsividade

Utilizar a abordagem mobile-first.

A página será utilizada principalmente
através de smartphones.

Validar larguras de:

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
- Campos dentro da largura disponível.
- Cards sem sobreposição.
- Textos legíveis.
- Botões acessíveis.
- Espaçamento adequado.
- Navegação confortável no celular.

Em desktop, centralizar o formulário.

Utilizar como referência uma largura máxima
entre 760px e 900px.

O Codex poderá ajustar esses valores conforme
a qualidade visual do resultado.

---

## 41. Campos e acessibilidade

Utilizar:

- HTML semântico.
- Labels associados aos inputs.
- Fieldset e legend para grupos de opções.
- Radio buttons nativos.
- Estados de foco visíveis.
- Contraste adequado.
- Navegação por teclado.

Os campos de texto deverão possuir fonte
de pelo menos 16px em dispositivos móveis.

Priorizar áreas de interação de pelo menos
44px por 44px.

Não desabilitar o zoom do navegador.

Não depender exclusivamente de cores
para comunicar estados.

Respeitar prefers-reduced-motion.

---

## 42. Organização das views

Utilizar a estrutura padrão do Rails.

Organização sugerida:

    app/views/
    └── bookings/
        ├── new.html.erb
        ├── confirmation.html.erb
        ├── _form.html.erb
        ├── _contact_fields.html.erb
        ├── _vehicle_fields.html.erb
        ├── _schedule_fields.html.erb
        └── _availability.html.erb

A estrutura é uma sugestão.

Separar partials quando isso melhorar
a manutenção e a legibilidade.

Não criar dezenas de arquivos para
componentes extremamente simples.

Manter os controllers pequenos.

Não executar consultas ao banco diretamente
nas views.

Não concentrar todas as regras de negócio
no controller.

---

## 43. Organização do CSS

Utilizar o sistema de assets existente
na aplicação Rails.

Organizar os estilos de forma clara.

Criar classes reutilizáveis para:

- Formulários.
- Inputs.
- Labels.
- Cards.
- Seleções.
- Botões.
- Mensagens.
- Estados de erro.

Utilizar CSS Grid e Flexbox quando adequado.

Utilizar variáveis CSS para cores e
espaçamentos recorrentes.

Evitar:

- CSS inline.
- Estilos duplicados.
- Seletores excessivamente complexos.
- Uso indiscriminado de !important.
- Dependências externas.
- Frameworks CSS adicionais.
- Animações desnecessárias.

---

## 44. JavaScript

Utilizar o mínimo possível de JavaScript.

Antes de criar código JavaScript, verificar
se o comportamento pode ser implementado
utilizando HTML, CSS ou recursos nativos
do Rails.

Preferir:

    HTML
      |
      v
    CSS
      |
      v
    Rails / ERB
      |
      v
    Turbo
      |
      v
    Stimulus, quando necessário

Não utilizar JavaScript para:

- Definir regras de disponibilidade.
- Validar autorização.
- Controlar capacidade.
- Gerar o protocolo definitivo.
- Definir status operacionais.
- Garantir integridade dos dados.
- Substituir validações do Rails.

Não utilizar:

- eval
- new Function
- document.write
- innerHTML com dados externos
- outerHTML com dados externos
- insertAdjacentHTML com dados externos
- Handlers JavaScript inline.
- Scripts de CDNs.

Não desabilitar ou enfraquecer a CSP
para permitir o funcionamento da interface.

Não utilizar unsafe-eval.

Não adicionar unsafe-inline para scripts.

---

## 45. Segurança do formulário

Preservar todas as proteções do RF001.

Utilizar Strong Parameters com uma lista
explícita de atributos permitidos.

Permitir somente os campos necessários:

- contact_name
- company
- operation
- invoice
- plate
- vehicle_model
- booking_date
- dock_number
- slot_number
- request_id

Não permitir que o participante defina:

- id
- protocol
- status
- checkin_at
- released_at
- release_remark
- change_reason
- lock_version
- created_at
- updated_at

Esses atributos deverão ser controlados
pelo servidor.

Manter CSRF habilitado.

Não utilizar skip_forgery_protection
ou skip_before_action para contornar
problemas de implementação.

Utilizar escaping padrão do ERB.

Não utilizar raw ou html_safe para
exibir informações fornecidas pelo usuário.

Utilizar consultas parametrizadas.

Não concatenar parâmetros em SQL.

Não armazenar dados pessoais ou fiscais
no localStorage ou sessionStorage.

Não registrar o conteúdo completo do
formulário nos logs.

Revisar a filtragem de parâmetros sensíveis.

---

## 46. Testes automatizados

Utilizar Minitest e PostgreSQL.

Criar testes de model, integração e
concorrência conforme necessário.

### 46.1 Página

Validar:

- GET /agendar retorna HTTP 200.
- Formulário renderizado pelo Rails.
- Presença dos campos obrigatórios.
- Presença das opções de operação.
- Presença das oito docas.
- Presença das dez janelas.
- Utilização do logo local.

### 46.2 Criação

Validar:

- Agendamento válido.
- Persistência correta.
- Geração de protocolo.
- Estado inicial agendado.
- Criação da auditoria.
- Página de confirmação.

### 46.3 Campos

Validar:

- Nome obrigatório.
- Empresa obrigatória.
- NF obrigatória.
- NF exclusivamente numérica.
- Preservação de zeros à esquerda.
- Placa antiga.
- Placa Mercosul.
- Normalização da placa.
- Modelo obrigatório.
- Operação inválida.
- Doca inválida.
- Janela inválida.

### 46.4 Datas

Validar:

- Hoje.
- Amanhã.
- Depois de amanhã.
- Data anterior rejeitada.
- Data posterior ao horizonte rejeitada.
- Janela passada rejeitada.
- Janela no instante exato do início rejeitada.
- Última janela terminando às 17:48.
- Virada de dia no fuso America/Sao_Paulo.

Utilizar mecanismos de controle de tempo
nos testes.

### 46.5 Disponibilidade

Validar:

- Janela livre.
- Janela reservada.
- Janela bloqueada.
- Reserva cancelada.
- Reserva em reagendamento.
- Reserva liberada.
- Alteração de data.
- Alteração de doca.
- Preservação dos campos preenchidos.

### 46.6 Concorrência e idempotência

Validar:

- Duas solicitações simultâneas para
  a mesma data, doca e janela.

- Apenas uma reserva confirmada.

- Reenvio com o mesmo request_id.

- Reutilização do request_id com dados
  incompatíveis.

- Ausência de auditorias duplicadas.

- Rollback em caso de falha da auditoria.

Utilizar conexões independentes com
o PostgreSQL nos testes de concorrência.

### 46.7 Segurança

Testar:

- Tentativa de definir status pelo formulário.
- Tentativa de definir protocolo.
- Tentativa de registrar check-in.
- Manipulação de data.
- Manipulação de doca.
- Manipulação de janela.
- Entrada contendo tags HTML.
- Tentativa de XSS armazenado.
- Tentativa de SQL Injection.
- Requisição sem token CSRF, em contexto
  de teste com a proteção habilitada.
- Ausência de dados de terceiros nas
  respostas de disponibilidade.
- Preservação da Content Security Policy.

Não declarar um teste de CSRF aprovado
se a proteção estiver desabilitada
no ambiente utilizado.

### 46.8 Regressão

Executar todos os testes existentes
do RF001 e RF002.

Não remover ou enfraquecer testes anteriores
para permitir a aprovação deste requisito.

---

## 47. Validação visual

Realizar testes no navegador utilizando
o ambiente de desenvolvimento.

Validar:

- Desktop.
- Mobile.
- Tablet.
- Formulário vazio.
- Formulário parcialmente preenchido.
- Formulário completo.
- Cards selecionados.
- Janelas indisponíveis.
- Mensagens de erro.
- Conflitos.
- Confirmação do agendamento.

Verificar o console do navegador.

Não deverão existir:

- Erros JavaScript.
- Violações inesperadas de CSP.
- Recursos não encontrados.
- Erros de carregamento de assets.
- Erros de renderização.
- Scroll horizontal.

Caso alguma validação visual não possa
ser executada, informar na entrega.

---

## 48. Documentação

Registrar as decisões em uma ADR objetiva em `docs/adr/`, conforme a ADR 0005.
Não criar relatório paralelo em `docs/requisitos/RF003.md`.

Atualizar:

- Índice de requisitos.
- README.md.
- Documentação do banco, quando necessário.

Documentar:

- Rota do formulário.
- Estrutura MVC implementada.
- Definição fixa de docas.
- Definição fixa de janelas.
- Regras de disponibilidade.
- Estratégia de idempotência.
- Estratégia de concorrência.
- Utilização do logo.
- Pendências operacionais.

Registrar uma ADR caso seja necessária
uma nova decisão arquitetural.

Não criar ADRs para decisões triviais.

---

## 49. Critérios de aceite

### Interface

- [ ] Rota /agendar funcional.
- [ ] Logo DSV oficial utilizado.
- [ ] Header implementado.
- [ ] Footer implementado.
- [ ] Identidade visual preservada.
- [ ] Layout baseado nas referências fornecidas.
- [ ] Formulário dividido em três seções.
- [ ] Layout responsivo.
- [ ] Sem scroll horizontal.
- [ ] Cards selecionáveis.
- [ ] Estados visuais claros.
- [ ] Mensagens em português.
- [ ] Acessibilidade básica validada.

### Funcionalidades

- [ ] Nome do responsável.
- [ ] Empresa / transportadora.
- [ ] Tipo de operação.
- [ ] Número da NF.
- [ ] Placa do veículo.
- [ ] Modelo do veículo.
- [ ] Seleção entre três datas.
- [ ] Oito docas disponíveis conforme regra provisória.
- [ ] Dez janelas de horários.
- [ ] Última janela termina às 17:48.
- [ ] Disponibilidade consultada no PostgreSQL.
- [ ] Horários passados rejeitados.
- [ ] Janelas reservadas indisponíveis.
- [ ] Janelas bloqueadas indisponíveis.
- [ ] Dados preservados em caso de erro.

### Persistência

- [ ] Agendamento persistido no PostgreSQL.
- [ ] Protocolo gerado no servidor.
- [ ] Estado inicial agendado.
- [ ] Auditoria de criação registrada.
- [ ] Transação de criação validada.
- [ ] Idempotência implementada.
- [ ] Duplicidade de reserva impedida.
- [ ] Concorrência validada.
- [ ] Confirmação apresentada ao participante.

### Segurança

- [ ] Strong Parameters configurado.
- [ ] Proteção CSRF preservada.
- [ ] Content Security Policy preservada.
- [ ] Dados do usuário escapados corretamente.
- [ ] Regras críticas protegidas no backend.
- [ ] Atributos internos protegidos.
- [ ] Nenhuma exposição de dados de outras reservas.
- [ ] Nenhuma dependência frontend desnecessária.
- [ ] Nenhum erro JavaScript no console.
- [ ] Nenhuma vulnerabilidade alta ou crítica
      conhecida sem tratamento.

### Qualidade

- [ ] Testes automatizados executados.
- [ ] Testes de segurança executados.
- [ ] Testes de concorrência executados.
- [ ] Testes de idempotência executados.
- [ ] Testes de regressão aprovados.
- [ ] Brakeman executado.
- [ ] Bundler Audit executado.
- [ ] RuboCop executado.
- [ ] Documentação atualizada.

---

## 50. Fora do escopo

Não implementar neste requisito:

- Cadastro de usuários.
- Login.
- Logout.
- Autenticação.
- Autorização.
- Perfis.
- Permissões.
- Cadastro de docas.
- Cadastro de janelas.
- Cadastro de motoristas.
- Cadastro independente de veículos.
- Cadastro independente de transportadoras.
- Dashboard administrativo.
- Check-in.
- Liberação de veículos.
- Cancelamento.
- Reagendamento.
- No-show automático.
- Interface de bloqueio.
- Interface de desbloqueio.
- Consulta pública de agendamentos existentes.
- QR Code.
- Exportação Excel.
- Notificações por e-mail.
- Upload de documentos.
- Active Storage.
- Integração WhatsApp.
- Links temporários.
- Implantação na VPS.
- Configuração do Nginx.

Não antecipar funcionalidades dos próximos RFs.

---

## 51. Entrega

Registrar somente uma ADR objetiva e responder brevemente com mudanças,
testes e impedimentos reais, conforme a ADR 0005 e a orientação do usuário.
Não criar relatório, inventário ou cópia dos critérios de aceite.
Não inventar resultados nem declarar validações não executadas.

---

## 52. Regra de parada

Ao finalizar o RF003, PARE.

Não implementar o RF004.

Não implementar o dashboard.

Não implementar autenticação.

Não implementar funcionalidades administrativas.

Deixar o formulário operacional no ambiente
de desenvolvimento para homologação.

Aguardar novas instruções.