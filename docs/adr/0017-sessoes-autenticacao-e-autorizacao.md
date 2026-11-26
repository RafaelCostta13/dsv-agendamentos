# ADR 0017 — Sessões, autenticação e autorização

## Status

Implementada no RF016 e validada por testes automatizados; aguardando homologação manual. RF013 e RF014 continuam suspensos. A publicação em produção permanece bloqueada até RF017/RF018.

## Decisão

Manter o `User` e o BCrypt do RF015. A autenticação usa `has_secure_password`, mensagem genérica para credenciais inválidas e uma comparação BCrypt também para e-mail inexistente. Não há cadastro público, recuperação por e-mail, login externo, remember me ou credencial padrão.

Persistir sessões no PostgreSQL. O navegador recebe um token opaco aleatório de 256 bits em cookie criptografado, HttpOnly e SameSite Lax; somente SHA-256 do token é armazenado. Em produção o cookie é Secure. O backend revalida sessão, revogação, expiração, usuário ativo, perfil atual e troca obrigatória a cada requisição. O limite é 30 minutos de inatividade e 12 horas absolutas. Polling valida a sessão sem atualizar `last_seen_at`; HTTP 401 encerra o ciclo e encaminha ao login. Navegação explícita renova a atividade. Logout revoga somente a sessão atual.

`AuthorizationPolicy` mantém uma matriz fixa e negação por padrão. `Admin::BaseController` autentica e autoriza todas as rotas administrativas. Admin possui acesso total; operator pode operar agenda e bloqueios; viewer possui leitura operacional e exportação. Perfil, e-mail, desativação e redefinição administrativa revogam sessões do usuário. A troca da própria senha valida a senha atual, rejeita repetição, revoga todas as sessões, remove `must_change_password` e exige novo login.

O rate limiting usa PostgreSQL e advisory locks: cinco falhas por e-mail e trinta tentativas por IP em quinze minutos. Chaves são digeridas, expiram sem bloqueio permanente e registros técnicos antigos são removidos diariamente pelo worker. O limite por e-mail pode ser provocado por terceiros e causar bloqueio temporário; não substitui MFA, que permanece risco residual para avaliação antes da produção.

`audit_events` ganhou ator opcional com foreign key, nome/perfil históricos e origem. Operações autenticadas registram o ator obtido exclusivamente da sessão; formulário público, no-show e bootstrap usam origens próprias sem usuário fictício. Histórico antigo permanece com responsável não registrado e a trigger append-only continua ativa. Operadores/viewers não consultam eventos de usuários. Exportações registram um evento por arquivo gerado, com quantidade e filtros, sem conteúdo das linhas.

## Concorrência e segurança

Operações sensíveis revalidam o ator dentro da transação antes das travas de agenda. A ordem é usuário do ator, trava de requisição/doca/posição e registro de negócio. Gerenciamento de usuários usa a trava global do RF015, linha do usuário alvo, alteração, revogação e auditoria na mesma transação. Uma operação já confirmada não é desfeita retroativamente.

CSRF, CSP e escaping Rails foram preservados. Senhas, digests, tokens e cookies permanecem filtrados e fora da auditoria. Retorno após login aceita somente caminho interno iniciado por `/admin`. Respostas administrativas usam `no-store`. Em produção, rotas administrativas só existem com `ADMIN_ACCESS_ENABLED=true`; autenticação nunca é ignorada. HTTPS, `SECRET_KEY_BASE`, proxies confiáveis e Nginx precisam ser homologados antes da habilitação.

## Validação

A suíte completa terminou com **273 testes, 3.849 assertions, zero falhas, erros ou skips**. RuboCop inspecionou 141 arquivos sem infrações; Brakeman terminou sem avisos e Bundler Audit não encontrou vulnerabilidades. Os testes cobrem autenticação, cookies, expirações, revogação, primeiro acesso, matriz dos três perfis, acesso direto, CSRF, open redirect, polling, auditoria, limpeza e rate limiting concorrente com conexões PostgreSQL. A validação manual e screenshots não foram executados, conforme o processo do responsável.
