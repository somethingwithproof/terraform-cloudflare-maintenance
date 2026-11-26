> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![ፈቃድ](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![የOpenTofu ስሪት](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

በOpenTofu/Terraform እና በTypeScript Cloudflare Worker የተገነባ በCloudflare ለሚስተናገዱ መተግበሪያዎች የጥገና ሁነታ መፍትሔ።

## ባህሪያት

- የHTTPS አርማ ድጋፍ እና ጥብቅ ማምለጫ ያለው ሊበጅ የሚችል የHTML/CSS የጥገና ገጽ።
- በ`CF-Connecting-IP` በኩል የIPv4/IPv6 CIDR ፈቃድ ዝርዝር እና የISO 3166-1 alpha-2 ክልል ማለፊያ።
- ራስ-ሰር `Retry-After` ራስጌዎች እና የJSON ሁኔታ መጨረሻ ነጥብ ያላቸው የታቀዱ የRFC3339 የጥገና መስኮቶች።
- በWorkers KV በኩል ያለ መቋረጥ የአሂድ ጊዜ መቀየሪያ እና አማራጭ የSlack/PagerDuty/webhook ማሳወቂያዎች።
- ከRTL ድጋፍ ጋር በ45 አካባቢዎች ላይ ራስ-ሰር የ`Accept-Language` አካባቢያዊ ትርጉም።

## መሠረታዊ አጠቃቀም

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

## አካባቢያዊ ትርጉም

ይህ Worker 45 አካባቢዎችን (20 ደረጃ 1፣ 15 የአፍሪካ እና 10 የእስያ አካባቢዎች) ያጠቃልላል እና የRFC 9110 `Accept-Language` የጥራት እሴቶችን በመጠቀም ምላሾችን ይደራደራል፣ `Content-Language` እና `Vary: Accept-Language` ያዘጋጃል። የRTL አካባቢዎች (`ar`፣ `ar-EG`፣ `ar-MA`፣ `fa`፣ `he`፣ `ur`) `dir="rtl"` ያወጣሉ። ብጁ `maintenance_title`፣ `maintenance_message`፣ `pages` እና የKV ሽረቶች ቃል በቃል ይጠበቃሉ።

## ሙከራ እና ፈቃድ

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

ለተመነጩ የግብዓት/ውጤት ሰንጠረዦች ሙሉውን [የእንግሊዝኛ README](../../../README.md) ይመልከቱ። በ[MIT](../../../LICENSE) ፈቃድ የተሰጠ።
