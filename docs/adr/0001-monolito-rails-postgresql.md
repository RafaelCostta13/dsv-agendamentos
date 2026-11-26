# ADR 0001 — Monólito Ruby on Rails com PostgreSQL

## Status

Aceita

## Contexto

A aplicação será reconstruída do zero para substituir o protótipo anterior, preservando as regras de negócio documentadas e adotando uma stack simples para operação em VPS própria.

## Decisão

Adotar:

- Ruby on Rails como aplicação web monolítica;
- PostgreSQL como banco de dados;
- ERB como renderização principal;
- Hotwire/Turbo/Stimulus quando necessário;
- Puma como servidor da aplicação.

Não adotar SPA ou microsserviços na arquitetura inicial.

## Consequências

### Positivas

- menor complexidade operacional;
- integração forte entre backend e frontend;
- menos lógica crítica no navegador;
- deploy simples em VPS;
- boa adequação às regras transacionais do agendamento.

### Trade-offs

- frontend menos desacoplado que uma SPA;
- futuras integrações externas devem respeitar o monólito como fonte principal das regras de negócio.
