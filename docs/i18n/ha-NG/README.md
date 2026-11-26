> [English](../../../README.md)

# Kula da Cloudflare da Terraform

[![Lasisi](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Sigar OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Maganin yanayin kulawa don manhajojin da aka ɗaura a Cloudflare wanda aka gina da OpenTofu/Terraform da TypeScript Cloudflare Worker.

## Abubuwan da Ke Ciki

- Shafin kulawa na HTML/CSS mai sauƙin gyara tare da tallafin tambarin HTTPS da tsaftataccen tsarin tsaro.
- Jerin izinin IPv4/IPv6 CIDR ta hanyar `CF-Connecting-IP` da ƙetare yanki na ISO 3166-1 alpha-2.
- Lokutan kulawa da aka tsara na RFC3339 tare da kawunan `Retry-After` na atomatik da tashar bayanin matsayi ta JSON.
- Canza yanayi ba tare da katsewar sabis ba ta hanyar Workers KV da sanarwar zaɓi na Slack/PagerDuty/webhook.
- Daidaita harshe na `Accept-Language` ta atomatik a harsuna 45 tare da tallafin RTL.

## Amfani na Asali

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

## Daidaita Harshe

Worker ɗin yana ɗauke da harsuna 45 (20 na Mataki na 1, 15 na Afirka, da 10 na Asiya) kuma yana daidaita amsoshi ta amfani da ƙimar ingancin RFC 9110 `Accept-Language`, yana saita `Content-Language` da `Vary: Accept-Language`. Harsunan RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) suna fitar da `dir="rtl"`. Ana kiyaye `maintenance_title`, `maintenance_message`, `pages`, da saitin KV na musamman yadda suke.

## Gwaji da Lasisi

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Duba cikakken [README na Turanci](../../../README.md) don teburan shigarwa da fitarwa da aka samar. An ba da lasisi ƙarƙashin [MIT](../../../LICENSE).
