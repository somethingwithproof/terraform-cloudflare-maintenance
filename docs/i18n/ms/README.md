> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lesen](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Versi OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Penyelesaian mod penyelenggaraan untuk aplikasi yang dihoskan di Cloudflare yang dibina dengan OpenTofu/Terraform dan Cloudflare Worker TypeScript.

## Ciri-ciri

- Halaman penyelenggaraan HTML/CSS boleh suai dengan sokongan logo HTTPS dan pelepasan aksara yang ketat.
- Senarai dibenarkan CIDR IPv4/IPv6 melalui `CF-Connecting-IP` dan pintasan rantau ISO 3166-1 alpha-2.
- Tetingkap penyelenggaraan RFC3339 berjadual dengan pengepala `Retry-After` automatik dan titik hujung status JSON.
- Togol masa jalan tanpa masa henti melalui Workers KV dan pemberitahuan Slack/PagerDuty/webhook pilihan.
- Penyetempatan `Accept-Language` automatik merentasi 45 lokal dengan sokongan RTL.

## Penggunaan Asas

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

## Penyetempatan

Worker menghimpunkan 45 lokal (20 lokal Peringkat 1, 15 lokal Afrika, dan 10 lokal Asia) dan merundingkan respons menggunakan nilai kualiti `Accept-Language` RFC 9110, dengan menetapkan `Content-Language` dan `Vary: Accept-Language`. Lokal RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) mengeluarkan `dir="rtl"`. Pemboleh ubah suai `maintenance_title`, `maintenance_message`, `pages`, dan penggantian KV dikekalkan secara verbatim.

## Pengujian dan Lesen

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Lihat [README Bahasa Inggeris](../../../README.md) penuh untuk jadual input/output yang dijana. Dilesenkan di bawah [MIT](../../../LICENSE).
