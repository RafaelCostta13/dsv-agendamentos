# ADR 0008 — Check-in e liberação transacionais

## Status

Implementada e validada localmente no RF005; aguardando homologação.

## Contexto

A operação precisa registrar entrada e liberação sem permitir ocupação física simultânea, sobrescritas concorrentes ou auditoria parcial. O RF005 complementa o painel de consulta da ADR 0007 com as duas ações autorizadas.

## Decisão

Adicionar confirmações GET `/admin/bookings/:id/confirm_checkin` e `confirm_release` e comandos PATCH `/admin/bookings/:id/checkin` e `release`. Reutilizar o layout e os detalhes do painel, sem JavaScript ou alteração do formulário público. As rotas e o controller permanecem restritos a development/test. O header deixa de afirmar que o painel é somente de consulta.

`BookingCheckinPolicy` centraliza a elegibilidade utilizada na interface e na confirmação transacional: reserva agendada, data de São Paulo igual à atual, início da janela alcançado e instante anterior a 17:30. A doca precisa estar sem outra reserva em operação, inclusive de datas anteriores. Atraso além do fim da janela não impede entrada. Todos os horários efetivos vêm de `Time.current`.

`OperateBooking` adquire trava advisory transacional por doca física, no namespace existente `dsv-agenda:v1:physical-dock`, depois trava/recarrega a reserva. A ordem é doca → registro. Compara a versão recebida com `lock_version` e preserva o optimistic locking nativo no UPDATE. As regras e o relógio são reavaliados após as travas, com espera limitada a cinco segundos. O índice parcial `bookings_dock_occupation_unique` permanece a proteção definitiva inclusive contra escritores que ignorem a trava. Violações de unicidade, versões obsoletas e contenção retornam conflito compreensível, sem retry automático. Novos escritores de ocupação física deverão usar a mesma ordem; os locks de request/posição da criação pública permanecem inalterados.

Cada transição salva reserva e auditoria `checkin`/`release` na mesma transação, com status, horários, observação e versão anteriores/posteriores. Falha de auditoria reverte tudo. Repetições não produzem novo evento. Não há identificação de operador, usuários ou autenticação provisória.

A liberação exige estado em operação, versão atual, observação de 3 a 500 caracteres após remover whitespace das extremidades e horário não anterior ao check-in. Pode ocorrer após o expediente e em outra data. Mantém o check-in e a posição reservada; nenhuma transição deste RF muda o consumo de capacidade do slot, portanto não altera o protocolo de locks de posição da ADR 0006.

`Booking#operation_overdue?` compara data/hora final completa em `Time.zone` com o relógio do servidor. Lista, detalhes e matriz exibem atenção vermelha e texto de horário excedido, preservando o status em operação. O fim da última janela continua 17:48. Não há encerramento automático.

## Consequências e validação

Sem migrations, tabelas, índices duplicados ou novas dependências. Strong Parameters permite somente versão no check-in e versão/observação na liberação. CSRF, CSP e escaping são preservados; observações são filtradas dos logs. Em conflito a versão obsoleta não é substituída silenciosamente no formulário: o operador deve voltar aos detalhes atualizados.

Suíte PostgreSQL: 112 testes, 1.326 assertions, zero falhas, erros ou skips; 23 testes novos, incluindo quatro disputas com conexões independentes e bloqueio observado no PostgreSQL. Validaram-se limites de horário, virada do dia, versões obsoletas, rollback nas duas transições, repetições, XSS, parâmetros manipulados, CSRF habilitado e ausência das rotas em produção. RuboCop: 64 arquivos, sem infrações. Brakeman 8.1.1: zero avisos. Bundler Audit atualizado: nenhuma vulnerabilidade. Zeitwerk: carregamento válido.

O Chromium percorreu o fluxo completo com dois agendamentos fictícios pelo formulário público, em banco de teste e servidor temporário com relógio controlado por requisição: entrada do primeiro, recusa do segundo por doca ocupada, liberação, entrada do segundo e liberação às 18:15. Confirmaram-se seis eventos de auditoria (duas criações e quatro transições), os horários exatos e a manutenção da capacidade. Screenshots desktop/mobile estão em `tmp/rf005-screenshots/`. Sem erros de console, rede, CSP ou overflow da página. A referência ao favicon oficial foi adicionada ao layout público para eliminar o recurso ausente encontrado nessa verificação, sem alterar seu layout ou formulário. Os dados fictícios foram removidos somente do banco de teste; reservas de desenvolvimento foram preservadas. Nenhum relógio do sistema operacional foi alterado.

O ambiente atual continua sem metadados Git utilizáveis: `git status --short` retorna `fatal: not a git repository`. Não há pendência funcional identificada; aguarda-se homologação do usuário, sem avançar ao RF006.
