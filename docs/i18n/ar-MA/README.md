> [English](../../../README.md)

# صيانة Cloudflare عبر Terraform

[![الترخيص](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![إصدار OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

حل لوضع الصيانة للتطبيقات المستضافة على Cloudflare، مبني باستخدام OpenTofu/Terraform وCloudflare Worker بلغة TypeScript.

## الميزات

- صفحة صيانة HTML/CSS قابلة للتخصيص مع دعم الشعار عبر HTTPS وتهريب صارم للنصوص.
- قوائم السماح لنطاقات CIDR لكل من IPv4/IPv6 عبر `CF-Connecting-IP` وتجاوز المناطق حسب معيار ISO 3166-1 alpha-2.
- نوافذ صيانة مجدولة بصيغة RFC3339 مع ترويسات `Retry-After` التلقائية ونقطة نهاية JSON للحالة.
- التبديل الفوري أثناء التشغيل دون توقف عبر Workers KV وإشعارات اختيارية عبر Slack/PagerDuty/webhook.
- توطين تلقائي عبر `Accept-Language` لـ 45 لغة محلية مع دعم RTL.

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

## التوطين

يدمج Worker 45 لغة محلية (20 من المستوى 1، و15 لغة إفريقية، و10 لغات آسيوية) ويتفاوض على الاستجابات باستخدام قيم الجودة في `Accept-Language` وفق RFC 9110، مع تعيين `Content-Language` و`Vary: Accept-Language`. تصدر اللغات المكتوبة من اليمين إلى اليسار (`ar`، `ar-EG`، `ar-MA`، `fa`، `he`، `ur`) السمة `dir="rtl"`. ويتم الحفاظ على القيم المخصصة لـ `maintenance_title` و`maintenance_message` و`pages` وتجاوزات KV كما هي حرفيا.

## الاختبار والترخيص

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

راجع [ملف README الإنجليزي الكامل](../../../README.md) لجداول المدخلات والمخرجات المولدة. مرخص بموجب [MIT](../../../LICENSE).
