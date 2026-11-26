> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Solução de modo de manutenção para aplicações hospedadas na Cloudflare, construída com OpenTofu/Terraform e um Cloudflare Worker em TypeScript.

## Recursos

- Página de manutenção HTML/CSS personalizável com suporte a logotipo HTTPS e escape rigoroso.
- Lista de permissão CIDR IPv4/IPv6 via `CF-Connecting-IP` e bypass de região ISO 3166-1 alpha-2.
- Janelas de manutenção agendadas em RFC3339 com cabeçalhos `Retry-After` automáticos e endpoint de status em JSON.
- Alternância em tempo de execução sem tempo de inatividade via Workers KV e notificações opcionais via Slack/PagerDuty/webhook.
- Localização automática por `Accept-Language` em 45 locales com suporte a RTL.

## Uso básico

```hcl
provider "cloudflare" {}

module "maintenance" {
  source = "git::https://github.com/somethingwithproof/terraform-cloudflare-maintenance.git?ref=v4.0.0"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  enabled               = true
  worker_route          = "*.example.com/*"
}
```

## Localização

O Worker empacota 45 locales (20 Tier 1, 15 africanos e 10 asiáticos) e negocia respostas usando valores de qualidade de `Accept-Language` da RFC 9110, definindo `Content-Language` e `Vary: Accept-Language`. Locales RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) emitem `dir="rtl"`. Valores personalizados de `maintenance_title`, `maintenance_message`, `pages` e substituições via KV são preservados literalmente.

## Testes e Licença

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Consulte o [README em inglês](../../../README.md) completo para as tabelas geradas de entradas e saídas. Licenciado sob [MIT](../../../LICENSE).
