> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licentie](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu-versie](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Oplossing voor onderhoudsmodus bij op Cloudflare gehoste applicaties, gebouwd met OpenTofu/Terraform en een TypeScript Cloudflare Worker.

## Functies

- Aanpasbare HTML/CSS-onderhoudspagina met ondersteuning voor HTTPS-logo's en strikte escaping.
- IPv4/IPv6 CIDR-allowlisting via `CF-Connecting-IP` en regio-uitzondering op basis van ISO 3166-1 alpha-2.
- Geplande RFC3339-onderhoudsvensters met automatische `Retry-After`-headers en een JSON-statusendpoint.
- Runtime-omschakeling zonder downtime via Workers KV en optionele meldingen via Slack, PagerDuty of webhooks.
- Automatische `Accept-Language`-lokalisatie voor 45 locales met RTL-ondersteuning.

## Basisgebruik

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

## Lokalisatie

De Worker bundelt 45 locales (20 Tier 1-, 15 Afrikaanse en 10 Aziatische locales) en onderhandelt antwoorden op basis van RFC 9110 `Accept-Language`-kwaliteitswaarden, waarbij `Content-Language` en `Vary: Accept-Language` worden ingesteld. RTL-locales (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) geven `dir="rtl"` uit. Aangepaste `maintenance_title`, `maintenance_message`, `pages` en KV-overrides blijven letterlijk behouden.

## Testen en licentie

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Zie de volledige [Engelse README](../../../README.md) voor gegenereerde invoer- en uitvoertabellen. Gelicentieerd onder [MIT](../../../LICENSE).
