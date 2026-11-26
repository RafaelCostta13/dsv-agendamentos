# Produção — preparação e primeira implantação manual

Este roteiro destina-se ao responsável pela VPS Ubuntu informada no RF018. Não foi executado durante o desenvolvimento. Checkout previsto: `/opt/apps/dsv-agendamentos`; domínio `dsvbooking.tech`; IP informado `189.24.17.159`. DNS, firewall, Nginx, certificados e publicação continuam sob responsabilidade operacional.

## Arquitetura

`compose.production.yaml` usa projeto, rede e volumes próprios. Serviços permanentes: `db`, `web`, `worker`; `migrate` executa uma vez antes de web/worker, usa a mesma imagem e não tem restart permanente. `Dockerfile.production` usa build multi-stage, Ruby 3.4.13, Bundler 2.6.2, lockfile congelado, gems sem grupos development/test, assets compilados e UID/GID 10001. A imagem Rails instala `postgresql-client-17` (inclui `psql` e `pg_dump`), sem instalar o servidor PostgreSQL, e verifica os executáveis durante o build. Bundler grava estado de usuário em `/tmp/bundler`; o tmpfs `/tmp` de cada serviço é gravável pelo UID 10001. Web e worker usam filesystem read-only, tmpfs, `cap_drop: ALL`, `no-new-privileges` e nenhum bind mount do código. Não há socket Docker nem porta pública do banco. Puma escuta `0.0.0.0:3000` no container e somente `127.0.0.1:${HOST_RAILS_PORT}:3000` no host. A rede dos containers é interna. Logs usam driver Docker `local`, cinco arquivos de 10 MiB por serviço.

PostgreSQL `17.12-alpine` persiste em `dsv_agenda_production_postgres`; storage Rails em volume separado. Não reutilize nomes/volumes de desenvolvimento. Papéis distintos:

- `POSTGRES_ADMIN_USER`: somente no container `db`, inicialização/administração.
- `POSTGRES_MIGRATION_USER`: somente no serviço one-shot `migrate`, DDL e ownership dos objetos das migrations.
- `POSTGRES_APP_USER`: somente em `web`/`worker`; sem privilégios de administração, ownership, criação de banco/schema/roles, e sem UPDATE/DELETE/TRUNCATE em auditoria.

`SECRET_KEY_BASE` real vai somente para web/worker. Migrations não emitem sessões nem recebem essa chave; usam a chave dummy de build do Rails. Credenciais admin e runtime não são distribuídas ao serviço `migrate`.

`deploy/postgres/10-create-application-roles.sh` roda pelo entrypoint oficial **somente com volume vazio**, recebe segredos exclusivamente no container db, usa variáveis psql escapadas e configura default privileges. `production:grant_runtime` concede permissões por tabela depois das migrations. Alterar o script de init não atualiza roles de volume existente. Para banco existente, faça backup e prepare migração de ownership/grants revisada; não apague nem inicialize de novo o volume.

## Pré-requisitos

1. DNS A `dsvbooking.tech` aponta para `189.24.17.159`; se Cloudflare for usado, inicie com **DNS Only**. Não crie AAAA sem IPv6 confirmado.
2. SSH restrito, portas 80/443 conforme necessário, Nginx/Certbot ativos e renovação automática. Confira regras efetivas de Docker e host; não presuma que UFW bloqueie portas publicadas pelo Docker.
3. Confira espaço e se volumes com os nomes de produção já contêm dados a preservar. Nunca execute `down -v` ou `volume rm`.
4. Use checkout revisado. Se `git status --short` não estiver limpo, pare e resolva antes de atualizar.

## Preparar ambiente e banco

Na VPS:

```sh
cd /opt/apps/dsv-agendamentos
git status --short
git pull --ff-only
cp .env.production.example .env.production
chmod 600 .env.production
```

