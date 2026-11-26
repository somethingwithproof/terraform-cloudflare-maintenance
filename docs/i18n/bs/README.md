> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licenca](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Verzija OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Rješenje za režim održavanja za aplikacije hostirane na Cloudflare infrastrukturi, izgrađeno pomoću OpenTofu/Terraform alata i Cloudflare Worker servisa u jeziku TypeScript.

## Mogućnosti

- Prilagodljiva HTML/CSS stranica održavanja sa podrškom za HTTPS logotip i strogim eskejpovanjem sadržaja.
- Liste dozvoljenih IPv4/IPv6 CIDR adresa na osnovu zaglavlja `CF-Connecting-IP` i zaobilaženje režima održavanja prema ISO 3166-1 alpha-2 kodu regije.
- Planirani termini održavanja u RFC3339 formatu sa automatskim zaglavljem `Retry-After` i JSON krajnjom tačkom statusa.
- Prebacivanje u realnom vremenu bez prekida rada putem Workers KV servisa i opcionalna obavještenja za Slack, PagerDuty i webhook.
- Automatska lokalizacija putem zaglavlja `Accept-Language` za 48 jezičkih oznaka uz podršku za RTL.

## Osnovna upotreba

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

## Lokalizacija

Worker uključuje 48 jezičkih oznaka (20 Tier 1, 15 afričkih, 10 azijskih i 3 južnoslavenske) i određuje jezik odgovora prema RFC 9110 težinama kvaliteta iz zaglavlja `Accept-Language`, uz postavljanje zaglavlja `Content-Language` i `Vary: Accept-Language`. RTL oznake (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) dodaju `dir="rtl"`. Prilagođene vrijednosti `maintenance_title`, `maintenance_message`, `pages` i KV nadjačavanja ostaju sačuvane doslovno.

## Testiranje i licenca

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Generisane tabele ulaznih i izlaznih parametara nalaze se u punoj [engleskoj verziji README](../../../README.md). Objavljeno pod licencom [MIT](../../../LICENSE).
