# ADR 0006 — Formulário público e criação transacional

## Status

Implementada no código do RF003; homologação pendente.

## Contexto

O formulário precisa preservar dados, impedir reservas duplicadas e registrar auditoria, sem frontend independente ou consulta pública por ID.

## Decisão

Usar `/agendar` com ERB e um único formulário POST. O botão “Atualizar horários” consulta o servidor e preserva os campos e UUID, sem dados pessoais na URL e sem JavaScript. A consulta identifica data/doca e é revalidada ao confirmar; a CSP permanece inalterada. Os cartões de data agora são botões de consulta POST imediata, preservando os campos e o UUID, sem JavaScript. A navegação nativa serializa a atualização da página, sem respostas assíncronas antigas substituindo a seleção atual. O retorno renderiza o formulário porque a CSP bloqueia scripts; não há limpeza dos demais campos. Os botões de data e de atualização usam `formaction` com a âncora `#schedule`, mantendo a navegação na seção de agendamento em vez de retornar ao topo. A âncora posiciona a seção; não restaura a coordenada exata anterior de rolagem. Disponibilidade e confirmação compartilham `AgendaDefinition.future_slot?`, que compara o início completo da janela na data selecionada em `Time.zone` com `Time.current` e verifica o horizonte. O backend já comparava a data completa; o defeito era a consulta visual permanecer na data anterior após mudar apenas o rádio.

`BookingRequest` normaliza e valida a entrada pública sem alterar as regras estruturais dos registros históricos. `CreateBooking` gera protocolo aleatório de 96 bits, fixa status agendado e grava reserva/auditoria na mesma transação. O mesmo UUID e dados normalizados retornam a reserva existente; dados incompatíveis produzem conflito.

`AgendaCapacityLock` usa advisory locks transacionais PostgreSQL com chave SHA-256 determinística, namespace `dsv-agenda:v1`, para request e posição (data/doca/janela). A ordem é request → posição, com espera de lock limitada a cinco segundos. Consultar reservas e bloqueios somente após obter a trava; manter os índices únicos. Todos os próximos escritores de capacidade deverão usar a mesma trava de posição. Escritores que ignorem esse protocolo ainda não estão protegidos entre tabelas.

A confirmação usa redirect e flash de sessão com apenas protocolo/operação/data/doca/janela, sem rota de consulta por ID ou protocolo. A distribuição de docas definida para o formulário público é: entrega nas docas 1–3 e coleta nas docas 4–8. `AgendaDefinition` centraliza a lista; o formulário mostra a seleção correspondente à operação com CSS e `BookingRequest` aplica a mesma regra no backend. Reservas administrativas históricas não são alteradas.

## Consequências

Sem novas dependências ou migrations. Dados completos do formulário são filtrados dos logs. Seeds, autenticação, ações administrativas e demais fluxos permanecem fora do escopo.

As referências visuais foram encontradas diretamente em `docs/referencias`. O arquivo oficial `DSV_Logo.svg` foi fornecido e integrado ao cabeçalho via `image_tag`, com desenho, proporções e cores originais. Foram removidos conteúdo estranho após o fechamento do SVG e a declaração de DTD externo; o SVG resultante contém somente elementos gráficos locais, sem scripts ou referências externas. Validação da correção de data: suíte PostgreSQL com 72 testes e 824 assertions, sem falhas, erros ou skips, incluindo concorrência e oito testes novos de regressão. RuboCop sem infrações. Consulta HTTP com sessão e CSRF confirmou a alternância Hoje → Amanhã → Depois de amanhã → Hoje, preservando campos e CSP. A validação visual segue pendente: Chrome do Windows não iniciou pelo WSL (`UtilBindVsockAnyPort: socket failed`). A auditoria anterior encontrou nove avisos no Puma 8.0.2 e o Brakeman 8.0.5 exigiu atualização; dependências não foram alteradas nesta correção.
