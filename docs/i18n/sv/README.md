> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licens](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu-version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Lösning för underhållsläge i Cloudflare-baserade applikationer byggd med OpenTofu/Terraform och en TypeScript-baserad Cloudflare Worker.

## Funktioner

- Anpassningsbar HTML/CSS-underhållssida med stöd för HTTPS-logotyp och strikt escaping.
- Tillåtelselistor för IPv4/IPv6 CIDR via `CF-Connecting-IP` och förbikoppling baserad på region enligt ISO 3166-1 alpha-2.
- Schemalagda RFC3339-underhållsfönster med automatiska `Retry-After`-huvuden och en JSON-statusändpunkt.
- Växling i körtid utan avbrott via Workers KV samt valfria aviseringar till Slack, PagerDuty eller webhook.
- Automatisk `Accept-Language`-lokalisering för 45 språkområden med RTL-stöd.

## Grundläggande användning

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

Workern paketerar 45 språkområden (20 Tier 1-, 15 afrikanska och 10 asiatiska språkområden) och förhandlar svar med hjälp av RFC 9110 `Accept-Language`-kvalitetsvärden, samt sätter `Content-Language` och `Vary: Accept-Language`. RTL-språkområden (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) matar ut `dir="rtl"`. Anpassade `maintenance_title`, `maintenance_message`, `pages` och KV-åsidosättningar bevaras ordagrant.

## Testning och licens

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Se den fullständiga [engelska README-filen](../../../README.md) för genererade in- och utdatatabeller. Licensierad under [MIT](../../../LICENSE).
