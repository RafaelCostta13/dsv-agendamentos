# Backup e restauração PostgreSQL

Os comandos são procedimentos manuais na VPS e não foram executados neste RF. Backup contém dados pessoais e auditoria. Mantenha-o cifrado, fora do host, com acesso restrito. Guarde a chave em secret manager separado do arquivo e do host. Nunca grave dumps no repositório, em `public/` ou em caminho servido pelo Nginx.

## Criar backup

Use destino restrito, `umask 077` e GPG gerenciado pela operação:

```sh
umask 077
backup_dir="/mnt/secure-backups/dsv-agenda"
test -d "$backup_dir" && test -w "$backup_dir"
backup_file="$backup_dir/$(date -u +%Y%m%dT%H%M%SZ).dump.gpg"
docker compose --env-file .env.production -f compose.production.yaml exec -T db sh -c 'pg_dump --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --format=custom --no-owner --no-acl' | gpg --symmetric --cipher-algo AES256 --output "$backup_file"
chmod 600 "$backup_file"
gpg --decrypt "$backup_file" | docker compose --env-file .env.production -f compose.production.yaml exec -T db pg_restore --list - >/dev/null
```

GPG solicita a frase secreta pelo terminal; não a passe por argumento ou variável de shell. Envie uma cópia cifrada para storage externo protegido. Retenção inicial sugerida: 7 diários, 4 semanais e 3 mensais. Defina RPO/RTO com responsável. Antes de migrations relevantes, faça backup e registre apenas versão/commit e horário.

## Ensaiar restauração sem tocar na produção

Restaure somente em PostgreSQL isolado, sem porta publicada e com banco vazio exclusivo. Prepare papéis fictícios runtime/migration e crie a base de teste com owner migration. Descriptografe o dump em pipe, restaure como migration com `--no-owner --no-acl`, e aplique grants de runtime. Nunca use `pg_restore --clean`, `db:drop`, `db:reset` ou `down -v` em banco existente. Em VPS, use outro projeto Compose e volumes com nomes exclusivos; valide constraints, índices, trigger `audit_events_append_only`, contagens agregadas sem imprimir dados pessoais e healthchecks. Remova somente recursos descartáveis identificados por nomes exclusivos após confirmar que não guardam dados persistentes.

Se Active Storage vier a ser usado, coordene o volume de storage com o snapshot PostgreSQL para restaurar ambos no mesmo ponto. RF013 segue suspenso e este requisito não habilita uploads.
