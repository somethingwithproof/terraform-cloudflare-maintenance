> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Isixazululo semodi yokulungisa izinhlelo zokusebenza ezisingathwe ku-Cloudflare esakhiwe nge-OpenTofu/Terraform kanye ne-TypeScript Cloudflare Worker.

## Izici

- Ikhasi lokulungisa le-HTML/CSS elingenziwa ngendlela oyifisayo elisekela ilogo ye-HTTPS nokuphunyuka okuqinile.
- Uhlu oluvunyelwe lwe-IPv4/IPv6 CIDR nge-`CF-Connecting-IP` kanye nokweqa isifunda se-ISO 3166-1 alpha-2.
- Izikhathi zokulungisa ezihleliwe ze-RFC3339 ezinezihloko ezizenzakalelayo ze-`Retry-After` kanye nendawo yokugcina yesimo se-JSON.
- Ukushintsha kwesikhathi sokusebenza okungenakho ukuma kokusebenza nge-Workers KV kanye nezaziso zokuzikhethela ze-Slack/PagerDuty/webhook.
- Ukuhunyushwa okuzenzakalelayo kwe-`Accept-Language` ezilimini zendawo ezingu-45 okunokusekelwa kwe-RTL.

## Ukusetshenziswa Okuyisisekelo

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

## Ukwenziwa ngokwendawo

I-Worker ihlanganisa izilimi zendawo ezingu-45 (ezingu-20 ze-Tier 1, ezingu-15 zase-Afrika, kanye nezingu-10 zase-Asia) futhi ixoxisana ngezimpendulo isebenzisa amanani ekhwalithi e-RFC 9110 `Accept-Language`, isetha i-`Content-Language` ne-`Vary: Accept-Language`. Izilimi zendawo ze-RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) zikhipha i-`dir="rtl"`. I-`maintenance_title`, i-`maintenance_message`, i-`pages`, kanye nokushintsha kwe-KV ngokwezifiso kugcinwa njengoba kunjalo.

## Ukuhlolwa kanye Nelayisense

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Bheka [i-README yesiNgisi](../../../README.md) ephelele ngamathebula okokufaka/okokukhipha akhiqiziwe. Inikezwe ilayisense ngaphansi kwe-[MIT](../../../LICENSE).
