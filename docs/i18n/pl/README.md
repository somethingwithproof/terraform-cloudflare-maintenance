> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licencja](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Wersja OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Rozwiązanie trybu konserwacji dla aplikacji hostowanych w Cloudflare, zbudowane w oparciu o OpenTofu/Terraform oraz Cloudflare Worker napisany w TypeScript.

## Funkcje

- Konfigurowalna strona konserwacji HTML/CSS z obsługą logo przez HTTPS i ścisłym escapowaniem.
- Listy dozwolonych adresów CIDR IPv4/IPv6 na podstawie `CF-Connecting-IP` oraz pomijanie trybu konserwacji według kodu regionu ISO 3166-1 alpha-2.
- Zaplanowane okna konserwacji w formacie RFC3339 z automatycznymi nagłówkami `Retry-After` i punktem końcowym statusu JSON.
- Przełączanie w czasie rzeczywistym bez przestojów przez Workers KV oraz opcjonalne powiadomienia Slack/PagerDuty/webhook.
- Automatyczna lokalizacja na podstawie nagłówka `Accept-Language` dla 45 ustawień regionalnych z obsługą RTL.

## Podstawowe użycie

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

## Lokalizacja

Worker zawiera wbudowane 45 ustawień regionalnych (20 z grupy Tier 1, 15 afrykańskich i 10 azjatyckich) i negocjuje język odpowiedzi na podstawie wag jakości w nagłówku `Accept-Language` zgodnie z RFC 9110, ustawiając `Content-Language` oraz `Vary: Accept-Language`. Ustawienia regionalne RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) dodają atrybut `dir="rtl"`. Niestandardowe wartości `maintenance_title`, `maintenance_message`, `pages` oraz nadpisania w KV są zachowywane dosłownie.

## Testy i licencja

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Wygenerowane tabele zmiennych wejściowych i wyjściowych znajdują się w pełnej [angielskiej wersji README](../../../README.md). Udostępniono na licencji [MIT](../../../LICENSE).
