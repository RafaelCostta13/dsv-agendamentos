# ADR 0003 — Active Storage para documentos

## Status

Aceita

## Contexto

A aplicação deverá receber documentos como PDFs e precisa preservar esses arquivos fora da camada descartável do container Rails.

## Decisão

Utilizar Active Storage.

Na fase inicial, os arquivos serão armazenados em volume persistente associado ao serviço Rails.

O diretório físico não será exposto diretamente pelo reverse proxy.

A implementação deve permanecer compatível com migração futura para um serviço de objetos compatível com S3.

## Consequências

- banco e storage precisam de estratégia de backup coordenada;
- recriar o container Rails não pode apagar documentos;
- regras de autorização e validação de uploads serão implementadas em RF específico.
