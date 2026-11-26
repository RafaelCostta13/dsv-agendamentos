# Preparação para implantação

O RF018 prepara arquivos e procedimentos, mas não acessa a VPS nem publica a aplicação. Desenvolvimento continua em `compose.yaml`; produção usa `compose.production.yaml` e `Dockerfile.production`. Nginx e Certbot permanecem no host.

- [Produção e primeira implantação](production.md): variáveis, papéis PostgreSQL, migrations, DNS, Certbot e Nginx.
- [Backup e restauração](backup-restore.md): cópia protegida e ensaio isolado.
- [Atualização e rollback](rollback.md): imagem por commit e compatibilidade do schema.

Não execute comandos destrutivos, `docker compose down -v`, alterações de firewall/DNS, Certbot ou SSH sem autorização operacional. Mantenha `ADMIN_ACCESS_ENABLED=false` até homologar os controles e as credenciais.
