> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform এবং একটি TypeScript Cloudflare Worker দিয়ে তৈরি Cloudflare-হোস্টেড অ্যাপ্লিকেশনের জন্য রক্ষণাবেক্ষণ মোড সমাধান।

## বৈশিষ্ট্যসমূহ

- HTTPS লোগো সমর্থন এবং কঠোর এস্কেপিংসহ কাস্টমাইজযোগ্য HTML/CSS রক্ষণাবেক্ষণ পৃষ্ঠা।
- `CF-Connecting-IP`-এর মাধ্যমে IPv4/IPv6 CIDR অনুমোদিত তালিকাভুক্তি এবং ISO 3166-1 alpha-2 অঞ্চল বাইপাস।
- স্বয়ংক্রিয় `Retry-After` হেডার এবং JSON স্ট্যাটাস এন্ডপয়েন্টসহ নির্ধারিত RFC3339 রক্ষণাবেক্ষণ সময়সীমা।
- Workers KV-এর মাধ্যমে শূন্য-ডাউনটাইম রানটাইম টগল এবং ঐচ্ছিক Slack/PagerDuty/ওয়েবহুক বিজ্ঞপ্তি।
- RTL সমর্থনসহ ৪৫টি লোকেল জুড়ে স্বয়ংক্রিয় `Accept-Language` স্থানীয়করণ।

## মৌলিক ব্যবহার

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

## স্থানীয়করণ

Workerটি ৪৫টি লোকেল (২০টি Tier 1, ১৫টি আফ্রিকান এবং ১০টি এশীয় লোকেল) বান্ডেল করে এবং RFC 9110 `Accept-Language` মানের ওপর ভিত্তি করে রেসপন্স নির্ধারণ করে ও `Content-Language` এবং `Vary: Accept-Language` সেট করে। RTL লোকেলগুলো (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` নির্গত করে। কাস্টম `maintenance_title`, `maintenance_message`, `pages` এবং KV ওভাররাইডগুলো হুবহু সংরক্ষিত থাকে।

## পরীক্ষা ও লাইসেন্স

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

উৎপন্ন ইনপুট/আউটপুট টেবিলের জন্য সম্পূর্ণ [ইংরেজি README](../../../README.md) দেখুন। [MIT](../../../LICENSE) লাইসেন্সের অধীনে লাইসেন্সকৃত।
