> [English](../../../README.md)

# حالت نگهداری Cloudflare با Terraform

[![مجوز](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![نسخه OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

راهکار حالت نگهداری برای برنامه‌های میزبانی‌شده روی Cloudflare، ساخته‌شده با OpenTofu/Terraform و یک Cloudflare Worker به زبان TypeScript.

## ویژگی‌ها

- صفحه نگهداری HTML/CSS قابل سفارشی‌سازی با پشتیبانی از لوگوی HTTPS و کدگذاری ایمن.
- فهرست مجاز CIDR برای IPv4/IPv6 از طریق `CF-Connecting-IP` و عبور بر اساس منطقه ISO 3166-1 alpha-2.
- بازه‌های نگهداری زمان‌بندی‌شده با فرمت RFC3339 همراه با هدرهای خودکار `Retry-After` و نقطه پایانی وضعیت JSON.
- تغییر وضعیت در زمان اجرا بدون قطعی از طریق Workers KV و اعلان‌های اختیاری Slack/PagerDuty/وب‌هوک.
- بومی‌سازی خودکار بر اساس `Accept-Language` در ۴۵ زبان محلی با پشتیبانی از راست‌به‌چپ (RTL).

## نحوه استفاده پایه

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

## بومی‌سازی

این Worker شامل ۴۵ زبان محلی (۲۰ زبان رده اول، ۱۵ زبان آفریقایی و ۱۰ زبان آسیایی) است و پاسخ‌ها را با استفاده از مقادیر کیفیت `Accept-Language` طبق استاندارد RFC 9110 مذاکره کرده و هدرهای `Content-Language` و `Vary: Accept-Language` را تنظیم می‌کند. زبان‌های راست‌به‌چپ (`ar`، `ar-EG`، `ar-MA`، `fa`، `he`، `ur`) صفت `dir="rtl"` را خروجی می‌دهند. مقادیر سفارشی `maintenance_title`، `maintenance_message`، `pages` و بازنویسی‌های KV عینا حفظ می‌شوند.

## آزمون و مجوز

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

برای مشاهده جدول‌های ورودی و خروجی تولیدشده به [نسخه انگلیسی README](../../../README.md) مراجعه کنید. منتشرشده تحت مجوز [MIT](../../../LICENSE).
