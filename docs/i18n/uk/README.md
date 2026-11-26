> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Ліцензія](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Версія OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Рішення для режиму технічного обслуговування застосунків на базі Cloudflare, побудоване з використанням OpenTofu/Terraform і Cloudflare Worker на TypeScript.

## Можливості

- Налаштовувана HTML/CSS-сторінка технічного обслуговування з підтримкою HTTPS-логотипів і суворим екрануванням.
- Списки дозволених IPv4/IPv6 CIDR через `CF-Connecting-IP` та обхід блокування за регіонами ISO 3166-1 alpha-2.
- Заплановані вікна технічного обслуговування у форматі RFC3339 з автоматичними заголовками `Retry-After` і кінцевою точкою стану JSON.
- Перемикання під час виконання без простоїв через Workers KV та опційні сповіщення у Slack, PagerDuty або через вебхук.
- Автоматична локалізація за заголовком `Accept-Language` для 45 локалей із підтримкою RTL.

## Базове використання

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

## Локалізація

Worker містить 45 локалей (20 рівня Tier 1, 15 африканських і 10 азійських локалей) і узгоджує відповіді за значеннями якості `Accept-Language` відповідно до RFC 9110, встановлюючи `Content-Language` та `Vary: Accept-Language`. Для RTL-локалей (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) додається `dir="rtl"`. Власні значення `maintenance_title`, `maintenance_message`, `pages` і перевизначення KV зберігаються без змін.

## Тестування та ліцензія

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Див. повний [README англійською](../../../README.md), щоб переглянути згенеровані таблиці вхідних і вихідних параметрів. Ліцензовано за [MIT](../../../LICENSE).
