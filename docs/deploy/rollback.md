# Atualização e rollback

Identifique imagem por versão ou commit e use o mesmo `IMAGE_TAG` para web, worker e migrations. Não sobrescreva tag publicada nem use `latest`. Registre o tag anterior antes da mudança.

## Atualização

Na VPS, inspecione a árvore e atualize somente checkout limpo:

```sh
cd /opt/apps/dsv-agendamentos
git status --short
git pull --ff-only
```

Atualize `IMAGE_TAG`, revise variáveis e faça backup conforme [backup-restore.md](backup-restore.md). Valide configuração, construa e atualize:

```sh
docker compose --env-file .env.production -f compose.production.yaml config --quiet
docker compose --env-file .env.production -f compose.production.yaml build web
docker compose --env-file .env.production -f compose.production.yaml up -d web worker
docker compose --env-file .env.production -f compose.production.yaml ps
docker compose --env-file .env.production -f compose.production.yaml logs --tail=100 migrate web worker
```

`migrate` precede web/worker. Valide `/ready`, `/agendar`, autenticação/autorização se habilitadas, worker e logs. Migration incompatível exige janela e plano próprios antes da publicação.

## Rollback

1. Registre o erro e interrompa a promoção da nova tag.
2. Se a aplicação ainda responder com segurança, retorne `IMAGE_TAG` à imagem anterior imutável e recrie web/worker. Se migration falhou, confira seu exit code antes de iniciar processos.
3. Valide healthchecks e fluxos afetados.
4. Se migration concluiu, não presuma que schema pode voltar. O código anterior só é compatível com mudanças backward-compatible; uma alteração destrutiva exige plano autorizado de restauração e manutenção.
5. Não remova volumes, rode `db:rollback` em massa, `db:reset` ou `docker system prune` como rollback automático.

```sh
docker compose --env-file .env.production -f compose.production.yaml ps
docker compose --env-file .env.production -f compose.production.yaml logs --tail=100 db migrate web worker
```

Não automatize rollback de banco nem exclusão de recursos persistentes. Registre a decisão operacional e valide integridade antes de retomar tráfego.
