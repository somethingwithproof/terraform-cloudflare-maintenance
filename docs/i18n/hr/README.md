> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licencija](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Inačica OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Rješenje za način održavanja za aplikacije udomljene na Cloudflare infrastrukturi, izgrađeno pomoću alata OpenTofu/Terraform i Cloudflare Worker poslužitelja napisanog u TypeScriptu.

## Značajke

- Prilagodljiva HTML/CSS stranica održavanja s podrškom za HTTPS logotip i strogim kodiranjem znakova.
- Popisi dopuštenih IPv4/IPv6 CIDR adresa na temelju zaglavlja `CF-Connecting-IP` te zaobilaženje načina održavanja prema ISO 3166-1 alpha-2 oznaci regije.
- Zakazani prozori održavanja u RFC3339 obliku s automatskim zaglavljem `Retry-After` i JSON krajnjom točkom stanja.
- Prebacivanje u stvarnom vremenu bez zastoja putem usluge Workers KV te izborne obavijesti putem Slacka, PagerDutyja i webhooka.
- Automatska lokalizacija putem zaglavlja `Accept-Language` za 48 jezičnih oznaka uz podršku za RTL.

## Osnovna uporaba

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

## Lokalizacija

Worker objedinjuje 48 jezičnih oznaka (20 Tier 1, 15 afričkih, 10 azijskih i 3 južnoslavenske) i pregovara jezik odgovora prema RFC 9110 težinama kakvoće u zaglavlju `Accept-Language`, uz postavljanje zaglavlja `Content-Language` i `Vary: Accept-Language`. RTL oznake (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) dodaju `dir="rtl"`. Prilagođene vrijednosti `maintenance_title`, `maintenance_message`, `pages` i KV zamjene čuvaju se doslovno.

## Ispitivanje i licencija

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Generirane tablice ulaznih i izlaznih vrijednosti nalaze se u cjelovitoj [engleskoj inačici README](../../../README.md). Objavljeno pod licencijom [MIT](../../../LICENSE).
