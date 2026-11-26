# ADR 0015 — Exportação XLSX de agendamentos

## Status

Implementada e validada por testes automatizados no RF012; aguardando homologação manual do responsável no Excel/Power Query.

## Decisão

Adicionar **Exportar Excel** à listagem e GET `/admin/bookings/export.xlsx`, restrito a development/test. A consulta reutiliza `Admin::BookingFilters`, incluindo data, doca, operação e status. O período novo considera `booking_date`, com ambas as extremidades inclusivas, sem horizonte de três dias. Quando informado, tem prioridade sobre a data individual; isso evita restringir um período ao dia previamente selecionado. Datas inválidas e intervalos invertidos são rejeitados. Os filtros continuam na paginação e nos retornos aos detalhes.

`ExportBookingsXlsx` gera sincronicamente uma aba **Agendamentos**, com as 26 colunas A–Z na ordem do RF012, uma linha por reserva atual, cabeçalho azul, autofiltro, primeira linha congelada e larguras limitadas. Sem imagens, células mescladas, totais ou fórmulas. A consulta não utiliza auditoria e inclui todos os estados, inclusive canceladas e em reagendamento. Ordenação por data/janela/doca/ID; ID não é exportado. Paginação da tela não limita o arquivo.

Limite centralizado de 20.000 registros. Contar antes de gerar e carregar somente os atributos necessários, com limite defensivo de 20.001 e nova verificação antes de criar o arquivo. Crescimento concorrente acima do limite também rejeita a exportação; não há truncamento silencioso. O conjunto exportado reflete a consulta dos registros, não um snapshot histórico ou a mesma transação de uma consulta anterior da tela.

## Biblioteca, tipos e segurança

Adicionar [`caxlsx` 4.5.0](https://rubygems.org/gems/caxlsx/versions/4.5.0), MIT, publicada em junho de 2026, Ruby mínimo 2.6 e compatível com Ruby 3.4.13. Novas dependências de execução: `htmlentities` 4.4.2 e `rubyzip` 3.7.0; `marcel` e `nokogiri` já existiam. Para leitura independente dos arquivos nos testes, adicionar [`roo` 3.0.0](https://rubygems.org/gems/roo/versions/3.0.0), MIT, somente no grupo test, e sua dependência `csv` 3.3.7. Não há exportação CSV. As versões anteriores do lockfile foram verificadas e preservadas.

Todos os campos textuais possuem tipo string explícito e formatação de texto; `escape_formulas` é habilitado no workbook. Conteúdo com `=`, `+`, `-`, `@`, whitespace, DDE ou sintaxe HYPERLINK permanece literal, sem prefixos adicionados ou perda do conteúdo legítimo. Testes inspecionam a ausência de elementos de fórmula e links externos no ZIP/XML.

Datas são números seriais nativos do Excel com formato `dd/mm/yyyy`; horários são frações de dia com formato `hh:mm:ss`. Converter timestamps para America/Sao_Paulo antes da separação evita interpretar UTC como horário local. Doca e janela são números com apresentação `00`. Notas fiscais são texto, preservando zeros e até 44 dígitos. Valores ausentes permanecem vazios.

Calcular minutos no Ruby com duas casas: duração entre check-in/liberação válidos; atraso como máximo entre zero e check-in menos início agendado; excedido como máximo entre zero e liberação menos fim agendado. Usar instantes completos, inclusive após meia-noite e última janela às 17:48. Ausência de horário não vira zero e o horário atual não simula liberação. Esses indicadores não atribuem responsabilidade pelo atraso nem alteram regras operacionais.

O arquivo é montado em memória e enviado somente após geração completa, como attachment com MIME XLSX e `Cache-Control: no-store`. Não é streaming. Não há arquivo permanente, diretório público, job, migration ou nova tabela. Logs registram horário, quantidade, tempo, resultado e classe da falha, sem conteúdo das células. Erros devolvem HTML em português, preservando filtros quando aplicável, sem attachment parcial.

## Validação e desempenho observado

Suíte completa: **236 testes, 3.224 assertions, zero falhas, erros ou skips**. Oito testes novos abrem o XLSX com Roo e validam colunas, dados/tipos, notas de 44 dígitos, células vazias, métricas, estados, filtros, paginação independente, limites, erros e restrição de ambiente. ZIP/XML validam autofiltro, congelamento e ausência de fórmulas, hyperlinks e células mescladas. Foi gerado exemplo fictício em `tmp/rf012-example.xlsx`.

Benchmark reproduzível em `test/support/benchmark_booking_export.rb`, bloqueado fora de Rails test, com dados fictícios inseridos em transação e integralmente revertidos. Cada volume foi executado em processo novo, sequencialmente, sem alterar dados operacionais. Medidas do service; não incluem rede/download HTTP. “Demais etapas” inclui hidratação Active Record, preparação, geração e compactação, descontando o tempo SQL instrumentado. Pico RSS é do processo inteiro, incluindo Rails e preparação dos dados, não apenas a memória da planilha.

| Registros | SQL (ms) | Demais etapas (ms) | Total (ms) | RSS inicial (MiB) | Pico RSS (MiB) | Arquivo (bytes) |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | 1,98 | 63,84 | 65,82 | 89,82 | 90,23 | 17.079 |
| 1.000 | 4,27 | 276,75 | 281,02 | 99,88 | 102,11 | 114.447 |
| 5.000 | 14,13 | 1.350,48 | 1.364,60 | 106,80 | 143,07 | 548.046 |
| 10.000 | 35,10 | 2.817,36 | 2.852,46 | 101,99 | 188,62 | 1.090.195 |
| 20.000 | 54,41 | 5.715,43 | 5.769,84 | 107,52 | 289,14 | 2.172.874 |

Todos os cenários fizeram duas consultas SQL, sem N+1. O limite de 20 mil foi mantido conforme essa amostra local, com custo significativo de CPU/memória e ocupação síncrona de uma requisição. Não houve teste de carga concorrente ou estimativa de capacidade máxima; exportações simultâneas podem elevar consumo e latência. Uma evolução para volumes maiores exige avaliação e requisito próprio, sem filas neste RF.

RuboCop: nove arquivos sem infrações. Brakeman: zero avisos. Bundler Audit atualizado: nenhuma vulnerabilidade. Excel/Power Query e validação manual não foram executados; são da homologação do responsável. O diretório permanece sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`).
