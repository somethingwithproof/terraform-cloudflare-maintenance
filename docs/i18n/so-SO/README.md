> [English](../../../README.md)

# Dayactirka Terraform Cloudflare

[![Shatiga](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Nooca OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Xalka habka dayactirka ee codsiyada lagu martigeliyo Cloudflare oo lagu dhisay OpenTofu/Terraform iyo TypeScript Cloudflare Worker.

## Astaamaha

- Bogga dayactirka ee HTML/CSS oo la habeyn karo oo leh taageerada astaanta HTTPS iyo ka-baxsanaan adag.
- Liiska oggolaanshaha IPv4/IPv6 CIDR iyadoo la adeegsanayo `CF-Connecting-IP` iyo ka-gudubka gobolka ee ISO 3166-1 alpha-2.
- Daaqadaha dayactirka ee RFC3339 ee qorshaysan oo leh madaxyada `Retry-After` ee tooska ah iyo barta xaaladda JSON.
- Beddelka waqtiga-shaqada ee aan lahayn joogsi iyadoo loo marayo Workers KV iyo ogeysiisyada ikhtiyaariga ah ee Slack/PagerDuty/webhook.
- Deegaameynta tooska ah ee `Accept-Language` guud ahaan 45 deegaan oo leh taageerada RTL.

## Isticmaalka Aasaasiga ah

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

## Deegaameynta

Worker-ku wuxuu xirmo ahaan u sitaa 45 deegaan (20 Heerka 1-aad, 15 Afrikaan, iyo 10 Aasiyaan ah) wuxuuna ka gorgortamaa jawaabaha isagoo adeegsanaya qiimaha tayada ee RFC 9110 `Accept-Language`, isagoo dejinaya `Content-Language` iyo `Vary: Accept-Language`. Deegaannada RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) waxay soo saaraan `dir="rtl"`. Qiimayaasha gaarka ah ee `maintenance_title`, `maintenance_message`, `pages`, iyo ka-dhaafitaannada KV sidooda ayaa loo ilaaliyaa.

## Tijaabinta iyo Shatiga

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Eeg [README-ga Ingiriisiga](../../../README.md) oo dhammaystiran si aad u hesho shaxda gelinta/soo-saarka ee la soo saaray. Waxaa lagu shatiyeeyay [MIT](../../../LICENSE).
