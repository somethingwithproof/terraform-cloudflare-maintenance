> [English](../../../README.md)

# Terraform Cloudflare నిర్వహణ

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform మరియు TypeScript Cloudflare Worker తో నిర్మించబడిన Cloudflare-హోస్ట్ అప్లికేషన్‌ల కోసం నిర్వహణ మోడ్ పరిష్కారం.

## విశిష్టతలు

- HTTPS లోగో మద్దతు మరియు కఠినమైన ఎస్కేపింగ్‌తో అనుకూలీకరించదగిన HTML/CSS నిర్వహణ పేజీ.
- `CF-Connecting-IP` ద్వారా IPv4/IPv6 CIDR అనుమతి జాబితా మరియు ISO 3166-1 alpha-2 ప్రాంతీయ బైపాస్.
- స్వయంచాలక `Retry-After` హెడర్లు మరియు JSON స్థితి ఎండ్‌పాయింట్‌తో షెడ్యూల్ చేయబడిన RFC3339 నిర్వహణ సమయాలు.
- Workers KV ద్వారా జీరో-డౌన్‌టైమ్ రన్‌టైమ్ టాగుల్ మరియు ఐచ్ఛిక Slack/PagerDuty/వెబ్‌హుక్ నోటిఫికేషన్‌లు.
- RTL మద్దతుతో 45 లోకేల్స్‌లో స్వయంచాలక `Accept-Language` స్థానికీకరణ.

## ప్రాథమిక వినియోగం

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

## స్థానికీకరణ

Worker 45 లోకేల్స్‌ను (20 టియర్ 1, 15 ఆఫ్రికన్, మరియు 10 ఆసియా లోకేల్స్) బండిల్ చేస్తుంది మరియు `Content-Language` మరియు `Vary: Accept-Language` లను సెట్ చేస్తూ RFC 9110 `Accept-Language` నాణ్యత విలువలను ఉపయోగించి ప్రతిస్పందనలను నిర్ధారిస్తుంది. RTL లోకేల్స్ (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` ను జారీ చేస్తాయి. అనుకూల `maintenance_title`, `maintenance_message`, `pages`, మరియు KV ఓవర్‌రైడ్‌లు యథాతథంగా ఉంచబడతాయి.

## పరీక్ష మరియు లైసెన్స్

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

రూపొందించబడిన ఇన్‌పుట్/అవుట్‌పుట్ పట్టికల కోసం పూర్తి [ఆంగ్ల README](../../../README.md) ను చూడండి. [MIT](../../../LICENSE) క్రింద లైసెన్స్ పొందింది.
