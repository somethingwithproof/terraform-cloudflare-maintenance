> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

โซลูชันโหมดบำรุงรักษาสำหรับแอปพลิเคชันที่โฮสต์บน Cloudflare ซึ่งสร้างด้วย OpenTofu/Terraform และ Cloudflare Worker ที่เขียนด้วย TypeScript

## ความสามารถ

- หน้าเว็บแจ้งปิดปรับปรุงแบบ HTML/CSS ที่ปรับแต่งได้ รองรับโลโก้ผ่าน HTTPS และการหลีกอักขระพิเศษอย่างเข้มงวด
- การอนุญาตรายการ IPv4/IPv6 CIDR ผ่าน `CF-Connecting-IP` และการข้ามโหมดบำรุงรักษาตามภูมิภาคแบบ ISO 3166-1 alpha-2
- การกำหนดช่วงเวลาบำรุงรักษาตามมาตรฐาน RFC3339 พร้อมส่วนหัว `Retry-After` อัตโนมัติและจุดเชื่อมต่อสถานะแบบ JSON
- การเปิดปิดโหมดขณะทำงานแบบไม่หยุดชะงักผ่าน Workers KV พร้อมการแจ้งเตือนเสริมไปยัง Slack, PagerDuty หรือเว็บฮุก
- การเลือกภาษาท้องถิ่นอัตโนมัติตาม `Accept-Language` ครอบคลุม 45 ภาษาท้องถิ่นพร้อมรองรับการแสดงผลแบบขวาไปซ้าย (RTL)

## การใช้งานเบื้องต้น

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

## การรองรับภาษาท้องถิ่น

Worker รวมชุดคำแปล 45 ภาษาท้องถิ่น (ภาษาท้องถิ่นระดับ Tier 1 จำนวน 20 ภาษา แอฟริกา 15 ภาษา และเอเชีย 10 ภาษา) และเจรจาเลือกภาษาตอบกลับโดยใช้ค่าคุณภาพของ `Accept-Language` ตามมาตรฐาน RFC 9110 พร้อมตั้งค่าส่วนหัว `Content-Language` และ `Vary: Accept-Language` ภาษาท้องถิ่นแบบขวาไปซ้าย (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) จะส่งออก `dir="rtl"` ส่วนค่า `maintenance_title`, `maintenance_message`, `pages` และค่าทับจาก KV ที่กำหนดเองจะถูกรักษาไว้ตามเดิมทุกประการ

## การทดสอบและสัญญาอนุญาต

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

ดูตารางอินพุตและเอาต์พุตที่สร้างขึ้นได้ที่ [README ภาษาอังกฤษ](../../../README.md) ฉบับเต็ม อนุญาตให้ใช้งานภายใต้สัญญาอนุญาต [MIT](../../../LICENSE)
