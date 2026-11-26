> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licenza](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Versione OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Soluzione per la modalità di manutenzione destinata ad applicazioni ospitate su Cloudflare, realizzata con OpenTofu/Terraform e un Cloudflare Worker in TypeScript.

## Funzionalità

- Pagina di manutenzione HTML/CSS personalizzabile con supporto per logo HTTPS ed escaping rigoroso.
- Allowlist CIDR IPv4/IPv6 tramite `CF-Connecting-IP` ed esclusione per area geografica ISO 3166-1 alpha-2.
- Finestre di manutenzione pianificate secondo RFC3339 con intestazioni `Retry-After` automatiche ed endpoint di stato JSON.
- Attivazione e disattivazione a runtime senza interruzioni tramite Workers KV e notifiche opzionali su Slack/PagerDuty/webhook.
- Localizzazione automatica tramite `Accept-Language` in 45 localizzazioni con supporto RTL.

## Utilizzo di base

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

## Localizzazione

Il Worker include 45 localizzazioni (20 Tier 1, 15 africane e 10 asiatiche) e negozia le risposte utilizzando i valori di qualità `Accept-Language` secondo RFC 9110, impostando `Content-Language` e `Vary: Accept-Language`. Le localizzazioni RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) generano `dir="rtl"`. I valori personalizzati di `maintenance_title`, `maintenance_message`, `pages` e le sovrascritture KV vengono mantenuti testualmente.

## Test e licenza

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Consulta il [README completo in inglese](../../../README.md) per le tabelle generate di input/output. Rilasciato sotto licenza [MIT](../../../LICENSE).
