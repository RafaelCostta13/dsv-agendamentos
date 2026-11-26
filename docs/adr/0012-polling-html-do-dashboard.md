# ADR 0012 — Polling HTML do Dashboard

## Status

Implementada e validada por testes automatizados no RF009; aguardando homologação manual do responsável.

## Decisão

Adicionar GET `/admin/dashboard/refresh`, restrito a development/test como as demais rotas administrativas. A data é obrigatória e validada, incluindo consultas históricas e futuras sem limite de horizonte administrativo. A resposta HTML usa `Cache-Control: no-store`, o model existente `Admin::Dashboard` e o mesmo partial `content` da renderização inicial. Dados e horário de referência são calculados no servidor em America/Sao_Paulo. São mantidas as três consultas agrupadas existentes, sem consultas por célula e sem qualquer gravação ou execução de no-show no GET.

Turbo e Stimulus não estão instalados. Adotar um único controlador em JavaScript nativo, servido pelo Propshaft, evita novas dependências para este comportamento localizado. A região substituível contém os cinco indicadores e a matriz existente. Header, sidebar, seletor, controles e indicador de comunicação permanecem fora dela. Não há APIs JSON, WebSockets, mudanças de banco ou infraestrutura.

As configurações ficam centralizadas em `Admin::DashboardController`: intervalo de 5 segundos, timeout de 10 segundos e teto de retry de 30 segundos. A próxima solicitação é programada após a conclusão da anterior. Atualização manual reutiliza esse mecanismo; troca de data cancela e invalida a solicitação antiga. AbortController e identificação de geração impedem respostas obsoletas. Timeout também encerra a espera quando uma resposta não conclui seu corpo. Falhas preservam a região e o horário anteriores, com tentativas em 5/10/20/30 segundos; somente sucesso remove o alerta e restaura o intervalo normal.

A aba oculta cancela requisições e pausa o ciclo; retornar solicita atualização imediatamente. Saída da página e cache de navegação encerram timers/listeners. Eventos de navegação Turbo são tratados sem exigir a biblioteca, inclusive restauração de conteúdo pausado. Instâncias repetidas não duplicam o mecanismo. A substituição valida a estrutura do HTML, preserva scroll vertical/horizontal e foco quando possível e aguarda a conclusão de interação por ponteiro. Nenhuma regra operacional é calculada no cliente.

## CSP e segurança

A política anterior `script-src 'none'` inviabilizava qualquer atualização no navegador. Somente a resposta inicial do Dashboard autoriza seu asset por nonce aleatório de 32 bytes, renovado por resposta. Não há autorização genérica por origem, scripts inline, handlers inline, eval ou CDN. A política global continua `script-src 'none'`, inclusive no formulário público, detalhes, ações administrativas e endpoint de fragmento. As demais diretivas, CSRF, escaping e restrições de ambiente são preservados. A mudança específica complementa a decisão de ausência de JavaScript das ADRs anteriores para atender ao RF009.

O cliente recebe HTML renderizado pelo Rails da mesma origem e usa DOMParser/replaceWith, sem innerHTML com conteúdo externo. Fragmentos incompletos, de outra data, não HTML, redirecionamentos e falhas HTTP são rejeitados. Não há exposição adicional de dados cadastrais ou fiscais. A atualização consulta somente resultados do worker RF008, cuja frequência e funcionamento permanecem independentes.

## Validação

Suíte completa: **208 testes, 2.723 assertions, zero falhas, erros ou skips**. Inclui testes do endpoint com transições reais dos RF003–RF008, condições temporais, datas, falhas, ausência de gravações, escaping, CSP, ambiente e três consultas por atualização. Duas sessões independentes fizeram seis consultas sequenciais com datas distintas: 4,29–5,59 ms nesta amostra local. Isso não é teste de carga nem estimativa de capacidade máxima de operadores.

Testes de sistema adicionais: **2 testes, 13 assertions, sem falhas, erros ou skips**, executados em Chromium headless. Um teste exercita o Dashboard real servido pelo Rails, comprovando carregamento do asset autorizado por nonce e polling da data selecionada. Outro executa o asset real com respostas e relógio controlados em oito cenários: ciclo único, preservação de elementos/foco/scroll, troca rápida de data, respostas obsoletas, falhas e backoff, timeout, HTML inválido, visibilidade e ciclo de navegação/interação. Não foram feitos roteiros manuais ou screenshots.

RuboCop: sete arquivos alterados sem infrações. Brakeman: zero avisos. Nenhuma dependência da aplicação foi alterada; Bundler Audit não foi repetido. Chromium foi instalado somente no ambiente de teste, sem inclusão na imagem da aplicação ou Gemfile. O diretório permanece sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`).
