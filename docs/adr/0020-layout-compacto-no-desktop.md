# ADR 0020 — Layout compacto no desktop

## Status

Implementada a pedido do responsável; aguardando homologação visual.

## Contexto

O tamanho dos componentes no smartphone foi aprovado, mas o desktop exigia reduzir o zoom do navegador para acomodar o conteúdo confortavelmente.

## Decisão

Aplicar ajustes em `admin.css` e `bookings.css` exclusivamente em `@media screen and (min-width: 761px)`. Preservar as regras existentes até 760 px e as regras de impressão.

Compactar cabeçalho, navegação, indicadores, painéis, formulários, tabelas e seletores do painel administrativo; reduzir largura, espaçamentos, títulos e controles do formulário público e da autenticação.

Após a primeira homologação, o responsável solicitou aproximar a apresentação em zoom de 100% da captura de referência em 80%. A redução inicial de espaçamentos foi insuficiente. Converter as medidas dos dois estilos para `rem`, usando a equivalência de 16 px por rem, e definir `font-size: 80%` na raiz apenas na faixa de desktop. Assim, fontes e dimensões recebem uma redução adicional de 20%, inclusive os textos da matriz e das tabelas. Com a fonte padrão do navegador, o cabeçalho administrativo passa a 52,8 px, inputs administrativos a 28,8 px, células da agenda a 48 px de altura mínima e inputs públicos a 32 px. Os breakpoints permanecem em pixels, evitando deslocar a troca de layout.

Manter os estados visuais, os indicadores de foco e as bordas de 1 px. O CSS próprio do comprovante compartilhado e o tamanho explícito do QR Code não são alterados. A matriz e as listagens continuam com rolagem horizontal interna quando necessário. Não aplicar `zoom` nem `transform: scale`, nem alterar regras de negócio ou dependências.

## Consequências e validação

A apresentação de desktop fica mais densa no zoom padrão do navegador, mantendo os controles de toque existentes em smartphones. O limite de 760 px acompanha o breakpoint já utilizado pelo painel administrativo; o formulário público mantém seu comportamento anterior entre 600 e 760 px. A compactação também se aplica a tablets cuja largura de viewport ultrapasse 760 px.

Executados os testes de integração existentes de painel, agendamento público e autenticação: **30 testes, 469 assertions, sem falhas, erros ou skips**. Esses testes verificam os fluxos e a renderização HTML, sem comprovar a geometria visual. A suíte completa não foi executada; a homologação visual será realizada pelo responsável, conforme solicitado.

Na revisão de escala, os mesmos 30 testes foram executados novamente, sem falhas. Uma checagem automatizada pontual no Chrome, com exemplos dos componentes de painel, agendamento e autenticação, aprovou **252 verificações**: fontes, alturas mínimas e espaçamentos equivalentes a 80% em 761/1440 px; dimensões anteriores preservadas em 390/760 px. O parser Crass analisou os dois arquivos sem erros. Não foram produzidas screenshots nem executado roteiro manual de homologação.
