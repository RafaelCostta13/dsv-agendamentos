# ADR 0013 — Comprovante temporário e QR Code

## Status

Implementada e validada por testes automatizados no RF010; aguardando homologação manual do responsável.

## Decisão

Reutilizar o Post/Redirect/Get de `/agendar` para `/agendar/confirmacao`. Substituir o snapshot operacional mantido em flash por um contexto na sessão Rails contendo somente ID interno e expiração absoluta de 30 minutos. O cookie de sessão é protegido pelos mecanismos nativos do Rails; não contém dados pessoais da reserva. A confirmação HTML e sua imagem PNG consultam novamente o registro no PostgreSQL, sem aceitar identificadores fornecidos na URL. Atualizar a página não renova o prazo. Iniciar outro formulário revoga o contexto anterior e gera novo request ID, sem criar uma reserva automaticamente.

GET `/agendar/confirmacao.png` depende da mesma sessão e expiração; não é um link público permanente nem uma consulta por protocolo. GET `/admin/bookings/:id/receipt`, com variante `.png`, reutiliza o componente e segue a restrição administrativa a development/test. Todas essas respostas têm `Cache-Control: no-store`; consultas não alteram reservas ou auditorias. Falhas de consulta são tratadas sem expor detalhes técnicos.

O partial compartilhado exibe protocolo, operação, data, doca, janela, empresa e placa persistidos. Não mostra nome do responsável, nota fiscal, request ID, versão, motivos ou histórico interno. Somente `agendado` apresenta confirmação e QR Code. Canceladas e em reagendamento mostram seu estado e informam que a posição anterior não representa reserva ativa. Em operação e liberadas permitem consulta sem sugerir nova entrada e sem QR. Alterações administrativas são refletidas ao consultar novamente, preservando protocolo e idempotência; capturas antigas não são atualizadas nem constituem autorização de acesso.

## Geração do QR Code

Adicionar [`rqrcode` 3.2.0](https://rubygems.org/gems/rqrcode/versions/3.2.0), biblioteca Ruby com licença MIT, Ruby mínimo 3.2 e release publicada em janeiro de 2026. É compatível com Ruby 3.4.13 do projeto. As únicas dependências transitivas adicionadas são `rqrcode_core` 2.1.0 e `chunky_png` 1.4.0, ambas MIT e Ruby puro. As versões das dependências anteriores foram comparadas ao lockfile original e permaneceram intactas. A [documentação oficial](https://github.com/whomwah/rqrcode/tree/v3.2.0) descreve os formatos e margens suportados.

`ReceiptQrCode` produz texto com destino DSV, sistema, protocolo, operação, data, doca, janela e fuso de Brasília. Não inclui empresa, placa, responsável, documentos, IDs, tokens ou URLs. Caracteres de controle no protocolo não podem injetar linhas adicionais. Gerar PNG evita incorporar SVG/HTML e dispensa mudanças de CSP. A imagem usa fundo branco, módulos pretos, correção M e margem de quatro módulos; a resolução de origem usa quatro pixels por módulo. A apresentação é quadrada, com 220 px, sem logo sobreposto. Não há arquivos permanentes, tabelas, migrations, serviços externos ou Active Storage.

O comprovante usa logo existente, orientações de captura e check-in e CSS de impressão que preserva dados/logo/QR e oculta navegação. A geração e visualização não realizam check-in, não liberam docas nem garantem disponibilidade física.

## Validação

Suíte completa: **217 testes, 2.885 assertions, zero falhas, erros ou skips**. Inclui nove testes novos para acesso por sessão, expiração exata sem renovação, tentativa de enumeração, consultas sem gravação, dados atuais após alteração/replay, estados, privacidade, escaping, CSP, formato e falhas de banco. `zbarimg`, instalado somente no ambiente de teste, decodificou efetivamente os PNGs a 180/220/240 px e o código da posição alterada; o resultado foi comparado ao texto esperado. Não é suficiente apenas detectar uma imagem.

Teste adicional em Chromium: **1 teste, 51 assertions**, aprovado nas larguras 320/375/390/414/430/768/1024/1440 px, com protocolo no limite de 50 caracteres e empresa extensa. Validou ausência de overflow, protocolo completo e imagem carregada, quadrada e entre 180–240 px. Os dois testes de navegador do polling RF009 também foram executados como regressão. Os utilitários de teste não integram a imagem da aplicação. Não foram realizados leitura com dispositivo físico, roteiro manual, screenshots ou impressão física; essa homologação é do responsável.

RuboCop nos nove arquivos Ruby alterados, Brakeman e Bundler Audit atualizado: sem infrações, avisos ou vulnerabilidades. Sem alterações nas regras de agenda, banco, polling ou worker. O diretório permanece sem metadados Git utilizáveis (`git status --short`: `fatal: not a git repository`).
