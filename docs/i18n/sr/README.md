> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Лиценца](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Верзија OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Решење за режим одржавања за апликације хостоване на Cloudflare инфраструктури, изграђено помоћу OpenTofu/Terraform алата и Cloudflare Worker сервиса написаног у TypeScript-у.

## Функције

- Прилагодљива HTML/CSS страница одржавања са подршком за HTTPS логотип и строгим ескејповањем садржаја.
- Листе дозвољених IPv4/IPv6 CIDR адреса на основу заглавља `CF-Connecting-IP` и заобилажење режима одржавања према ISO 3166-1 alpha-2 коду региона.
- Заказани прозори одржавања у RFC3339 формату са аутоматским заглављем `Retry-After` и JSON крајњом тачком статуса.
- Пребацивање у реалном времену без застоја путем Workers KV сервиса и опциона обавештења за Slack, PagerDuty и webhook.
- Аутоматска локализација путем заглавља `Accept-Language` за 48 језичких ознака уз подршку за RTL.

## Основна употреба

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

## Локализација

Worker укључује 48 језичких ознака (20 Tier 1, 15 афричких, 10 азијских и 3 јужнословенске) и преговара језик одговора према RFC 9110 тежинама квалитета из заглавља `Accept-Language`, уз постављање заглавља `Content-Language` и `Vary: Accept-Language`. RTL ознаке (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) додају `dir="rtl"`. Прилагођене вредности `maintenance_title`, `maintenance_message`, `pages` и KV измене остају сачуване дословно.

## Тестирање и лиценца

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Генерисане табеле улазних и излазних параметара налазе се у потпуној [енглеској верзији README](../../../README.md). Објављено под лиценцом [MIT](../../../LICENSE).
