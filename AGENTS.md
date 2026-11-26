# AGENTS.md — DSV Doca Agenda

## 1. Objetivo deste arquivo

Este arquivo define as regras obrigatórias para agentes de código que atuarem neste repositório.

O projeto deve evoluir de forma incremental, requisito por requisito, com prioridade para segurança, clareza, testes e manutenção.

Nenhum agente deve tentar implementar funcionalidades futuras sem que exista um RF explícito autorizando a mudança.

## 2. Arquitetura oficial

A aplicação será um monólito Ruby on Rails.

Stack principal:

- Ruby on Rails
- PostgreSQL
- Puma
- HTML/ERB
- Hotwire/Turbo/Stimulus quando necessário
- Active Storage
- Docker / Docker Compose
- Nginx instalado diretamente na VPS em produção

Não usar Nginx dentro do Docker sem nova ADR aprovada.

Não introduzir React, Vue, SPA, microsserviços, Redis, Sidekiq ou outras dependências estruturais sem requisito ou ADR específica.

## 3. Desenvolvimento e produção

### Desenvolvimento

- Rails será servido pelo Puma.
- A aplicação poderá ser acessada diretamente em `localhost:3000`.
- PostgreSQL será executado em Docker.

### Produção

Fluxo oficial:

Internet -> Nginx no host -> Puma/Rails em Docker -> PostgreSQL em Docker

Regras:

- Nginx fica instalado no sistema operacional da VPS.
- Rails/Puma deve ficar acessível ao host somente via loopback.
- PostgreSQL não deve ser exposto publicamente.
- HTTPS será terminado no Nginx do host.

## 4. Segurança obrigatória

Nunca confiar no navegador para segurança ou integridade.

Regras críticas devem ser validadas no servidor e, quando aplicável, protegidas também por constraints, índices e transações no PostgreSQL.

Obrigatório:

- CSRF habilitado.
- Strong Parameters.
- escaping padrão das views Rails.
- não usar `html_safe` com conteúdo não confiável.
- não usar `raw` com conteúdo de usuário.
- não usar `eval`.
- não usar `innerHTML` com dados não confiáveis.
- não interpolar SQL manualmente com entrada do usuário.
- não armazenar senha ou segredo em texto puro.
- não versionar `.env`, credenciais reais ou `master.key`.
- não registrar tokens, senhas ou segredos em logs.
- uploads devem ser validados no backend.

JavaScript nunca deve ser a única camada que impede uma ação inválida.

## 5. JavaScript

Usar o mínimo necessário.

Preferência:

1. HTML/ERB server-side.
2. Turbo.
3. Stimulus para comportamento localizado.
4. JavaScript puro somente quando realmente necessário.

Evitar lógica extensa no cliente.

Não duplicar regras de negócio no frontend.

## 6. Banco de dados

PostgreSQL é a fonte persistente de verdade.

- Criar migrations novas; nunca editar migrations já aplicadas em ambientes compartilhados.
- Utilizar foreign keys.
- Utilizar índices quando necessários.
- Utilizar constraints para invariantes importantes.
- Operações concorrentes devem utilizar transações e proteção adequada no banco.
- Evitar N+1 queries.

## 7. Storage

Documentos serão tratados com Active Storage.

Na fase inicial:

- armazenamento local persistente em volume Docker;
- arquivos não devem ficar apenas na camada descartável do container;
- não expor diretamente o diretório de storage via Nginx.

A arquitetura deve permitir migração futura para serviço compatível com S3.

## 8. RFs

Cada RF define um escopo fechado.

Ao implementar um RF:

1. Ler este `AGENTS.md`.
2. Ler as skills aplicáveis em `.agents/skills/`.
3. Ler as ADRs relevantes.
4. Ler somente o RF solicitado e suas dependências.
5. Implementar apenas o escopo solicitado.
6. Executar testes.
7. Registrar as decisões em uma ADR objetiva e responder brevemente com mudanças, testes e impedimentos.
8. Não avançar automaticamente para outro RF.

O RF deve prevalecer sobre sugestões genéricas do agente, exceto quando houver conflito com segurança, integridade ou ADR já aprovada.

