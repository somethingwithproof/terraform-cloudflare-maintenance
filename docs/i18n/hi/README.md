> [English](../../../README.md)

# Terraform Cloudflare रखरखाव

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform और TypeScript Cloudflare Worker के साथ निर्मित Cloudflare-होस्टेड अनुप्रयोगों के लिए रखरखाव मोड समाधान।

## विशेषताएँ

- HTTPS लोगो समर्थन और सख्त एस्केपिंग के साथ अनुकूलन योग्य HTML/CSS रखरखाव पृष्ठ।
- `CF-Connecting-IP` के माध्यम से IPv4/IPv6 CIDR अनुमति-सूची और ISO 3166-1 alpha-2 क्षेत्र बाईपास।
- स्वचालित `Retry-After` हेडर और JSON स्थिति एंडपॉइंट के साथ निर्धारित RFC3339 रखरखाव विंडो।
- Workers KV के माध्यम से शून्य-डाउनटाइम रनटाइम टॉगल और वैकल्पिक Slack/PagerDuty/वेबहुक सूचनाएँ।
- RTL समर्थन के साथ 45 लोकेल में स्वचालित `Accept-Language` स्थानीयकरण।

## बुनियादी उपयोग

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

## स्थानीयकरण

Worker 45 लोकेल (20 टियर 1, 15 अफ़्रीकी और 10 एशियाई लोकेल) बंडल करता है और `Content-Language` तथा `Vary: Accept-Language` सेट करते हुए RFC 9110 `Accept-Language` गुणवत्ता मानों का उपयोग करके प्रतिक्रियाएँ तय करता है। RTL लोकेल (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` उत्सर्जित करते हैं। कस्टम `maintenance_title`, `maintenance_message`, `pages` और KV ओवरराइड ज्यों के त्यों रखे जाते हैं।

## परीक्षण और लाइसेंस

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

उत्पन्न इनपुट/आउटपुट तालिकाओं के लिए पूर्ण [अंग्रेज़ी README](../../../README.md) देखें। [MIT](../../../LICENSE) के अंतर्गत लाइसेंस प्राप्त।
