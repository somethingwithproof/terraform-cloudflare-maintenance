> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licence](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Version OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Solution de mode maintenance pour les applications hébergées sur Cloudflare, construite avec OpenTofu/Terraform et un Cloudflare Worker en TypeScript.

## Fonctionnalités

- Page de maintenance HTML/CSS personnalisable avec prise en charge de logo HTTPS et échappement strict.
- Liste d'autorisation CIDR IPv4/IPv6 via `CF-Connecting-IP` et contournement par région ISO 3166-1 alpha-2.
- Fenêtres de maintenance planifiées au format RFC3339 avec en-têtes `Retry-After` automatiques et point de terminaison de statut JSON.
- Bascule à chaud sans interruption via Workers KV et notifications facultatives Slack/PagerDuty/webhook.
- Localisation automatique via `Accept-Language` pour 45 locales avec prise en charge RTL.

## Utilisation de base

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

## Localisation

Le Worker embarque 45 locales (20 de niveau 1, 15 africaines et 10 asiatiques) et négocie les réponses à l'aide des valeurs de qualité `Accept-Language` RFC 9110, en définissant `Content-Language` et `Vary: Accept-Language`. Les locales RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) produisent `dir="rtl"`. Les valeurs personnalisées de `maintenance_title`, `maintenance_message`, `pages` et les surcharges KV sont conservées à l'identique.

## Tests et licence

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Consultez le [README en anglais](../../../README.md) complet pour les tableaux d'entrées et de sorties générés. Sous licence [MIT](../../../LICENSE).
