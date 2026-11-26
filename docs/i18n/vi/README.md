> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Giải pháp chế độ bảo trì cho các ứng dụng lưu trữ trên Cloudflare, được xây dựng bằng OpenTofu/Terraform và Cloudflare Worker viết bằng TypeScript.

## Tính năng

- Trang bảo trì HTML/CSS có thể tùy chỉnh với hỗ trợ logo HTTPS và thoát ký tự nghiêm ngặt.
- Danh sách cho phép IPv4/IPv6 CIDR thông qua `CF-Connecting-IP` và bỏ qua theo mã vùng ISO 3166-1 alpha-2.
- Khung thời gian bảo trì theo lịch định dạng RFC3339 kèm tiêu đề `Retry-After` tự động và điểm cuối trạng thái JSON.
- Bật/tắt tại thời điểm chạy không gián đoạn qua Workers KV và tùy chọn gửi thông báo tới Slack/PagerDuty/webhook.
- Bản địa hóa tự động qua `Accept-Language` trên 45 ngôn ngữ địa phương với hỗ trợ RTL.

## Cách dùng cơ bản

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

## Bản địa hóa

Worker đóng gói 45 ngôn ngữ địa phương (20 ngôn ngữ Bậc 1, 15 ngôn ngữ châu Phi và 10 ngôn ngữ châu Á) và thương lượng phản hồi bằng các giá trị chất lượng `Accept-Language` theo chuẩn RFC 9110, thiết lập `Content-Language` và `Vary: Accept-Language`. Các ngôn ngữ RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) xuất ra `dir="rtl"`. Các giá trị tùy chỉnh `maintenance_title`, `maintenance_message`, `pages` và các phần ghi đè trong KV được giữ nguyên văn.

## Kiểm thử và Giấy phép

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Xem đầy đủ [README tiếng Anh](../../../README.md) để xem các bảng đầu vào/đầu ra được tạo tự động. Phát hành theo giấy phép [MIT](../../../LICENSE).
