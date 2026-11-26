> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Vahaolana ho an'ny fomba fikojakojana ho an'ny rindranasa ampiantranoin'ny Cloudflare namboarina tamin'ny OpenTofu/Terraform sy TypeScript Cloudflare Worker.

## Endri-javatra

- Pejy fikojakojana HTML/CSS azo ovaina miaraka amin'ny fanohanana sary famantarana HTTPS sy fiarovana henjana amin'ny fanodinana litera manokana.
- Lisitra IPv4/IPv6 CIDR nahazo alalana amin'ny alalan'ny `CF-Connecting-IP` sy fandalovana araka ny faritra ISO 3166-1 alpha-2.
- Fe-potoana fikojakojana voalamina araka ny RFC3339 miaraka amin'ny lohateny `Retry-After` mandeha ho azy sy teboka famaranana sata JSON.
- Fanodinana mandritra ny fampandehanana tsy misy fahatapahana amin'ny alalan'ny Workers KV ary fampandrenesana Slack/PagerDuty/webhook raha tiana.
- Fampifanarahana amin'ny fiteny mandeha ho azy amin'ny alalan'ny `Accept-Language` manerana ny fiteny eo an-toerana miisa 45 miaraka amin'ny fanohanana RTL.

## Fampiasana fototra

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

## Fampifanarahana amin'ny fiteny

Ny Worker dia manambatra fiteny eo an-toerana miisa 45 (fiteny sokajy 1 miisa 20, fiteny afrikanina miisa 15, ary fiteny aziatika miisa 10) ary mifanaraka amin'ny valinteny amin'ny fampiasana ny sandan'ny kalitao RFC 9110 `Accept-Language`, ka mametraka ny `Content-Language` sy `Vary: Accept-Language`. Ireo fiteny RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) dia mamoaka `dir="rtl"`. Ny `maintenance_title`, `maintenance_message`, `pages`, ary ny fanoloana KV namboarina manokana dia tazonina tsy miova.

## Fitsapana sy Lisansa

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Jereo ny [README amin'ny teny anglisy](../../../README.md) feno ho an'ny tabilao fampidirana/famoahana vokarina. Navoaka teo ambany lisansa [MIT](../../../LICENSE).
