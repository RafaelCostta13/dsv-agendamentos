# Skill — Segurança da Aplicação

## Objetivo

Garantir que cada RF seja implementado sem depender do navegador como fronteira de segurança.

## Regras

- Autenticação e autorização devem ser verificadas no servidor.
- CSRF deve permanecer habilitado para sessões web.
- Nunca confiar em IDs, roles, datas, status ou flags enviados pelo cliente sem validação.
- Usar Strong Parameters.
- Não construir SQL com concatenação/interpolação de entrada do usuário.
- Não usar `eval`, `new Function`, `document.write` ou equivalentes.
- Evitar `innerHTML`; quando inevitável, nunca usá-lo com conteúdo não confiável.
- Não inserir dados de usuário como HTML não escapado.
- Cookies de sessão de produção devem usar configurações seguras compatíveis com HTTPS.
- Não expor stack traces, segredos ou detalhes internos em respostas de produção.
- Uploads devem validar tamanho, tipo permitido e autorização de acesso.
- Segredos devem ficar em credenciais Rails ou variáveis de ambiente.

## Revisão obrigatória

Antes de concluir um RF, verificar:

- autenticação;
- autorização;
- CSRF;
- XSS;
- SQL injection;
- mass assignment;
- exposição indevida de dados;
- concorrência;
- logs sensíveis;
- upload/path traversal quando aplicável.
