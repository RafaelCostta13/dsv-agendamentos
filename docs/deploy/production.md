# Deploy de produção

Produção usa três serviços: `web` (Rails/Puma), `worker` e `db` (PostgreSQL 17.12). O Compose cria uma rede bridge privada padrão. Só `web` publica `127.0.0.1:${HOST_RAILS_PORT}:3000`; Nginx e Certbot continuam no host. O banco e o storage mantêm os volumes `dsv_agenda_production_postgres` e `dsv_agenda_production_storage`. Web/worker compartilham `dsv-agendamentos-production:local`. Rails usa o usuário da aplicação para requests, worker e migrations manuais; ele não é superuser nem pode criar bancos ou usuários. A auditoria mantém o trigger contra UPDATE/DELETE, mas o proprietário das tabelas pode alterá-lo; essa limitação é aceita.

## Atualização normal

No checkout da VPS, mantenha o `.env.production` existente e atualize somente os valores necessários. O arquivo deve conter `APP_HOST`, `SECRET_KEY_BASE`, `ADMIN_ACCESS_ENABLED`, parâmetros Rails, `POSTGRES_DB`, `POSTGRES_ADMIN_USER`/`POSTGRES_ADMIN_PASSWORD` e `POSTGRES_APP_USER`/`POSTGRES_APP_PASSWORD`. Não coloque a senha de admin nos containers Rails. Não há `IMAGE_TAG` nem configuração manual de CIDR do Docker.

```sh
cd /opt/apps/dsv-agendamentos
git pull --ff-only origin main
docker compose --env-file .env.production -f compose.production.yaml build
docker compose --env-file .env.production -f compose.production.yaml up -d db
docker compose --env-file .env.production -f compose.production.yaml run --rm web bin/rails db:migrate
docker compose --env-file .env.production -f compose.production.yaml up -d --remove-orphans
docker compose --env-file .env.production -f compose.production.yaml ps
docker compose --env-file .env.production -f compose.production.yaml logs --tail=100
```

Se `db:migrate` falhar, interrompa o deploy: não execute `up -d` para web/worker. Preserve logs e faça diagnóstico sem apagar tabelas ou migrations. `/up` verifica o processo e `/ready` verifica a conexão PostgreSQL. `docker compose ps` deve mostrar `db` saudável e web saudável; worker deve estar em execução.

## Transição do volume existente

O procedimento abaixo não foi executado na VPS. Preserve os volumes existentes; não use `down -v`, `volume rm`, `db:drop` ou `db:reset`. Antes de alterar o `.env.production`:

1. Faça e confira um backup conforme [backup e restauração](backup-restore.md).
2. Com a configuração antiga ainda ativa, consulte os proprietários e atributos de roles sem alterar o banco:

   ```sh
   docker compose --env-file .env.production -f compose.production.yaml exec -T db sh -c 'psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --no-psqlrc' <<'SQL'
   SELECT DISTINCT pg_get_userbyid(c.relowner) AS owner
   FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relkind IN ('r', 'S', 'v', 'm', 'f')
   ORDER BY 1;
   SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolbypassrls
   FROM pg_roles
   WHERE rolname IN ('dsv_agenda_migrator', 'dsv_agenda_runtime')
   ORDER BY 1;
   SQL
   ```

3. Só reutilize `dsv_agenda_migrator` como `POSTGRES_APP_USER` se a consulta confirmar que ele é proprietário de todos os objetos da aplicação e que não tem `rolsuper`, `rolcreatedb`, `rolcreaterole` ou `rolbypassrls`. Esse é o candidato esperado porque as migrations anteriores rodaram com essa role, mas a propriedade ainda precisa ser confirmada pelo responsável na VPS. Se o resultado diferir, pare: faça backup e prepare uma alteração de privilégios/ownership revisada antes de migrar. Não transfira ownership automaticamente.
4. Edite o `.env.production` no lugar: defina `POSTGRES_APP_USER=dsv_agenda_migrator` e `POSTGRES_APP_PASSWORD` com a senha já existente dessa role; mantenha as credenciais admin atuais. Remova somente as variáveis `POSTGRES_MIGRATION_*`, `IMAGE_TAG` e `TRUSTED_PROXY_CIDRS` que deixaram de ser usadas. Não copie o arquivo de exemplo sobre o arquivo de produção e não exclua roles antigas nesta etapa.
5. Siga a seção “Atualização normal”. O comando `up -d --remove-orphans` remove o container one-shot `migrate` antigo depois que a migration manual termina. Os nomes dos volumes não mudaram; o PostgreSQL não será reinicializado enquanto o volume existente for preservado.

Para uma instalação com volume vazio, o entrypoint do PostgreSQL cria a role da aplicação por meio de `deploy/postgres/10-create-application-roles.sh`. Alterar esse script não modifica roles em um volume já inicializado.

Nginx deve sobrescrever `Host`, `X-Real-IP`, `X-Forwarded-For` e `X-Forwarded-Proto`, conforme o template existente. Rails usa suas faixas privadas de proxy padrão; não confia em endereços públicos arbitrários. HTTPS, firewall, backup e acesso público continuam sendo responsabilidade operacional da VPS.
