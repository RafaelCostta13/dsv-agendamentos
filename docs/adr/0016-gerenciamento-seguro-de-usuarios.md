# ADR 0016 — Cadastro e gerenciamento de usuários

## Status

Implementada e validada por testes automatizados no RF015; aguardando homologação manual. Autenticação e autorização efetiva permanecem no RF016.

## Decisões

`users` armazena nome, e-mail normalizado, `password_digest` BCrypt, perfil (`admin`, `operator`, `viewer`), estado, troca obrigatória de senha, datas de alteração/desativação e `lock_version`. A migration adiciona unicidade case-insensitive de e-mail e checks de perfil, identidade, estado e versão. A migration é irreversível para preservar usuários e auditoria; `db/structure.sql` é o snapshot oficial.

Senhas são processadas por `has_secure_password` e BCrypt 3.1.22. A política exige 12 caracteres, até 72 bytes, confirmação e preserva espaços; não há senha padrão nem truncamento. O custo de produção permanece nativo do BCrypt. Logs e eventos não incluem senha ou digest.

`ManageUser` centraliza criação, edição, ativação, desativação e redefinição de senha. Cada mutação usa transação, advisory lock global de gerenciamento, lock de linha e validação otimista. A mesma trava serializa as operações que impedem remover ou desativar o último administrador ativo. Gravações SQL que ignorem a aplicação não recebem essa garantia. Nenhuma rota ou serviço exclui usuários.

Desativação e redefinição exigem motivo. Mudanças de perfil pedem confirmação separada; estados repetidos são no-op. A auditoria registra seis ações de usuário com snapshots em lista permitida e nunca inclui credenciais. A trigger append-only do RF011 continua vigente. O bootstrap `users:bootstrap_admin` exige TTY e entrada de senha sem eco, não aceita credenciais por argumento/arquivo/ambiente e recusa inicialização se já existir qualquer administrador, inclusive inativo. Nenhum administrador real foi criado durante a implementação.

A listagem oferece busca literal por nome/e-mail, filtros, 25 resultados por página e totais globais. Os perfis e descrições documentam escopo pretendido, mas não aplicam permissões. As rotas continuam limitadas a development/test; login, sessões, ator de auditoria, primeiro acesso e autorização efetiva pertencem ao RF016.

## Validação

Suíte completa: **256 testes, 3.527 assertions, zero falhas ou erros**. Os 20 testes novos cobrem modelo, serviços, integração e concorrência com conexões PostgreSQL independentes. Após ajuste para aceitar perfil somente da enumeração definida, testes de integração direcionados passaram; Brakeman terminou sem avisos. RuboCop e Bundler Audit também passaram sem infrações ou vulnerabilidades.
