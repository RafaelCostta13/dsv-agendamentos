# ADR 0018 — Revisão de segurança e condições de publicação

## Estado e escopo

Revisão local do RF017 em 25/11/2026, sem implantação, acesso à VPS ou testes externos. RF013/RF014 continuam suspensos. Esta ADR concentra decisões, evidências sanitizadas, achados e condições para publicação, conforme AGENTS.md; não foi criado relatório paralelo RF017.md.

As decisões de empacotamento, execução de containers, roles do banco e proxy desta revisão eram do desenho de produção anterior. Foram simplificadas pela [ADR 0019](0019-preparacao-para-producao.md); os achados e controles funcionais de aplicação abaixo continuam válidos.

Referências consultadas: [Rails Security Guide](https://guides.rubyonrails.org/security.html), [OWASP ASVS 5.0](https://owasp.org/projects/asvs), [privilégios PostgreSQL](https://www.postgresql.org/docs/17/ddl-priv.html) e [segurança Docker](https://docs.docker.com/engine/security/). Controles ASVS relevantes orientam a avaliação, sem certificação de conformidade integral.

### Inventário observado

Em execução: Ruby 3.4.13, Rails 8.1.4.1, Puma 8.0.5, PostgreSQL 17.12, Docker Engine 29.9.2. Propshaft fornece CSS/JavaScript local; não há npm, importmap, framework SPA ou bibliotecas JavaScript de terceiros usadas pelo frontend. Dependências diretas incluem BCrypt 3.1.22, rqrcode 3.2.0 e caxlsx 4.5.0; Roo é de teste. Não foram atualizadas dependências.

No desenho revisto, monólito com web e worker compartilhando imagem; worker executa no-show a cada 60 segundos e limpeza técnica diária. PostgreSQL e storage persistem em volumes com nomes estáveis. Web publica apenas `127.0.0.1:3000`; PostgreSQL não publica porta no host. Produção usa a rede bridge padrão do Compose, usuário root padrão da imagem Rails, três serviços e migrations manuais; detalhes atuais estão na ADR 0019.

### Ameaças e fronteiras

Ativos: credenciais/digests, sessões, dados pessoais de contatos/usuários, placas, agenda, capacidade física, auditoria e exportações. Fronteiras: cliente→Rails, Rails→PostgreSQL, processo web→worker e futura cadeia proxy→Puma. Entradas são formulário público, login e rotas administrativas. Bots podem consumir CPU/slots; um viewer pode tentar mutações diretas; operadores podem tentar administrar usuários; administradores comprometidos mantêm grande impacto. Concorrência e revogação afetam integridade e rastreabilidade. XLSX e comprovantes são saídas controladas, mas cópias salvas por usuários ficam fora do controle da aplicação.

## Achados e tratamento

| ID | Severidade / categoria | Evidência e impacto | Tratamento / teste | Estado |
| --- | --- | --- | --- | --- |
| SEC-001 | Alta, CWE-367 | `AuthenticateUser#call` verificava senha; `SessionsController#create` emitia a sessão depois, fora da unidade crítica. Uma redefinição entre essas etapas permitia sessão baseada na senha antiga. | Verificação, emissão e auditoria executadas sob lock do usuário e transação; `AuthenticationConcurrencyTest` observa contenção real antes de rejeitar senha antiga após reset. | Corrigida |
| SEC-002 | Alta, CWE-863 / CWE-367 | Serviços revalidavam perfil sem verificar credencial revogada dentro da transação; gerenciamento de usuário não revalidava ator durante espera. | `AuthenticatedOperation` coordena trava global, usuário e sessão antes de mutações administrativas, exportação, senha própria e logout. Teste concorrente observa revogação confirmada antes da rejeição da operação aguardando. | Corrigida |
| SEC-003 | Média, CWE-346 | Uso direto de `remote_ip` aceitava cabeçalhos encaminhados sem assegurar que o peer era proxy autorizado; afetava rate limiting. | Rails confia em suas faixas privadas padrão, não em peers públicos. Nginx sobrescreve os cabeçalhos encaminhados; teste garante que X-Forwarded-For de peer público não altere o IP usado pelo limitador. Sem CIDR manual por deploy. | Corrigida; proxy de produção depende da configuração Nginx |
| SEC-004 | Média, CWE-770 | Área pública não tinha limitação de requisições. | Limites compartilhados PostgreSQL por IP/minuto: 180 leituras, 120 consultas de disponibilidade, 80 tentativas de criação. Limite de criação permite o volume nominal diário por IP sem confundir tentativa com reserva confirmada. Contadores têm retenção técnica existente. | Mitigada; bots distribuídos e preenchimento fraudulento ainda exigem homologação |
| SEC-005 | Média, CWE-400 | Corpos HTTP públicos não possuíam limite explícito da aplicação. | Middleware anterior ao parsing lê até 64 KiB + 1 e rejeita excesso com 413, inclusive sem Content-Length. Formulários não possuem upload. Teste de corpo acima do limite não cria sessão. | Corrigida |
| SEC-006 | Média, CWE-16 | Host Authorization de produção não configurado. | `APP_HOST` e `SECRET_KEY_BASE` obrigatório (mínimo 64 caracteres), host exato e falha segura ao iniciar sem configuração. Teste em processo real production rejeita host arbitrário e mantém administração indisponível por padrão. | Corrigida |
| SEC-007 | Média, CWE-862 | Algumas políticas usavam defaults por controller, autorizando ações futuras sem entrada explícita. | Lista explícita de ações; teste verifica negação de ações desconhecidas e cobertura de todas as rotas administrativas. | Corrigida |
| SEC-008 | Baixa, CWE-200 | Dropdown de operadores consultava também autores exclusivos de eventos restritos. | Consulta aplica o mesmo escopo de visibilidade dos eventos e limite de 500 opções. Teste confirma ausência de nome associado somente a evento restrito. | Corrigida |
| SEC-009 | Baixa, CWE-20 | Campos de senha ausentes/NUL/tipos inesperados e corte binário de user agent Unicode podiam causar exceções internas. | Validação antes do BCrypt, defaults para campos ausentes, corte por caracteres válidos e respostas genéricas de banco. Testes de request/model. | Corrigida |
| SEC-010 | Alta se publicado, CWE-250 | Consulta de `pg_roles` confirmou superuser/CREATEROLE/CREATEDB no usuário compartilhado de web/worker do Compose local. Pode desativar triggers/alterar auditoria. | A role da aplicação de produção será não-superuser, sem CREATEDB/CREATEROLE/BYPASSRLS; pode ser proprietária dos objetos e alterar o trigger de auditoria. Essa limitação é aceita na ADR 0019. Os atributos e owners do banco existente devem ser verificados antes de selecioná-la no `.env.production`. | Transição operacional pendente; risco de proprietário aceito |

Sem CVSS inventado. Total: 10 achados confirmados; 8 corrigidos e 2 mitigados. Por severidade: críticas 0; altas 3 (2 corrigidas, 1 mitigada com provisionamento pendente); médias 5 (4 corrigidas, 1 mitigada); baixas 2 (2 corrigidas). Alertas de ferramentas não foram contabilizados como vulnerabilidades confirmadas.

## Decisões de concorrência e disponibilidade

Login: trava de rate limiting→linha do usuário→emissão da sessão/auditoria, na mesma transação. Não adquire a trava global durante BCrypt; autenticações de contas diferentes não ficam serializadas globalmente.

Mutação autenticada: trava global de gerenciamento→linha do ator→sessão→travas de agenda existentes→linhas de negócio. Alteração de usuários/senha mantém a trava global, seguido de alvo e revogação. Logout usa a mesma coordenação. A revalidação ocorre antes das mudanças; operações já confirmadas não são desfeitas retroativamente. O custo de serializar mutações administrativas é aceito para o volume atual; carga concorrente de produção ainda precisa ser medida.

Os serviços operacionais existentes continuam utilizáveis internamente sem sessão em testes/console, mas os caminhos HTTP administrativos passam obrigatoriamente pela barreira central. Formulário público e worker não recebem ator administrativo automaticamente.

## Inventário de endpoints revisados

`bin/rails routes` foi executado. Grupos abaixo abrangem as rotas atuais, inclusive aliases `/` e `/admin`. A política enumera cada ação individualmente e os testes iteram as rotas Rails reais.

| Método / caminho | Controller#ações | Acesso, entradas e efeito |
| --- | --- | --- |
| GET /agendar | bookings#new | Público, data inicial no servidor, consulta disponibilidade e renova contexto do comprovante; limite de leitura |
| POST /agendar | bookings#create | Público, somente BookingRequest::FIELDS, seleção de data/intent; consulta ou criação transacional/idempotente; CSRF e limites distintos |
| GET /agendar/confirmacao[.png] | bookings#confirmation | Público somente no contexto legítimo da sessão, 30 minutos, sem lookup por protocolo/ID; HTML/PNG sem credenciais |
| GET/POST /login | sessions#new/create | Público; login somente email/password; CSRF no POST, limites de falhas por conta e tentativas por IP; nova sessão/auditoria |
| DELETE /logout | sessions#destroy | Sessão válida, inclusive restrita; CSRF, revogação individual; GET não aceito |
| GET /admin/profile | admin/profiles#show | Todos os perfis, própria conta, somente leitura |
| GET /admin/password/edit; PATCH /admin/password | passwords#edit/update | Sessão válida, inclusive troca obrigatória; current_password/password/password_confirmation; CSRF, troca/revogação/auditoria transacionais |
| GET /; /admin; /admin/dashboard/refresh | admin/dashboard#index/refresh | Todos os perfis; filtros de data; refresh não renova inatividade; sem mutação de negócio |
| GET /admin/bookings; /admin/bookings/:id | admin/bookings#index/show | Todos os perfis; filtros operacionais/paginação e ID; consulta dados operacionais |
| GET /admin/bookings/:id/receipt[.png] | admin/bookings#receipt | Todos os perfis; comprovante atual, sem acesso público enumerável |
| GET /admin/bookings/export.xlsx | admin/bookings#export | Todos os perfis; filtros whitelisted, até 20 mil, 26 colunas; evento por arquivo gerado |
| GET /admin/bookings/:id/confirm_checkin, confirm_release | admin/bookings#confirm_checkin/confirm_release | Admin/operator, leitura da confirmação |
| PATCH /admin/bookings/:id/checkin, release | admin/bookings#checkin/release | Admin/operator; lock_version e observação na liberação; CSRF, constraints/travas/auditoria |
| GET /admin/bookings/:id/edit, cancellation | admin/booking_changes#edit/cancellation | Admin/operator; somente apresentação |
| PATCH /admin/bookings/:id/reschedule, cancel | admin/booking_changes#reschedule/cancel | Admin/operator; formulário de posição/motivo/versão; CSRF, preview ou mutação revalidada |
| GET /admin/slot_blocks | admin/slot_blocks#index | Todos os perfis; filtros e paginação; viewer não recebe comandos de mutação |
| POST /admin/slot_blocks | admin/slot_blocks#create | Admin/operator; datas/docas/janelas/motivo; CSRF, preview ou lote atômico |
| GET /admin/slot_blocks/:id/unblocking | admin/slot_blocks#unblocking | Admin/operator, confirmação |
| POST /admin/slot_blocks/review_unblock, bulk_unblock; DELETE /admin/slot_blocks/:id | admin/slot_blocks#review_unblock/bulk_unblock/destroy | Admin/operator; tokens de seleção assinados e revalidados, máximo 80; CSRF, remoção/auditoria transacional |
| GET /admin/audit_events; /admin/audit_events/:id | admin/audit_events#index/show | Todos os perfis para operacional; User/security somente admin; filtros/período/protocolo/ator, paginação sem JSON bruto |
| GET /admin/users, new, :id, :id/edit | admin/users#index/new/show/edit | Admin; lista/consulta/formulários, campos limitados |
| POST /admin/users; PATCH/PUT /admin/users/:id | admin/users#create/update | Admin; nome/email/perfil fixo, estado/senha somente na criação; versão e confirmação de perfil; CSRF, auditoria/revogação |
| GET /admin/users/:id/activation, deactivation, password_reset | admin/users#activation/deactivation/password_reset | Admin; apresentação, sem alterar usuário |
| PATCH /admin/users/:id/activate, deactivate, password_reset | admin/users#activate/deactivate/reset_password | Admin; versão, motivo quando exigido, senha apenas reset; CSRF, último admin protegido, revogação/auditoria |
| GET /up; /ready | rails/health#show; readiness#show | Diagnósticos mínimos sem credenciais; restringir /ready na borda durante RF018 |

## Controles preservados e limites

Revisão de consultas: parâmetros vinculados, filtros/listas fixas, nenhuma entrada externa compondo SQL executável. Views preservam escaping; buscas de `html_safe`, `raw`, `eval`, `innerHTML`, desserialização insegura e execução de comandos não revelaram sinks de entrada de usuário na aplicação. DOMParser do polling recebe partial local, valida estrutura e rejeita scripts/objetos. QR é PNG Ruby, sem URL externa ou credencial. Não há integração HTTP externa controlada pelo participante, uploads, SMTP ou Power Automate.

CSRF continua habilitado; testes existentes exercitam operações públicas e administrativas com proteção ativa. BCrypt preserva política RF015 de 12 caracteres/72 bytes, Unicode e confirmação. Sessões de 256 bits têm apenas digest no banco, cookie criptografado HttpOnly/SameSite Lax e Secure em produção. No-store permanece nos dados administrativos/comprovantes. CSP mantém nonces somente onde necessários e sem unsafe-eval/unsafe-inline. CORS permissivo não foi identificado. `Permissions-Policy` nega câmera, microfone e geolocalização.

Auditoria append-only e índices parciais de capacidade/ocupação continuam protegidos no PostgreSQL. Privilégios superiores ainda podem remover a trigger; isso não é imutabilidade absoluta. XLSX usa strings explícitas/escape de fórmulas, sem links/fórmulas externas ou credenciais. O limite de 20 mil permanece e não foi ampliado.

Não há Git utilizável: `git status --short` retorna `fatal: not a git repository`. Portanto não foi possível verificar arquivos rastreados, remoções ou histórico de segredos. `.env` local existe e não foi reproduzido em evidências; `.gitignore`/`.dockerignore` excluem segredos, logs, temporários e agora dumps/backups comuns. Exemplo de produção contém somente nomes ilustrativos. Não foi executado scanner de segredos no histórico nem auditoria das camadas das imagens.

## Evidências e pendências de validação

Resultados finais (25/11/2026, horário de Brasília):

| Execução | Resultado | Limite da evidência |
| --- | --- | --- |
| `docker compose exec -T web bin/rails test` | 295 testes, 4.685 assertions, zero falhas/erros/skips | PostgreSQL de teste; inclui matriz de rotas e concorrência real |
| `docker compose exec -T web bin/rails test test/system` | 3 testes, 65 assertions, zero falhas/erros/skips | Chromium 156 temporário: polling autenticado real, lifecycle e layout do comprovante |
| `node --test test/javascript/authentication_test.cjs test/javascript/dashboard_security_test.cjs` | Dois arquivos de testes aprovados | DOM simulado para alternância de senha e interrupção 401/403; não substitui TLS/browser de produção |
| `docker compose exec -T web bin/rubocop` | 149 arquivos, sem infrações | RuboCop 1.93.0 |
| `docker compose exec -T web bin/brakeman --no-pager` | Brakeman 8.1.1: zero avisos/erros, antes e após as correções | Falhas de concorrência e autorização identificadas por inspeção não apareciam no scanner |
| `docker compose exec -T web bin/bundler-audit check --update` | Bundler Audit 0.9.3: nenhuma vulnerabilidade conhecida | Base ruby-advisory-db de 22/11/2026, commit c87703e7f2c64f8745ce032711308a17d10cda55 |
| Inicialização real production em subprocessos | Administração bloqueada por padrão; host arbitrário 403; ausência de APP_HOST impede boot; role privilegiado impede habilitar publicação | Sem servidor externo ou dado operacional de teste |
| `assets:precompile` sob production com segredo efêmero no processo | Assets compilados; resultado movido para `tmp/rf017-production-assets` | Somente teste de compilação; não implantação |
| `git status --short` | `fatal: not a git repository` | Histórico e rastreamento indisponíveis |

Após aplicar o Compose, web e banco ficaram saudáveis e o worker iniciou normalmente. Verificação HTTP local: `/login` 200, `/admin` 302 para autenticação, `/agendar` 200 e `/ready` 200. O processo Rails confirmou `CapEff=0` e `NoNewPrivs=1`. Não houve migration nova ou alteração de dependências neste RF.

A primeira tentativa de regressão encontrou dois erros por ausência de `zbarimg` após recriação do container; o pré-requisito de teste foi instalado temporariamente e a suíte completa passou. O teste de sistema antigo foi adaptado para obter cookie via login real; não foi desabilitada autenticação. Chromium e zbar não são dependências da aplicação e não entram na imagem.

Gitleaks, Trivy e OWASP ZAP não estavam instalados; sua ausência limita análise de histórico, pacotes de imagem e varredura dinâmica ampla. Testes de integração locais exercitam requisições Rack reais, e o processo production é inicializado separadamente. Não houve ataque contra sistemas externos.

Production local testado por Rack com indicador HTTPS; isso não é uma negociação TLS real. Cookies Secure sobre conexão TLS real, proxy/Nginx, HSTS definitivo e firewall ficam para RF018. Restauração de conteúdo via back-forward cache em navegadores e invalidação visual após logout requerem teste específico; `no-store` sozinho não é alegado como garantia de apagar conteúdo já exibido. Esse risco deve ser homologado antes da liberação operacional.

## Condições operacionais para RF018

1. Banco: usuário admin somente no serviço `db`; role da aplicação sem superuser, CREATEDB, CREATEROLE ou BYPASSRLS. A role pode ser proprietária de objetos; a capacidade de alterar o trigger de auditoria é um risco aceito e documentado na ADR 0019. Antes da transição no volume existente, confirmar owners e atributos e manter backup.
2. Rails: APP_HOST exato, SECRET_KEY_BASE gerado e gerenciado fora do repositório, senha real de banco por secret store, ambiente production e logs sem debug. ADMIN_ACCESS_ENABLED permanece false até homologação. A role de aplicação não recebe a credencial admin.
3. Docker/Puma: imagem sem bind mount do código/.env nem socket Docker e sem modo privileged. Publicar Puma somente loopback; PostgreSQL somente na rede privada Compose. O processo Rails usa o root padrão da imagem conforme decisão da ADR 0019.
4. Nginx no host: TLS válido e redirect HTTPS, body limit 64k, timeouts/limites complementares de requisição, rejeitar Host não autorizado e sobrescrever cabeçalhos encaminhados. Rails usa faixas privadas de proxy padrão. Evitar logs de query/cookies/Authorization. Desabilitar cache de login, /admin e comprovantes; restringir readiness.
5. Firewall: portas públicas 80/443 e SSH restrito; bloquear 3000/5432 e verificar regras efetivas Docker, sem presumir cobertura por UFW. Cloudflare opcional exige Full (strict), origem protegida, cache privado desabilitado e proxies confiáveis específicos; não substituir controles Rails por WAF.
6. Backup: pg_dump diário criptografado, retenção inicial sugerida de 7 diários/4 semanais/3 mensais, cópia externa protegida e segredos guardados separadamente. Ensaiar restauração em banco isolado antes da publicação e periodicamente; definir RPO/RTO com responsável. Nenhum backup real foi enviado ou restaurado nesta revisão.
7. Privacidade: contatos/empresa/placa/NF em PostgreSQL e exportações têm finalidade operacional; nomes/e-mails em contas/auditoria têm finalidade de acesso/rastreabilidade. Admin controla contas; perfis operacionais consultam agenda/exportam. Sessões têm retenção técnica de 30 dias após revogação/expiração; tentativas são digeridas e removidas após um dia. Definir retenção de dados operacionais, auditoria, cópias XLSX e logs com o responsável; não há expurgo automático desses dados nem declaração de conformidade LGPD.
8. Homologar ausência de MFA, senhas comuns não bloqueadas, bloqueio temporário por e-mail provocado por terceiros e abuso distribuído do formulário. CAPTCHA/Turnstile/MFA dependem de decisão posterior. Fazer carga limitada representativa de exportações e múltiplos Dashboards; esta revisão não estima capacidade máxima.
9. Antes da publicação: imagem escaneada, TLS/cookies reais, backup restaurado, testes de autorização e sessões com a role da aplicação, cache/voltar do navegador, healthchecks, no-show independente e logs sanitizados. A migração da role existente deve seguir o procedimento da ADR 0019; não avançar para acesso à VPS sem autorização.

## Parecer

**APROVADO COM RESSALVAS, somente para preparação da implantação.** As correções locais verificadas não autorizam publicação. A role da aplicação e seus owners ainda precisam ser confirmados na VPS; imagem, TLS/proxy, firewall, backup e cache de restauração do navegador não foram homologados. O bloqueio administrativo deve permanecer ativo. Não se declara aprovação definitiva de produção nem conformidade integral com ASVS/LGPD.
