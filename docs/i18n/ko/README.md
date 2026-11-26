> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![License](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

OpenTofu/Terraform과 TypeScript Cloudflare Worker로 구축된 Cloudflare 호스팅 애플리케이션용 유지보수 모드 솔루션입니다.

## 주요 기능

- HTTPS 로고 지원 및 엄격한 이스케이프 처리를 갖춘 사용자 정의 가능한 HTML/CSS 유지보수 페이지를 제공합니다.
- `CF-Connecting-IP`를 통한 IPv4/IPv6 CIDR 허용 목록 지정 및 ISO 3166-1 alpha-2 지역 우회를 지원합니다.
- 자동 `Retry-After` 헤더와 JSON 상태 엔드포인트를 포함한 예약된 RFC3339 유지보수 기간을 지원합니다.
- Workers KV를 통한 무중단 런타임 전환과 선택적 Slack/PagerDuty/웹훅 알림을 제공합니다.
- RTL을 지원하는 45개 로캘에 걸쳐 자동 `Accept-Language` 현지화를 제공합니다.

## 기본 사용법

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

## 현지화

Worker는 45개 로캘(Tier 1 20개, 아프리카 15개, 아시아 10개)을 번들로 포함하며, RFC 9110 `Accept-Language` 품질 값을 사용해 응답을 협상하고 `Content-Language` 및 `Vary: Accept-Language`를 설정합니다. RTL 로캘(`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`)은 `dir="rtl"`을 출력합니다. 사용자 정의 `maintenance_title`, `maintenance_message`, `pages` 및 KV 재정의 값은 그대로 보존됩니다.

## 테스트 및 라이선스

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

생성된 입력/출력 테이블은 전체 [영문 README](../../../README.md)를 참조하세요. [MIT](../../../LICENSE)에 따라 라이선스가 부여됩니다.
