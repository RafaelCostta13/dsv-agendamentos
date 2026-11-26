# ADR 0019 — Preparação para produção

## Estado

Preparado com ressalvas no repositório local. Nenhum acesso à VPS, DNS, firewall, Cloudflare, Certbot, Nginx ativo ou deploy foi realizado. A publicação permanece dependente de validação local da stack PostgreSQL e homologação operacional.

## Decisões

- Preservar `compose.yaml` e Dockerfile de desenvolvimento. Produção tem `compose.production.yaml`, projeto/rede/volumes próprios e `Dockerfile.production` multi-stage com imagem oficial Ruby 3.4.13 pinada por digest, Bundler 2.6.2, lockfile congelado, assets compilados sem segredo real e runtime UID/GID 10001. Pacotes de sistema são resolvidos dos repositórios Debian no build, portanto a imagem não é declarada bit-a-bit reproduzível.
- `db`, `web`, `worker` e `migrate` compartilham rede interna. Nenhuma porta do banco é publicada; Puma publica somente loopback. Web/worker usam filesystem read-only, tmpfs, `cap_drop: ALL`, `no-new-privileges`, logs Docker rotacionados e restart `unless-stopped`. `migrate` roda uma vez, sem restart, antes de web/worker.
- Segregar papéis e segredos PostgreSQL: administrador somente no serviço db; migration somente na etapa DDL; runtime somente web/worker. O init do banco cria roles apenas em volume vazio; para cluster existente são necessários backup e procedimento não destrutivo revisado, sem recriação automática. Migrations concedem DML explícito: `audit_events` apenas SELECT/INSERT; sem TRUNCATE/DDL para runtime. Default privileges limitados são aplicados a objetos futuros criados pelo papel de migration.
- Runtime valida no boot atributos do role, ownership de database/tabelas, CREATE em database/schema e privilégios de alteração da auditoria. O build usa `SECRET_KEY_BASE_DUMMY` e marca explicitamente seu processo como migration para compilar assets sem banco; runtime não recebe esse bypass. `TRUSTED_PROXY_CIDRS` é obrigatório para web/worker e deve ser o endereço exato do peer Nginx observado após criar a rede. Nginx sobrescreve forwarding headers e serve host fixo.
- `ADMIN_ACCESS_ENABLED=false` permanece padrão. Um administrador é criado apenas pelo comando interativo existente, sem seed ou senha padrão. O template Nginx não é instalado automaticamente; há etapa HTTP ACME separada antes do certificado definitivo.
- Procedimentos de implantação, backup/restauração, atualização e rollback ficam em `docs/deploy/`; dados do RF018 permanecem na especificação. Não criar cópia `docs/requisitos/RF018.md` nem relatório paralelo.

## Validação e limites

`docker compose config --quiet` passou para desenvolvimento e produção (esta usando env sintético). `docker compose ... build web` passou, incluindo Bundler frozen e compilação de CSS, JavaScript e logo Propshaft. Minitest focado: 13 testes/115 assertions aprovados. Suíte completa: 307 testes/4.778 assertions, zero falhas, dois erros porque `zbarimg` não está instalado no container; o scanner de QR não pôde executar. RuboCop: 151 arquivos sem infrações. Brakeman 8.1.1: zero avisos/erros. Bundler Audit: nenhuma vulnerabilidade na base de advisories de 22/11/2026. `sh -n` e `git diff --check` passaram. `git ls-files` não encontrou `.env`, chaves privadas, dumps ou backups.

A tentativa de `docker compose up` da stack isolada foi bloqueada com `permission denied` no socket Docker. Portanto inicialização PostgreSQL, criação real de roles, grants/migrations, healthchecks de containers, UID efetivo, restart, backup/restauração e persistência não foram exercitados. Trivy e Nginx não estão instalados; a imagem não foi escaneada e o template não passou por `nginx -t`. Não há evidência de DNS público, HTTPS real, firewall, backup/restauração ou VPS. Essas pendências impedem declarar pronta sem ressalvas.

O healthcheck web usa `/ready` e Host autorizado; worker não expõe porta nem healthcheck HTTP, e precisa ser acompanhado por estado/logs do processo. `unhealthy` não reinicia container. O volume de storage existe mesmo sem RF013. Configuração de recursos CPU/RAM fica em aberto porque a capacidade da VPS não foi medida. O domínio administrativo continua bloqueado até decisão/homologação. Resultado não equivale a deploy nem autorização de publicação.
