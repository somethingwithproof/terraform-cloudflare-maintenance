> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lisensie](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu-weergawe](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Onderhoudsmodus-oplossing vir Cloudflare-gehuisveste toepassings gebou met OpenTofu/Terraform en 'n TypeScript Cloudflare Worker.

## Kenmerke

- Aanpasbare HTML/CSS-onderhoudsbladsy met HTTPS-logo-ondersteuning en streng ontsnapping.
- IPv4/IPv6 CIDR-toelaatlys via `CF-Connecting-IP` en ISO 3166-1 alpha-2-streekomseiling.
- Geskeduleerde RFC3339-onderhoudsvensters met outomatiese `Retry-After`-kopstukke en 'n JSON-status-eindpunt.
- Nul-stilstand-looptydskakelaar via Workers KV en opsionele Slack/PagerDuty/webhook-kennisgewings.
- Outomatiese `Accept-Language`-lokalisering oor 45 locales met RTL-ondersteuning.

## Basiese gebruik

```hcl
provider "cloudflare" {}

module "maintenance" {
  source = "git::https://github.com/somethingwithproof/terraform-cloudflare-maintenance.git?ref=fc7007e19c4b6d63fac468f1b1349dacecc7336f"

  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  enabled               = true
  worker_route          = "*.example.com/*"
}
```

## Lokalisering

Die Worker bundel 45 locales (20 Vlak 1-, 15 Afrika- en 10 Asiatiese locales) en onderhandel antwoorde deur middel van RFC 9110 `Accept-Language`-kwaliteitswaardes, terwyl `Content-Language` en `Vary: Accept-Language` gestel word. RTL-locales (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) gee `dir="rtl"` uit. Pasgemaakte `maintenance_title`, `maintenance_message`, `pages` en KV-oorheersings word woordeliks behou.

## Toetsing en lisensie

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Sien die volledige [Engelse README](../../../README.md) vir gegenereerde inset-/uitsettabelle. Gelisensieer onder [MIT](../../../LICENSE).
