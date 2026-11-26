> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lisensya](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Bersyon ng OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Solusyon para sa maintenance mode ng mga application na naka-host sa Cloudflare na binuo gamit ang OpenTofu/Terraform at isang TypeScript Cloudflare Worker.

## Mga Tampok

- Nako-customize na HTML/CSS maintenance page na may suporta sa HTTPS logo at mahigpit na pag-escape.
- IPv4/IPv6 CIDR allowlisting sa pamamagitan ng `CF-Connecting-IP` at pag-bypass ayon sa ISO 3166-1 alpha-2 na rehiyon.
- Mga nakaiskedyul na RFC3339 maintenance window na may awtomatikong `Retry-After` header at JSON status endpoint.
- Zero-downtime na runtime toggle sa pamamagitan ng Workers KV at opsyonal na mga abiso sa Slack/PagerDuty/webhook.
- Awtomatikong `Accept-Language` na lokalisasyon sa 45 locale na may suporta sa RTL.

## Pangunahing Paggamit

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

## Lokalisasyon

May kasamang 45 locale ang Worker (20 Tier 1, 15 African, at 10 Asian na locale) at nakikipagnegosasyon ng mga tugon gamit ang mga quality value ng RFC 9110 `Accept-Language`, habang itinatakda ang `Content-Language` at `Vary: Accept-Language`. Naglalabas ng `dir="rtl"` ang mga RTL na locale (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`). Pinapanatili nang eksakto ang mga custom na `maintenance_title`, `maintenance_message`, `pages`, at mga KV override.

## Pagsusuri at Lisensya

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Tingnan ang buong [README sa Ingles](../../../README.md) para sa mga nabuong talahanayan ng input/output. Lisensyado sa ilalim ng [MIT](../../../LICENSE).
