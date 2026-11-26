> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Igisubizo cy'uburyo bwo gusana ku maporogaramu acumbikiwe kuri Cloudflare cyubatswe hakoreshejwe OpenTofu/Terraform na Cloudflare Worker ya TypeScript.

## Ibiranga

- Urupapuro rw'isana rwa HTML/CSS ruhindurwa uko ushaka rufite ubufasha bwa logo ya HTTPS n'ubwirinzi bukomeye bw'inyandiko.
- Urutonde rw'imyanya ya IPv4/IPv6 CIDR yemewe hakoreshejwe `CF-Connecting-IP` no kurenza akarere ka ISO 3166-1 alpha-2.
- Ibihe by'isana byateguwe hakurikijwe RFC3339 bifite imitwe ya `Retry-After` yikora na endpoint y'imiterere ya JSON.
- Guhindura uburyo mu gihe cyo gukora nta guhagarara ukoresheje Workers KV n'ubumenyesha bwa Slack/PagerDuty/webhook iyo ubishaka.
- Ishyirwa mu ndimi rya `Accept-Language` ryikora mu ndimi 45 hamwe n'ubufasha bwa RTL.

## Ikoreshwa ry'ibanze

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

## Ishyirwa mu ndimi

Worker ikomatanya indimi 45 (indimi 20 z'icyiciro cya 1, 15 zo muri Afurika, na 10 zo muri Aziya) kandi ikumvikana ku bisubizo ikoresheje agaciro k'ubwiza ka RFC 9110 `Accept-Language`, ishyiraho `Content-Language` na `Vary: Accept-Language`. Indimi za RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) zitanga `dir="rtl"`. `maintenance_title`, `maintenance_message`, `pages`, n'impinduka za KV byihariye bibikwa uko byanditswe.

## Isuzuma n'Uruhushya

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Reba [README yuzuye mu Cyongereza](../../../README.md) kugira ngo ubone imbonerahamwe z'ibyinjizwa n'ibisohoka byakozwe. Ifite uruhushya rwa [MIT](../../../LICENSE).
