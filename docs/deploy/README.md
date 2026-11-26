# Preparação para implantação

O RF018 prepara arquivos e procedimentos, sem acesso à VPS ou publicação. Desenvolvimento continua em `compose.yaml`; produção usa `compose.production.yaml` e `Dockerfile.production`. Nginx e Certbot permanecem no host. A arquitetura atual tem apenas `web`, `worker` e `db`; migrations são manuais pelo web.

- [Deploy e transição do volume existente](production.md): três serviços, migration manual, variáveis e verificação do owner PostgreSQL.
- [Backup e restauração](backup-restore.md): cópia protegida e ensaio isolado.
- [Atualização e rollback](rollback.md): checkout Git e compatibilidade do schema.

Não execute comandos destrutivos, `docker compose down -v`, alterações de firewall/DNS, Certbot ou SSH sem autorização operacional. Mantenha `ADMIN_ACCESS_ENABLED=false` até homologar os controles e as credenciais.
