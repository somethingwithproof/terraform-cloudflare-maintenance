> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lisans](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Sürümü](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform ve TypeScript tabanlı bir Cloudflare Worker ile oluşturulmuş, Cloudflare üzerinde barındırılan uygulamalar için bakım modu çözümü.

## Özellikler

- HTTPS logo desteği ve sıkı kaçış (escaping) korumasına sahip özelleştirilebilir HTML/CSS bakım sayfası.
- `CF-Connecting-IP` üzerinden IPv4/IPv6 CIDR izin listesi ve ISO 3166-1 alpha-2 bölge atlama (bypass) desteği.
- Otomatik `Retry-After` üstbilgileri ve JSON durum uç noktası ile zamanlanmış RFC3339 bakım pencereleri.
- Workers KV aracılığıyla kesintisiz çalışma zamanı anahtarlama ve isteğe bağlı Slack/PagerDuty/webhook bildirimleri.
- RTL desteği ile 45 yerel ayar genelinde otomatik `Accept-Language` yerelleştirmesi.

## Temel Kullanım

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

## Yerelleştirme

Worker, 45 yerel ayarı (20 Tier 1, 15 Afrika ve 10 Asya yerel ayarı) paketler ve RFC 9110 `Accept-Language` kalite değerlerini kullanarak yanıtları uzlaştırır; `Content-Language` ve `Vary: Accept-Language` üstbilgilerini ayarlar. RTL yerel ayarları (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) `dir="rtl"` çıktısı üretir. Özel `maintenance_title`, `maintenance_message`, `pages` ve KV geçersiz kılmaları birebir korunur.

## Testler ve Lisans

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Oluşturulan girdi/çıktı tabloları için tam [İngilizce README](../../../README.md) dosyasına bakın. [MIT](../../../LICENSE) altında lisanslanmıştır.
