> [English](../../../README.md)

# Terraform Cloudflare مینٹیننس

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform اور TypeScript Cloudflare Worker کے ساتھ تیار کردہ Cloudflare پر ہوسٹ کی گئی ایپلیکیشنز کے لیے مینٹیننس موڈ کا حل۔

## خصوصیات

- HTTPS لوگو سپورٹ اور سخت اسکیپنگ کے ساتھ حسبِ ضرورت HTML/CSS مینٹیننس صفحہ۔
- `CF-Connecting-IP` کے ذریعے IPv4/IPv6 CIDR الاؤ لسٹنگ اور ISO 3166-1 alpha-2 ریجن بائی پاس۔
- خودکار `Retry-After` ہیڈرز اور JSON اسٹیٹس اینڈ پوائنٹ کے ساتھ شیڈول کردہ RFC3339 مینٹیننس ونڈوز۔
- Workers KV کے ذریعے زیرو ڈاؤن ٹائم رن ٹائم ٹوگل اور اختیاری Slack/PagerDuty/ویب ہک اطلاعات۔
- RTL سپورٹ کے ساتھ 45 لوکیلز میں خودکار `Accept-Language` لوکلائزیشن۔

## بنیادی استعمال

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

## لوکلائزیشن

Worker میں 45 لوکیلز (20 ٹیئر 1، 15 افریقی، اور 10 ایشیائی لوکیلز) شامل ہیں اور یہ RFC 9110 `Accept-Language` کوالٹی ویلیوز کا استعمال کرتے ہوئے جوابات طے کرتا ہے، اور `Content-Language` اور `Vary: Accept-Language` سیٹ کرتا ہے۔ RTL لوکیلز (`ar`، `ar-EG`، `ar-MA`، `fa`، `he`، `ur`) `dir="rtl"` جاری کرتے ہیں۔ حسبِ ضرورت `maintenance_title`، `maintenance_message`، `pages`، اور KV اوور رائیڈز کو بعینہ محفوظ رکھا جاتا ہے۔

## ٹیسٹنگ اور لائسنس

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

تیار کردہ ان پٹ/آؤٹ پٹ جدولوں کے لیے مکمل [انگریزی README](../../../README.md) دیکھیں۔ [MIT](../../../LICENSE) کے تحت لائسنس یافتہ۔
