> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

專為 Cloudflare 託管應用程式打造的維護模式解決方案，使用 OpenTofu/Terraform 與 TypeScript Cloudflare Worker 建置。

## 功能特色

- 可自訂的 HTML/CSS 維護頁面，支援 HTTPS 標誌圖片與嚴格跳脫處理。
- 透過 `CF-Connecting-IP` 進行 IPv4/IPv6 CIDR 允許清單過濾，以及 ISO 3166-1 alpha-2 地區略過。
- 支援 RFC3339 排程維護時段，並自動附加 `Retry-After` 標頭與提供 JSON 狀態端點。
- 透過 Workers KV 實現零停機時間的執行期切換，並可選配 Slack/PagerDuty/Webhook 通知。
- 跨 45 種語系的自動 `Accept-Language` 在地化處理，並支援 RTL。

## 基本用法

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

## 在地化

此 Worker 套件包含 45 種語系（20 種 Tier 1 語系、15 種非洲語系與 10 種亞洲語系），並使用 RFC 9110 `Accept-Language` 品質值進行回應協商，同時設定 `Content-Language` 與 `Vary: Accept-Language`。RTL 語系（`ar`、`ar-EG`、`ar-MA`、`fa`、`he`、`ur`）會輸出 `dir="rtl"`。自訂的 `maintenance_title`、`maintenance_message`、`pages` 與 KV 覆寫設定皆會原封不動保留。

## 測試與授權條款

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

產生的輸入與輸出表格請參閱完整的[英文 README](../../../README.md)。採用 [MIT](../../../LICENSE) 授權條款。
