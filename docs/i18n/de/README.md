> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Lizenz](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![OpenTofu-Version](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Wartungsmodus-Lösung für über Cloudflare gehostete Anwendungen auf Basis von OpenTofu/Terraform und einem TypeScript-Cloudflare-Worker.

## Funktionen

- Anpassbare HTML/CSS-Wartungsseite mit HTTPS-Logo-Unterstützung und striktem Escaping.
- IPv4/IPv6-CIDR-Allowlisting über `CF-Connecting-IP` sowie Regions-Bypass nach ISO 3166-1 Alpha-2.
- Geplante RFC3339-Wartungsfenster mit automatischen `Retry-After`-Headern und JSON-Status-Endpunkt.
- Umschaltung zur Laufzeit ohne Ausfallzeiten über Workers KV sowie optionale Slack-, PagerDuty- und Webhook-Benachrichtigungen.
- Automatische `Accept-Language`-Lokalisierung in 45 Locales mit RTL-Unterstützung.

## Grundlegende Verwendung

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

## Lokalisierung

Der Worker bündelt 45 Locales (20 Tier-1-, 15 afrikanische und 10 asiatische Locales) und handelt Antworten anhand der `Accept-Language`-Qualitätswerte gemäß RFC 9110 aus, wobei `Content-Language` und `Vary: Accept-Language` gesetzt werden. RTL-Locales (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) geben `dir="rtl"` aus. Benutzerdefinierte Werte für `maintenance_title`, `maintenance_message`, `pages` sowie KV-Überschreibungen bleiben unverändert erhalten.

## Tests und Lizenz

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Die generierten Eingabe- und Ausgabetabellen finden sich in der vollständigen [englischen README](../../../README.md). Lizenziert unter [MIT](../../../LICENSE).
