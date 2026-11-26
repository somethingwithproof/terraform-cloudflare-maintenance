> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Ìwé-àṣẹ](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Ẹ̀dà OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Ìdáhùn ipò ìtọ́jú-àtúnṣe fún àwọn ohun-èlò tí a gbé kalẹ̀ lórí Cloudflare tí a kọ́ pẹ̀lú OpenTofu/Terraform àti TypeScript Cloudflare Worker.

## Àwọn ẹ̀yà ara

- Ojú-ewé ìtọ́jú-àtúnṣe HTML/CSS tí a lè ṣàtúnṣe pẹ̀lú àtìlẹ́yìn àmì-ìdámọ̀ HTTPS àti ìyẹ̀rí-kọ́ọ̀dù (escaping) tí ó le.
- Fífàyègbà IPv4/IPv6 CIDR nípasẹ̀ `CF-Connecting-IP` àti ìyẹ̀rí agbègbè ISO 3166-1 alpha-2.
- Àwọn àkókò ìtọ́jú-àtúnṣe RFC3339 tí a ṣètò pẹ̀lú àwọn àkọlé `Retry-After` aládàáni àti ojú-ọ̀nà ipò JSON.
- Yíyípadà àkókò-ìṣiṣẹ́ láìsí ìdádúró nípasẹ̀ Workers KV àti àwọn ìfitónilétí Slack/PagerDuty/webhook tí ó ṣeé yàn.
- Ìsọdèdè-agbègbè `Accept-Language` aládàáni káàkiri àwọn èdè agbègbè 45 pẹ̀lú àtìlẹ́yìn RTL.

## Ìlò Ìpìlẹ̀

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

## Ìsọdèdè-agbègbè

Worker náà ń kó àwọn èdè agbègbè 45 jọ (20 ti Ìpele 1, 15 ti Áfíríkà, àti 10 ti Éṣíà), ó sì ń ṣe ìjíròrò àwọn ìdáhùn nípa lílo àwọn iye ìdára `Accept-Language` ti RFC 9110, tí ó sì ń ṣètò `Content-Language` àti `Vary: Accept-Language`. Àwọn èdè agbègbè RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) ń gbé `dir="rtl"` jáde. Àwọn àtúnṣe àdáni `maintenance_title`, `maintenance_message`, `pages`, àti àwọn ìrọ́pò KV ni a máa ń tọ́jú bí wọ́n ṣe rí gan-an.

## Ìdánwò àti Ìwé-àṣẹ

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Wo [README èdè Gẹ̀ẹ́sì](../../../README.md) ní kíkún fún àwọn tábìlì ìtẹ̀síwájú àti àbájáde tí a ṣẹ̀dá. A fún un ní ìwé-àṣẹ lábẹ́ [MIT](../../../LICENSE).
