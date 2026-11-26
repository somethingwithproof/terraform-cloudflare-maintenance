> [English](../../../README.md)

# Terraform Cloudflare देखभाल

[![परवाना](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu आवृत्ती](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform आणि TypeScript Cloudflare Worker वापरून तयार केलेल्या Cloudflare-होस्टेड अ‍ॅप्लिकेशन्ससाठी देखभाल मोड उपाय.

## वैशिष्ट्ये

- HTTPS लोगो समर्थन आणि कठोर एस्केपिंगसह सानुकूल करण्यायोग्य HTML/CSS देखभाल पृष्ठ.
- `CF-Connecting-IP` द्वारे IPv4/IPv6 CIDR अलाउलिस्टिंग आणि ISO 3166-1 alpha-2 प्रदेश बायपास.
- स्वयंचलित `Retry-After` हेडर्स आणि JSON स्थिती एंडपॉइंटसह नियोजित RFC3339 देखभाल कालावधी.
- Workers KV द्वारे झिरो-डाउनटाइम रनटाइम टॉगल आणि पर्यायी Slack/PagerDuty/वेबहुक सूचना.
- RTL समर्थनासह 45 लोकॅल्समध्ये स्वयंचलित `Accept-Language` स्थानिकीकरण.

## मूलभूत वापर

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

## स्थानिकीकरण

Worker मध्ये 45 लोकॅल्स (20 टियर 1, 15 आफ्रिकन आणि 10 आशियाई लोकॅल्स) समाविष्ट आहेत आणि तो RFC 9110 `Accept-Language` गुणवत्ता मूल्यांचा वापर करून प्रतिसाद निश्चित करतो, तसेच `Content-Language` आणि `Vary: Accept-Language` सेट करतो. RTL लोकॅल्स (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` उत्सर्जित करतात. सानुकूल `maintenance_title`, `maintenance_message`, `pages` आणि KV ओव्हरराइड्स जसेच्या तसे जतन केले जातात.

## चाचणी आणि परवाना

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

तयार केलेल्या इनपुट/आउटपुट सारण्यांसाठी संपूर्ण [इंग्रजी README](../../../README.md) पहा. [MIT](../../../LICENSE) अंतर्गत परवानाकृत.
