> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Ngwọta ọnọdụ mmezi maka ngwa ndị dị na Cloudflare e ji OpenTofu/Terraform na Cloudflare Worker nke TypeScript wuo.

## Njirimara

- Peeji mmezi HTML/CSS a pụrụ ịhazi nke nwere nkwado akara HTTPS na mgbapụ siri ike.
- Ndepụta IPv4/IPv6 CIDR e kwere site na `CF-Connecting-IP` na mgbapụ mpaghara ISO 3166-1 alpha-2.
- Oge mmezi RFC3339 edobere nwere isi okwu `Retry-After` akpaaka na ebe njedebe ọnọdụ JSON.
- Mgbanwe oge mmezu na-enweghị nkwụsị ọrụ site na Workers KV na ọkwa nhọrọ nke Slack/PagerDuty/webhook.
- Ntụgharị asụsụ `Accept-Language` akpaaka gafee asụsụ obodo 45 nwere nkwado RTL.

## Ojiji Isi

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

## Nkwado asụsụ obodo

Worker ahụ chịkọtara asụsụ obodo 45 (asụsụ Tier 1 20, asụsụ Afrịka 15, na asụsụ Eshia 10) ma na-ekpebi nzaghachi site na iji uru ịdị mma `Accept-Language` nke RFC 9110, na-atọ `Content-Language` na `Vary: Accept-Language`. Asụsụ obodo RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) na-ewepụta `dir="rtl"`. A na-edobe `maintenance_title`, `maintenance_message`, `pages`, na mgbanwe KV omenala ka ha dị.

## Nnwale na Ikikere

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Lee [README Bekee](../../../README.md) zuru ezu maka tebụl ntinye/mmepụta e mepụtara. E nyere ikikere n'okpuru [MIT](../../../LICENSE).
