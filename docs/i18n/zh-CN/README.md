> [English](../../../README.md)

# Terraform Cloudflare 维护模式

[![许可证](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu 版本](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

基于 OpenTofu/Terraform 与 TypeScript Cloudflare Worker 构建的 Cloudflare 托管应用维护模式解决方案。

## 功能特性

- 支持自定义 HTML/CSS 维护页面，提供 HTTPS Logo 支持及严格转义。
- 通过 `CF-Connecting-IP` 实现 IPv4/IPv6 CIDR 白名单放行，并支持基于 ISO 3166-1 alpha-2 地区代码的绕过。
- 支持按 RFC3339 计划的维护时间窗口，自动返回 `Retry-After` 响应头并提供 JSON 状态端点。
- 通过 Workers KV 实现零停机运行时开关，并可选配置 Slack/PagerDuty/webhook 通知。
- 支持基于 `Accept-Language` 的 45 个语言环境自动本地化，并支持 RTL 布局。

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

## 本地化

Worker 内置了 45 个语言环境（20 个 Tier 1、15 个非洲和 10 个亚洲语言环境），并使用 RFC 9110 `Accept-Language` 质量值进行内容协商，同时设置 `Content-Language` 与 `Vary: Accept-Language` 响应头。RTL 语言环境（`ar`、`ar-EG`、`ar-MA`、`fa`、`he`、`ur`）会输出 `dir="rtl"`。自定义的 `maintenance_title`、`maintenance_message`、`pages` 以及 KV 覆盖值将按原样保留。

## 测试与许可证

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

有关自动生成的输入/输出参数表，请参阅完整的[英文 README](../../../README.md)。基于 [MIT](../../../LICENSE) 协议开源。
