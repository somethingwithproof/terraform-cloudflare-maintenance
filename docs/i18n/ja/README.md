> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform と TypeScript 製 Cloudflare Worker で構築された、Cloudflare ホスト型アプリケーション向けのメンテナンスモードソリューションです。

## 主な機能

- HTTPS ロゴ対応および厳格なエスケープ処理を備えたカスタマイズ可能な HTML/CSS メンテナンスページ。
- `CF-Connecting-IP` を用いた IPv4/IPv6 CIDR 許可リストおよび ISO 3166-1 alpha-2 地域バイパス。
- 自動 `Retry-After` ヘッダーと JSON ステータスエンドポイントを備えた、RFC3339 形式のスケジュール済みメンテナンス期間。
- Workers KV によるゼロダウンタイムのランタイム切り替えと、オプションの Slack/PagerDuty/Webhook 通知。
- RTL サポート付き 45 ロケールにわたる `Accept-Language` 自動ローカライズ。

## 基本的な使い方

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

## ローカライズ

Worker には 45 ロケール（Tier 1 が 20、アフリカ地域が 15、アジア地域が 10）がバンドルされており、RFC 9110 `Accept-Language` の品質値（q 値）を用いてレスポンスをネゴシエートし、`Content-Language` および `Vary: Accept-Language` を設定します。RTL ロケール（`ar`、`ar-EG`、`ar-MA`、`fa`、`he`、`ur`）では `dir="rtl"` が出力されます。カスタムの `maintenance_title`、`maintenance_message`、`pages`、および KV オーバーライドはそのまま保持されます。

## テストとライセンス

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

生成された入出力テーブルについては[英語版 README](../../../README.md)を参照してください。ライセンスは [MIT](../../../LICENSE) です。