## 9. Testes

Mudanças de comportamento devem possuir testes proporcionais ao risco.

Priorizar:

- model tests;
- request/integration tests;
- system tests para fluxos críticos;
- testes de concorrência para invariantes de agenda quando introduzidos.

Não considerar uma funcionalidade concluída apenas porque a interface aparenta funcionar.

### Fluxo de validação proporcional

Por orientação do responsável pelo projeto, priorizar testes automatizados e entregas incrementais. A aplicação deve ser bem feita, com validação proporcional ao impacto de cada mudança, sem transformar toda entrega em uma homologação extensa.

A validação manual e a homologação são realizadas pelo responsável pelo projeto. O agente deve focar na implementação e nos testes automatizados necessários, com uso econômico de tokens: leituras direcionadas, saídas curtas e comunicação objetiva. Não duplicar a validação manual do responsável nem produzir evidências extras sem solicitação ou necessidade concreta de diagnóstico.

Toda alteração de código deve ser validada pela execução de testes automatizados antes da entrega. Mudanças de comportamento devem incluir ou atualizar os testes correspondentes; testes existentes podem ser reutilizados quando cobrirem adequadamente a alteração. A validação manual não substitui esses testes. Se não for possível executá-los, informar o impedimento e não considerar a alteração concluída. Alterações exclusivamente documentais dispensam testes da aplicação.

- Executar os testes automatizados relacionados à mudança. Para um RF que altere regras de negócio, executar também a suíte existente uma vez ao concluir.
- Após testes aprovados, repetir ou ampliar verificações somente quando houver nova alteração relevante, falha ou dúvida concreta ainda não resolvida.
- Não criar testes que apenas repitam a implementação nem acrescentar cenários redundantes sem benefício concreto.
- Validar concorrência quando a mudança introduzir ou alterar disputa por capacidade, transações ou travas; não repetir toda a matriz de concorrência em mudanças sem relação com essas regras.
- Não executar por padrão validação manual no navegador, screenshots, verificações em vários tamanhos de tela, servidores temporários ou roteiros extensos de QA. Usar esses recursos somente quando solicitados expressamente na tarefa atual ou necessários para investigar um problema que os testes automatizados não esclareçam.
- Executar ferramentas de qualidade conforme a mudança: lint nos arquivos de código alterados; análise de segurança quando houver impacto pertinente; auditoria de dependências quando estas forem alteradas ou houver uma suspeita concreta. Não repetir indiscriminadamente todas as ferramentas em cada ajuste.
- Checklists genéricos de validação manual ou ferramentas em RFs anteriores não tornam essas verificações obrigatórias para toda entrega. Esta orientação atual prevalece sobre esses checklists, preservando os critérios funcionais dos RFs e os controles de segurança e integridade.
- Informar brevemente o que foi testado e eventuais limitações reais. Não declarar verificações que não foram executadas.

## 10. Estilo de implementação

Preferir:

- soluções simples;
- Rails idiomático;
- nomes explícitos;
- métodos curtos;
- responsabilidades claras;
- código fácil de testar;
- serviços somente quando melhorarem realmente a organização.

Evitar abstrações antecipadas.

## 11. Documentação

Decisões arquiteturais relevantes devem ser registradas em `docs/adr/`.

Requisitos ficam em `docs/requisitos/`.

A especificação funcional de referência fica em `docs/referencias/`.

O registro de entrega deve limitar-se a uma ADR objetiva em `docs/adr/`,
criando ou atualizando uma ADR pertinente ao requisito. Não criar relatórios
de implementação, documentos paralelos `docs/requisitos/RFxxx.md`, inventários
de arquivos ou cópias dos critérios de aceite. Preservar os RFs como especificações.
Atualizar README e documentação técnica apenas quando necessário ao uso ou manutenção.
A resposta final deve ser breve, indicando mudanças, testes e impedimentos reais.
Essa simplificação documental não dispensa implementação, testes ou validação.

## 12. Regra final

Não reutilizar código da implementação anterior descartada.

Este repositório deve ser tratado como uma implementação nova a partir da especificação funcional e das ADRs vigentes.
