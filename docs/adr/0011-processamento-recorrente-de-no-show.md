# ADR 0011 — Processamento recorrente de no-show

## Status

Implementada e validada por testes automatizados no RF008; aguardando homologação manual do responsável.

## Decisão

Habilitar Active Job, já distribuído com o Rails instalado, e executar `ProcessNoShowsJob.perform_now` em um processo auxiliar da mesma aplicação. `NoShowWorker` executa imediatamente ao iniciar e repete a cada 60 segundos, usando relógio monotônico para a espera. `bin/no-show-worker` trata SIGTERM/SIGINT e conclui a execução corrente antes de encerrar. O serviço `worker` do Compose usa a mesma imagem, código, usuário não root e configuração PostgreSQL de `web`, sem publicar portas, com `restart: unless-stopped`.

Não havia fila ou mecanismo recorrente instalado. Para uma única varredura periódica, adotar esse processo evita adicionar Solid Queue, tabelas técnicas e dependências apenas para persistir disparos descartáveis. Active Job organiza a execução; não há enfileiramento assíncrono nem um job por reserva. A fonte persistente das pendências é a própria tabela `bookings`: reiniciar o worker recupera todas as reservas ainda elegíveis, inclusive de dias anteriores, independentemente de disparos perdidos. A elegibilidade nunca depende de memória, GET, navegador ou acesso ao painel.

`AgendaDefinition` centraliza o limite de check-in às 17:30 em America/Sao_Paulo, reutilizado pelo RF005 e pelo no-show. `ProcessNoShows` consulta candidatos agendados, sem check-in, até a data limite e percorre lotes de 100. Cada reserva tem transação independente, com a ordem compartilhada request → doca física → posição → registro. Após recarregar sob trava, revalida posição, versão, request ID, estado e relógio. Mudança concorrente é ignorada nessa execução; a próxima varredura reavalia o estado persistido.

A transição altera somente status para `reagendamento` e motivo automático, além de timestamps/versão nativos. O evento `no_show`, originado pelo sistema sem operador fictício, registra os valores anteriores/posteriores na mesma transação. Falha de auditoria reverte a reserva e não impede as demais. Estado e travas impedem duplicidade; um novo reagendamento seguido de outro não comparecimento permite novo evento legítimo. O replay público também reconhece `no_show` como origem da posição em registros legados sem auditoria de criação.

Reservas agendadas com check-in preenchido são preservadas e sinalizadas tecnicamente. Logs contêm horário, job ID, contagens, IDs internos e classes de erro, sem mensagens de exceção que possam expor dados. Ciclos vazios ficam em debug, suprimido no worker. Falhas de banco fazem o job falhar; o worker registra a falha e aguarda o próximo ciclo, sem retry imediato. Falhas isoladas continuam elegíveis para outra execução.

## Interface e limites

Chegada atrasada é calculada após o fim da janela e antes do limite operacional, sem mudar o status. Check-in atrasado permanece possível conforme RF005. Operações excedidas continuam em operação até liberação manual. Matriz, lista e detalhes usam texto e destaque de atenção. O novo card de reagendamentos pendentes conta todas as datas e direciona à lista existente sem filtro de data. Os quatro indicadores anteriores mantêm seus cálculos; há somente uma consulta agregada adicional para a contagem geral, sem consultas por célula.

Sem migrations, novos estados, novas dependências, novas rotas, mudanças de disponibilidade, autenticação, polling ou alteração de CSP. Índices existentes de data/capacidade são reutilizados. A efetivação ocorre no próximo ciclo disponível após 17:30; a tela só reflete alterações ao consultar novamente. Para recarregar alterações do código do worker, reiniciar seu serviço.

## Validação

`docker compose exec -T web bin/rails test`: **202 testes, 2.528 assertions, zero falhas, erros ou skips**. Os 20 testes novos incluem limites de horário/fuso, estados protegidos, identidade, idempotência, nova ocorrência após reagendamento, rollback, disponibilidade, consultas sem efeitos colaterais, pendências gerais e isolamento das portas do worker. Seis testes de concorrência exercitam oito disputas reais com conexões PostgreSQL independentes: tarefas duplicadas, check-in nas duas ordens, cancelamento e alteração nas duas ordens e reagendamento. Testes executam o job no ciclo configurado com tempo/espera controlados e iniciam/reiniciam o entrypoint real em subprocessos contra o banco de teste, sem HTTP, validando recuperação e encerramento por SIGTERM.

RuboCop: 19 arquivos alterados sem infrações. Brakeman: zero avisos. Compose validado, com porta 3000 publicada somente pelo web. Dependências não foram alteradas; Bundler Audit não foi repetido. Conforme AGENTS.md, a validação manual é do responsável; não foram executados navegador ou screenshots. O diretório permanece sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`).
