# Skill — Ruby on Rails

## Objetivo

Orientar implementações Rails deste projeto usando padrões simples, seguros e idiomáticos.

## Diretrizes

- Preferir recursos nativos do Rails antes de adicionar gems.
- Manter controllers pequenos.
- Colocar regras de domínio em models ou objetos dedicados quando houver benefício real.
- Usar Active Record com scopes claros e consultas legíveis.
- Evitar callbacks para fluxos complexos ou efeitos colaterais difíceis de rastrear.
- Usar transações para operações que precisam ser atômicas.
- Usar locking/constraints quando houver concorrência.
- Validar dados no servidor mesmo quando também validados no navegador.
- Usar I18n para textos que devam ser traduzíveis ou padronizados.
- Configurar `config.time_zone = "America/Sao_Paulo"` quando o RF de fundação inicializar Rails.
- Manter timestamps persistidos em UTC.

## Views

- Preferir ERB.
- Usar partials quando reduzirem duplicação real.
- Manter escaping padrão do Rails.
- Não usar `html_safe` ou `raw` com entrada não confiável.

## JavaScript

- Usar Turbo/Stimulus apenas para comportamento necessário.
- Não transformar a aplicação em SPA.
- Não transportar regra crítica para o cliente.

## Banco

- PostgreSQL.
- Foreign keys e índices devem ser avaliados em toda migration.
- Regras de unicidade críticas devem existir no banco, não apenas no model.

## Testes

Toda regra de negócio introduzida por RF deve possuir teste correspondente.
