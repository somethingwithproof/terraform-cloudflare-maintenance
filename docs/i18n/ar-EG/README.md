> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

حل لوضع الصيانة للتطبيقات المستضافة على Cloudflare، مبني باستخدام OpenTofu/Terraform وCloudflare Worker بلغة TypeScript.

## المميزات

- صفحة صيانة HTML/CSS قابلة للتخصيص مع دعم الشعار عبر HTTPS وتنقية صارمة للنصوص (strict escaping).
- قوائم سماح لعناوين IPv4/IPv6 CIDR عبر `CF-Connecting-IP`، وتجاوز حسب المنطقة بنظام ISO 3166-1 alpha-2.
- فترات صيانة مجدولة بصيغة RFC3339 مع ترويسات `Retry-After` تلقائية ونقطة نهاية (endpoint) للحالة بصيغة JSON.
- تبديل وقت التشغيل من غير توقف عبر Workers KV، وإشعارات اختيارية لـ Slack أو PagerDuty أو webhook.
- توطين تلقائي عبر `Accept-Language` لـ 45 لغة وإعداد محلي مع دعم اتجاه RTL.

## الاستخدام الأساسي

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

## اللغات والترجمة

الـ Worker بيدمج 45 لغة وإعداد محلي (20 من الفئة الأولى Tier 1، و15 لغة أفريقية، و10 لغات آسيوية) وبيتفاوض على الاستجابات باستخدام قيم الجودة في `Accept-Language` حسب RFC 9110، مع ضبط `Content-Language` و`Vary: Accept-Language`. اللغات اللي بتتكتب من اليمين لليسار (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) بتطلّع `dir="rtl"`. القيم المخصصة لـ `maintenance_title` و`maintenance_message` و`pages` وتجاوزات KV بتتحفظ زي ما هي بالظبط.

## الاختبار والترخيص

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

شوف [ملف README الإنجليزي](../../../README.md) الكامل لجداول المدخلات والمخرجات المولّدة. مرخّص بموجب [MIT](../../../LICENSE).
