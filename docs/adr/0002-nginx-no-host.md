# ADR 0002 — Nginx instalado no host da VPS

## Status

Aceita

## Contexto

A aplicação será executada em Docker, porém a VPS poderá hospedar outros serviços e precisa centralizar TLS, domínio e reverse proxy.

## Decisão

Em produção:

Internet -> Nginx instalado no Ubuntu -> Rails/Puma em Docker

O Nginx não fará parte do Docker Compose da aplicação.

O serviço Rails deve ser publicado apenas no loopback do host, por exemplo:

`127.0.0.1:3000:3000`

PostgreSQL não deve ser publicado para a Internet.

Em desenvolvimento, acessar Puma diretamente.

## Consequências

- certificados e domínios são administrados no host;
- o Compose fica restrito à aplicação e seus serviços internos;
- alterações de Nginx não exigem rebuild do container Rails.