Edite `.env.production` com editor restrito e preencha os valores vazios por secret manager. Gere chave e senhas independentes, por exemplo com `openssl rand -hex 64`; não cole segredos em tickets, Git, argumentos de processo ou logs. Valores iniciais: `APP_HOST=dsvbooking.tech`, `RAILS_ENV=production`, `ADMIN_ACCESS_ENABLED=false`, usuários `dsv_agenda_admin`, `dsv_agenda_migrator`, `dsv_agenda_runtime`, banco `dsv_doca_agenda_production`, `RAILS_PORT=3000`, `HOST_RAILS_PORT=3000`, `RAILS_MAX_THREADS=3`, `PUMA_WORKERS=0`, `PUMA_WORKER_TIMEOUT=60`, `RAILS_LOG_LEVEL=info`. Use `IMAGE_TAG` com versão ou SHA do commit; não use `latest` mutável.

Mantenha `TRUSTED_PROXY_CIDRS` vazio para iniciar somente o banco. Este comando não inicia Rails:

```sh
docker compose --env-file .env.production -f compose.production.yaml up -d db
docker compose --env-file .env.production -f compose.production.yaml ps
docker network inspect dsv_agenda_production_internal --format '{{(index .IPAM.Config 0).Gateway}}'
```

Anote o gateway e coloque `TRUSTED_PROXY_CIDRS=<gateway>/32` em `.env.production`, o endereço exato do peer Docker esperado para o Nginx. Não use CIDR amplo. O Rails recusa iniciar em runtime se estiver vazio. O Nginx deve sobrescrever `X-Forwarded-For`, `X-Real-IP`, `X-Forwarded-Proto` e Host; não confie em headers enviados pelo cliente. Se outro proxy for adotado, valide e documente cada endereço antes de confiar nele.

Valide sem imprimir a configuração expandida:

```sh
docker compose --env-file .env.production -f compose.production.yaml config --quiet
```

Construa e inicie. Compose aguarda DB saudável e executa `migrate` antes dos processos permanentes:

```sh
docker compose --env-file .env.production -f compose.production.yaml build web
docker compose --env-file .env.production -f compose.production.yaml up -d web worker
docker compose --env-file .env.production -f compose.production.yaml ps
docker compose --env-file .env.production -f compose.production.yaml logs --tail=100 db migrate web worker
```

Migration com erro bloqueia web/worker. Não execute `db:drop`, `db:reset`, seeds de usuários ou recrie volumes para resolver falhas.

### Recuperação segura após falha em `db:structure:load`

Antes de repetir uma migration que falhou, preserve os logs e faça um backup consistente do banco. A ausência do executável `psql` faz o Rails abortar antes de iniciar a carga de `db/structure.sql`; nesse caso a carga não criou objetos. Se os logs não confirmarem essa causa, não presuma que o banco ficou intacto: consulte o catálogo PostgreSQL (tabelas, sequences e funções no schema `public`) e `schema_migrations` usando uma conexão de diagnóstico somente leitura. Compare os objetos com `db/structure.sql` e os registros de migrations esperados. Não remova objetos nem edite `schema_migrations` manualmente. Se houver carga parcial ou estado divergente, pare web/worker e peça revisão de DBA com backup antes de qualquer reparo não destrutivo. Depois de confirmar ausência de objetos parciais ou estado consistente, atualize a imagem e reexecute somente o serviço `migrate`:

```sh
docker compose --env-file .env.production -f compose.production.yaml build migrate
docker compose --env-file .env.production -f compose.production.yaml run --rm migrate
```

O segundo comando usa o volume existente; não execute `down -v`, `volume rm`, `db:reset` nem recrie usuários. Verifique exit code 0 e grants antes de iniciar/recriar web e worker.

## Verificação e primeiro administrador

Confirme DB saudável, `migrate` concluído com exit 0, web saudável e worker ativo. `/ready` consulta somente `SELECT 1`; `/up` e `/ready` não revelam dados internos e o template Nginx restringe esses caminhos ao loopback. Docker reinicia processo encerrado com `unless-stopped`, mas estado unhealthy sozinho não o reinicia; monitore logs/healthchecks.

