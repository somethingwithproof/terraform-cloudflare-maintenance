> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lisensi](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Versi OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Solusi mode pemeliharaan untuk aplikasi yang dihosting di Cloudflare, dibangun dengan OpenTofu/Terraform dan Cloudflare Worker TypeScript.

## Fitur

- Halaman pemeliharaan HTML/CSS yang dapat disesuaikan dengan dukungan logo HTTPS dan escaping ketat.
- Daftar izin CIDR IPv4/IPv6 melalui `CF-Connecting-IP` dan pengecualian wilayah ISO 3166-1 alpha-2.
- Jendela pemeliharaan terjadwal RFC3339 dengan header `Retry-After` otomatis dan titik akhir status JSON.
- Pengalihan runtime tanpa waktu henti melalui Workers KV serta notifikasi opsional ke Slack/PagerDuty/webhook.
- Pelokalan `Accept-Language` otomatis di 45 lokal dengan dukungan RTL.

## Penggunaan Dasar

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

## Pelokalan

Worker membundel 45 lokal (20 lokal Tier 1, 15 lokal Afrika, dan 10 lokal Asia) dan menegosiasikan respons menggunakan nilai kualitas `Accept-Language` RFC 9110, sambil mengatur `Content-Language` dan `Vary: Accept-Language`. Lokal RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) menghasilkan `dir="rtl"`. Pengaturan khusus `maintenance_title`, `maintenance_message`, `pages`, dan penimpaan KV dipertahankan apa adanya.

## Pengujian dan Lisensi

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Lihat [README bahasa Inggris](../../../README.md) lengkap untuk tabel input/output yang dihasilkan. Dilisensikan di bawah [MIT](../../../LICENSE).
