# ADR 0019 — Arquitetura simplificada de produção

## Estado

Adotada no repositório. Sem deploy nem acesso à VPS. A transição do banco existente depende da verificação operacional de ownership descrita em `docs/deploy/production.md`.

## Decisões

- Compose mantém apenas `web`, `worker` e `db`, na rede bridge privada padrão. PostgreSQL e worker não publicam portas; Puma publica somente loopback. Volumes PostgreSQL e storage mantêm os nomes existentes. Os serviços permanentes reiniciam automaticamente, têm healthchecks adequados e logs rotacionados.
- Web/worker compartilham a imagem local `dsv-agendamentos-production:local`. O Dockerfile continua multi-stage, mantém Ruby/Bundler/lockfile, assets e `postgresql-client-17` (`psql`/`pg_dump`), usando o usuário root padrão da imagem oficial Ruby. Não há modo privileged nem socket Docker.
- Migrations são uma ação manual e explícita: `docker compose ... run --rm web bin/rails db:migrate`. Não há serviço migrate nem migration automática no boot de web/worker.
- Há duas roles PostgreSQL: admin, entregue somente a `db`, e aplicação, usada por Rails, worker e migrations. A role de aplicação é criada sem superuser, criação de bancos/roles ou BYPASSRLS. A role pode ser proprietária de seus objetos; por isso, o trigger append-only de auditoria protege contra operações normais, mas não contra alteração pelo proprietário. Essa limitação foi aceita. Nenhuma role antiga é removida automaticamente.
- O volume existente é preservado. `dsv_agenda_migrator` é o candidato à role única porque executou as migrations; a propriedade real das tabelas e os atributos da role ainda devem ser confirmados pelo responsável na VPS. Se não forem compatíveis, interromper a transição e revisar ownership/privilégios com backup; não transferir objetos automaticamente.
- Rails usa as faixas privadas de proxy padrão. Nginx no host continua terminando TLS e deve sobrescrever Host e cabeçalhos X-Forwarded. Não é necessário descobrir/configurar CIDR do gateway em cada deploy.
- `.env.production` continua fora do Git e do contexto de build. A senha admin fica apenas no serviço db. A tag da imagem é local e estável; versão é rastreada pelo checkout Git.

## Validação e limites

Testes direcionados: 22 testes/193 assertions aprovados (Compose, boot production e IP/proxy); suíte completa: 307 testes/4.782 assertions, zero falhas e dois erros porque `zbarimg` não está instalado. RuboCop nos quatro arquivos Ruby alterados: sem infrações; Brakeman: zero avisos; configurações Compose de desenvolvimento e produção com ambiente sintético, script de inicialização (`sh -n`) e `git diff --check` passaram.

O build da imagem e a inicialização de uma stack isolada não foram possíveis: Docker negou acesso ao socket (`/var/run/docker.sock`). Portanto, disponibilidade real dos binários na imagem, migrations manuais, healthchecks e persistência não foram exercitados. Nenhum teste acessou VPS ou banco de produção. O owner e os atributos da role existente também permanecem sem confirmação; a transição deve começar pela consulta somente leitura e backup descritos em `docs/deploy/production.md`.