Runtime valida seus privilégios ao inicializar e falha se for superuser, owner de DB/tabelas, puder criar no banco/schema, pertencer a roles privilegiados ou puder UPDATE/DELETE/TRUNCATE `audit_events`. Inspeção adicional pela aplicação, sem imprimir variáveis de ambiente:

```sh
docker compose --env-file .env.production -f compose.production.yaml exec -T web bin/rails runner 'c = ActiveRecord::Base.connection; abort "role privilegiado" if c.select_value("SELECT rolsuper OR rolcreatedb OR rolcreaterole OR rolbypassrls FROM pg_roles WHERE rolname = current_user"); abort "auditoria mutável" if c.select_value("SELECT has_table_privilege(current_user, '\''public.audit_events'\'', '\''UPDATE'\'') OR has_table_privilege(current_user, '\''public.audit_events'\'', '\''DELETE'\'') OR has_table_privilege(current_user, '\''public.audit_events'\'', '\''TRUNCATE'\'')"); puts "runtime PostgreSQL validado"'
```

Crie conta inicial somente em terminal interativo, após as verificações:

```sh
docker compose --env-file .env.production -f compose.production.yaml exec web bin/rails users:bootstrap_admin
```

A senha não tem eco, não há senha padrão e a troca é obrigatória. Mantenha painel indisponível (`ADMIN_ACCESS_ENABLED=false`) durante homologação. Só com autorização e validação de HTTPS, cookies, sessões, autorização e role runtime habilite `true` e recrie os processos Rails:

```sh
docker compose --env-file .env.production -f compose.production.yaml up -d --no-deps --force-recreate web worker
```

Essa opção apenas publica as rotas; não ignora autenticação/permissões.

## DNS, ACME e Nginx

Após DNS apontar, confira:

```sh
getent ahostsv4 dsvbooking.tech
curl -I http://dsvbooking.tech/
```

Instale primeiro `deploy/nginx/dsvbooking.tech-acme.conf.example` como vhost HTTP, valide com `sudo nginx -t` e faça reload. Ele serve somente `/.well-known/acme-challenge/` em `/var/www/html` e retorna 404 nos outros caminhos; não depende de certificado.

Depois de confirmar DNS A e acesso HTTP externo, emita o certificado (não executado pelo RF018):

```sh
sudo certbot certonly \
  --webroot \
  --webroot-path /var/www/html \
  -d dsvbooking.tech \
  --key-type ecdsa \
  --deploy-hook "nginx -t && systemctl reload nginx"
```

Verifique emissão e renovação:

```sh
sudo certbot certificates
sudo certbot renew --dry-run
sudo certbot renew --dry-run --run-deploy-hooks
```

Quando existirem `/etc/letsencrypt/live/dsvbooking.tech/fullchain.pem` e `privkey.pem`, substitua o vhost temporário por `deploy/nginx/dsvbooking.tech.conf.example`; revise com `sudo nginx -t` antes do reload. O template definitivo tem redirect fixo HTTPS, TLS 1.2/1.3, proxy para `127.0.0.1:3000`, body limit 64 KiB, timeouts, headers sobrescritos e bloqueio de dotfiles. Não há `www` nem redirect baseado em `$host`. Remova referências ao certificado temporário do IP somente após validar domínio e confirmar que outros vhosts não o usam.

O template não duplica cabeçalhos de segurança do Rails. `assume_ssl`/`force_ssl` do Rails geram HTTPS, cookie Secure e HSTS. Homologue `Location`, `Strict-Transport-Security`, `Set-Cookie` sem expor valores, CSP e Permissions-Policy. Com Cloudflare, comece DNS Only; se ativar posteriormente, use Full (strict), configure real_ip no Nginx com ranges oficiais vigentes e ajuste CIDRs confiáveis do Rails. Nunca use Flexible SSL.

Antes da publicação, valide firewall host/Docker (SSH restrito, 80/443; 3000/5432 não públicos), backup criptografado e restauração isolada, logs, worker, sessão/cookies e controles RF017. Nada aqui declara DNS, certificado, firewall ou deploy concluído.
