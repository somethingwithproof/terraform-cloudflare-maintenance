> [English](../../../README.md)

# Terraform Cloudflare பராமரிப்பு

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform மற்றும் TypeScript Cloudflare Worker கொண்டு உருவாக்கப்பட்ட Cloudflare இல் வழங்கப்படும் பயன்பாடுகளுக்கான பராமரிப்பு முறைத் தீர்வு.

## அம்சங்கள்

- HTTPS சின்ன ஆதரவு மற்றும் கடுமையான குறியீட்டுத் தப்பித்தல் கொண்ட தனிப்பயனாக்கக்கூடிய HTML/CSS பராமரிப்புப் பக்கம்.
- `CF-Connecting-IP` வழியாக IPv4/IPv6 CIDR அனுமதிப் பட்டியல் மற்றும் ISO 3166-1 alpha-2 பிராந்தியப் புறக்கணிப்பு.
- தானியங்கி `Retry-After` தலைப்புகள் மற்றும் JSON நிலை இறுதிமுனையுடன் திட்டமிடப்பட்ட RFC3339 பராமரிப்பு நேரங்கள்.
- Workers KV வழியாகப் பணிநிறுத்தமில்லாத இயக்க நேர நிலைமாற்றி மற்றும் விருப்பத்தேர்வு Slack/PagerDuty/webhook அறிவிப்புகள்.
- RTL ஆதரவுடன் 45 மொழியிடங்களில் தானியங்கி `Accept-Language` உள்ளூர்மயமாக்கல்.

## அடிப்படைப் பயன்பாடு

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

## உள்ளூர்மயமாக்கல்

Worker 45 மொழியிடங்களை (20 Tier 1, 15 ஆப்பிரிக்க மற்றும் 10 ஆசிய மொழியிடங்கள்) ஒருங்கிணைத்து, RFC 9110 `Accept-Language` தர மதிப்புகளைப் பயன்படுத்திப் பதில்களைத் தீர்மானித்து, `Content-Language` மற்றும் `Vary: Accept-Language` ஆகியவற்றை அமைக்கிறது. RTL மொழியிடங்கள் (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` ஐ வெளியிடுகின்றன. தனிப்பயன் `maintenance_title`, `maintenance_message`, `pages` மற்றும் KV மேலெழுதல்கள் மாற்றமின்றிப் பாதுகாக்கப்படுகின்றன.

## சோதனை மற்றும் உரிமம்

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

உருவாக்கப்பட்ட உள்ளீடு/வெளியீட்டு அட்டவணைகளுக்கு முழுமையான [ஆங்கில README](../../../README.md) ஐப் பார்க்கவும். [MIT](../../../LICENSE) உரிமத்தின் கீழ் வெளியிடப்பட்டது.
