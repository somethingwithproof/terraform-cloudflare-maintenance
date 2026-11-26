> [English](../../../README.md)

# وضع الصيانة لـ Cloudflare عبر Terraform

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

حلّ لوضع الصيانة للتطبيقات المستضافة على Cloudflare، مبنيّ باستخدام OpenTofu/Terraform وCloudflare Worker بلغة TypeScript.

## الميزات

- صفحة صيانة قابلة للتخصيص بلغة HTML/CSS مع دعم الشعارات عبر HTTPS وتهريب صارم للنصوص.
- قوائم سماح لعناوين IPv4/IPv6 بصيغة CIDR عبر `CF-Connecting-IP` وتجاوز الحجب حسب المناطق وفق معيار ISO 3166-1 alpha-2.
- نوافذ صيانة مجدولة بصيغة RFC3339 مع ترويسات `Retry-After` تلقائية ونقطة نهاية JSON للحالة.
- تبديل فوري في وقت التشغيل دون توقّف عبر Workers KV وإشعارات اختيارية عبر Slack أو PagerDuty أو webhook.
- توطين تلقائي عبر `Accept-Language` لـ 45 لغةً وإعدادًا محليًا مع دعم الاتجاه من اليمين إلى اليسار (RTL).

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

يضمّ الـ Worker حزمًا لـ 45 لغةً وإعدادًا محليًا (20 لغةً من المستوى الأول، و15 لغةً أفريقيةً، و10 لغاتٍ آسيويةٍ) ويتفاوض على الاستجابات باستخدام قيم الجودة في `Accept-Language` وفق معيار RFC 9110، مع ضبط ترويستَي `Content-Language` و`Vary: Accept-Language`. وتُصدر اللغات التي تُكتب من اليمين إلى اليسار (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) السمة `dir="rtl"`. أمّا القيم المخصّصة لـ `maintenance_title` و`maintenance_message` و`pages` وتجاوزات KV فتُحفظ حرفيًا دون تعديل.

## الاختبار والترخيص

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

راجع [ملف README الإنجليزي الكامل](../../../README.md) للاطّلاع على جداول المدخلات والمخرجات المُولَّدة. مرخّص بموجب [MIT](../../../LICENSE).
