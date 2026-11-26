# Atualização e rollback

Produção usa a versão do código presente no checkout local da VPS e a imagem estável `dsv-agendamentos-production:local`; o commit Git identifica a versão. Veja o fluxo normal e a execução manual de migrations em [production.md](production.md).

## Rollback da aplicação

1. Registre o erro e pare de promover a nova versão. Não reverta o banco automaticamente.
2. Confirme o commit anterior e que as migrations concluídas são compatíveis com o código anterior. Se não forem, interrompa e prepare plano próprio de recuperação com backup.
3. Faça checkout do commit anterior, reconstrua a imagem e recrie os serviços:

   ```sh
   git log -1 --oneline
   git switch --detach COMMIT_SHA_ANTERIOR
   docker compose --env-file .env.production -f compose.production.yaml build
   docker compose --env-file .env.production -f compose.production.yaml up -d --remove-orphans
   docker compose --env-file .env.production -f compose.production.yaml ps
   ```

4. Valide `/ready`, os logs, o formulário, a autenticação e o worker antes de retomar o tráfego. Depois, retorne ao branch de manutenção quando a correção estiver pronta.

Nunca remova volumes, rode `db:rollback` em massa, `db:reset` ou `docker system prune` como rollback automático. Restauração de banco é um procedimento separado, com backup e autorização operacional.
