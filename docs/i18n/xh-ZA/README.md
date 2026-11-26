> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Ilayisensi](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Inguqulelo ye-OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Isisombululo semowudi yolondolozo lwezicelo ezibanjwe kwi-Cloudflare ezakhiwe nge-OpenTofu/Terraform kunye ne-TypeScript Cloudflare Worker.

## Iimpawu

- Iphepha lolondolozo le-HTML/CSS elinokwenziwa ngokwezifiso elinenkxaso yelogo ye-HTTPS kunye nokubaleka okungqongqo.
- Uluhlu lwamavume lwe-IPv4/IPv6 CIDR nge-`CF-Connecting-IP` kunye nokudlula kommandla we-ISO 3166-1 alpha-2.
- Amaxesha olondolozo acwangcisiweyo e-RFC3339 anezihloko ze-`Retry-After` ezizenzekelayo kunye nesiphelo sesimo se-JSON.
- Ukutshintsha ngexesha lokuqhuba okungenakuma nge-Workers KV kunye nezaziso ezingakhethwayo ze-Slack/PagerDuty/webhook.
- Ulungiselelo lweelwimi lwe-`Accept-Language` oluzenzekelayo kwiilwimi zasekuhlaleni ezingama-45 olunenkxaso ye-RTL.

## Ukusetyenziswa okuSisiseko

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

## Ulungiselelo lweelwimi

I-Worker idibanisa iilwimi zasekuhlaleni ezingama-45 (ezingama-20 ze-Tier 1, ezili-15 zase-Afrika, nezili-10 zase-Asia) kwaye ixoxisana ngeempendulo isebenzisa amaxabiso omgangatho we-RFC 9110 `Accept-Language`, ibeka `Content-Language` kunye ne-`Vary: Accept-Language`. Iilwimi zasekuhlaleni ze-RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) zikhupha u-`dir="rtl"`. I-`maintenance_title`, `maintenance_message`, `pages`, kunye nokubeka ecaleni kwe-KV okwenziwe ngokwezifiso zigcinwa ngokuthe ngqo njengoko zinjalo.

## Uvavanyo neLayisensi

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Jonga i-[README yesiNgesi](../../../README.md) epheleleyo ukuze ufumane iitheyibhile zokufaka/zokukhupha ezivelisiweyo. Inikwe ilayisensi phantsi kwe-[MIT](../../../LICENSE).
