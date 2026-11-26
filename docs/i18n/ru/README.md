> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Решение для режима технического обслуживания приложений, размещённых в Cloudflare, на базе OpenTofu/Terraform и TypeScript-скрипта Cloudflare Worker.

## Возможности

- Настраиваемая HTML/CSS-страница технического обслуживания с поддержкой логотипа по HTTPS и строгим экранированием.
- Списки разрешённых подсетей IPv4/IPv6 CIDR по заголовку `CF-Connecting-IP` и обход по коду региона ISO 3166-1 alpha-2.
- Запланированные окна обслуживания в формате RFC3339 с автоматическими заголовками `Retry-After` и конечной точкой состояния в формате JSON.
- Переключение во время работы без простоев через Workers KV и необязательные уведомления в Slack, PagerDuty или по вебхукам.
- Автоматическая локализация по заголовку `Accept-Language` для 45 локалей с поддержкой RTL.

## Базовое использование

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

## Локализация

Worker включает 45 локалей (20 локалей Tier 1, 15 африканских и 10 азиатских) и согласует язык ответа с помощью значений качества `Accept-Language` согласно RFC 9110, устанавливая заголовки `Content-Language` и `Vary: Accept-Language`. Локали RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) формируют атрибут `dir="rtl"`. Пользовательские значения `maintenance_title`, `maintenance_message`, `pages` и переопределения KV сохраняются без изменений.

## Тестирование и лицензия

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Сгенерированные таблицы входных и выходных параметров см. в полной [английской версии README](../../../README.md). Распространяется под лицензией [MIT](../../../LICENSE).
