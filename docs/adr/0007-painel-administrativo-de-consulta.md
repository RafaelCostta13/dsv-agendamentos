# ADR 0007 — Painel administrativo de consulta

## Status

Implementado e validado localmente no RF004; aguardando homologação.

## Contexto

A operação precisa consultar reservas e capacidade sem introduzir autenticação provisória ou permitir alterações de estado.

## Decisão

A raiz `/` abre o Dashboard administrativo em development/test, por solicitação do usuário; nos demais ambientes preserva a página inicial pública. Disponibilizar somente GET `/admin`, `/admin/bookings` e `/admin/bookings/:id`, em namespace e layout ERB próprios. As rotas existem apenas em development/test, com defesa adicional no controller e respostas `no-store`. Reservas ausentes retornam 404 em português; falhas Active Record retornam 503 genérico, sem SQL ou detalhes de infraestrutura. O Compose continua publicando somente em loopback. Não há autenticação, ações operacionais, JavaScript, migrations ou seeds novos.

`Admin::Dashboard` carrega reservas que consomem capacidade e bloqueios da data em duas consultas, indexa por doca/janela e reutiliza os mesmos registros nos indicadores e nas 80 células. `BookingAvailability` aceita posições já carregadas e mantém a regra única de elegibilidade do RF003. Cancelados e reagendamentos aparecem na lista sem ocupar a matriz; liberados mantêm capacidade. Sobreposição de reserva ativa e bloqueio é sinalizada, sem correção automática ou contagem dupla da posição indisponível.

Filtros GET são validados em `Admin::BookingFilters` e aplicados por Active Record. A lista aceita consulta sem data, ordena por data/janela/doca/id e limita cada página a 25 registros. Contexto válido de filtros/data/página acompanha os links de detalhes e retorno. Dashboard aceita datas históricas e futuras; disponibilidade para nova criação respeita o horizonte público. Data inválida usa hoje com aviso no Dashboard; na lista retorna nenhum registro com aviso.

Puma foi atualizado de 8.0.2 para 8.0.5 para tratar os nove avisos da auditoria, e Brakeman de 8.0.5 para 8.1.1 para executar a checagem de versão vigente. Gemfile e lockfile permanecem fixados e a imagem é reconstruída; nenhuma nova gem foi adicionada.

## Consequências e validação

Layout público preservado; a interface administrativa tem header/sidebar compartilhados, matriz e tabelas com rolagem restrita ao próprio contêiner, filtros, legenda textual e detalhes sem comandos de alteração. Não pode ser publicada em produção antes de RF próprio de autenticação/autorização.

Suíte PostgreSQL: 89 testes, 1.030 assertions, sem falhas, erros ou skips. Os 17 testes novos cobrem filtros, paginação, estados, inconsistências, indicadores, consultas agrupadas, XSS/SQL injection, detalhes, datas, erros de consulta sem detalhes internos e ausência das rotas em produção. Brakeman 8.1.1: zero avisos; Bundler Audit com base atualizada: nenhuma vulnerabilidade. RuboCop: 59 arquivos, sem infrações. Imagem reconstruída com lockfile congelado e containers saudáveis. Chromium validou Dashboard, lista, detalhes e estado vazio em 1280×720, 1366×768, 1440×900, 1920×1080, 768×1024, 390×844 e 320×740, sem overflow da página, erros de console, falhas de recursos ou violações de CSP. Navegação nativa, filtros, limpeza e abertura de detalhes foram verificados; datas anteriores e fora do horizonte retornaram disponibilidade zero. Screenshots desktop/mobile estão em `tmp/rf004-screenshots/`, sem dados fictícios adicionados ao desenvolvimento. O navegador foi usado somente como ferramenta temporária no container, sem alteração do Dockerfile ou inclusão de dependência da aplicação.

O diretório atual não contém metadados Git utilizáveis; `git status --short` retorna `fatal: not a git repository`.
