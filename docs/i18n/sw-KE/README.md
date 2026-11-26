> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Suluhisho la hali ya matengenezo kwa programu zinazopangishwa kwenye Cloudflare lililojengwa kwa OpenTofu/Terraform na Cloudflare Worker ya TypeScript.

## Vipengele

- Ukurasa wa matengenezo wa HTML/CSS unaoweza kubinafsishwa wenye usaidizi wa nembo ya HTTPS na usimbaji mkali wa herufi maalum.
- Orodha ya ruhusa ya IPv4/IPv6 CIDR kupitia `CF-Connecting-IP` na kuruka kulingana na msimbo wa eneo wa ISO 3166-1 alpha-2.
- Vipindi vilivyopangwa vya matengenezo vya RFC3339 vyenye vichwa vya kiotomatiki vya `Retry-After` na kituo cha hali cha JSON.
- Kubadilisha hali wakati wa utekelezaji bila kukatiza huduma kupitia Workers KV na arifa za hiari za Slack/PagerDuty/webhook.
- Ujanibishaji wa kiotomatiki wa `Accept-Language` katika lugha na maeneo 45 wenye usaidizi wa RTL.

## Matumizi ya Msingi

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

## Ujanibishaji

Worker hukusanya lugha na maeneo 45 (maeneo 20 ya Daraja la 1, 15 ya Afrika, na 10 ya Asia) na kujadiliana majibu kwa kutumia thamani za ubora za RFC 9110 `Accept-Language`, ikiweka `Content-Language` na `Vary: Accept-Language`. Maeneo ya RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) hutoa `dir="rtl"`. Thamani maalum za `maintenance_title`, `maintenance_message`, `pages`, na mabadiliko ya KV huhifadhiwa jinsi zilivyo.

## Majaribio na Leseni

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Tazama [README kamili ya Kiingereza](../../../README.md) kwa majedwali ya ingizo/matokeo yaliyoundwa. Imepewa leseni chini ya [MIT](../../../LICENSE).
