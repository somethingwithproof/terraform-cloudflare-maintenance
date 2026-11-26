> [English](../../../README.md)

# Terraform Cloudflare Maintenance

[![Licencia](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![Versión de OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

Solución de modo de mantenimiento para aplicaciones alojadas en Cloudflare, desarrollada con OpenTofu/Terraform y un Cloudflare Worker en TypeScript.

## Características

- Página de mantenimiento HTML/CSS personalizable con compatibilidad para logotipos HTTPS y escape estricto.
- Lista de permitidos CIDR IPv4/IPv6 mediante `CF-Connecting-IP` y omisión por región ISO 3166-1 alfa-2.
- Ventanas de mantenimiento programadas en formato RFC3339 con encabezados `Retry-After` automáticos y punto de conexión de estado JSON.
- Conmutación en tiempo de ejecución sin tiempo de inactividad mediante Workers KV y notificaciones opcionales a Slack, PagerDuty o webhooks.
- Localización automática mediante `Accept-Language` en 45 configuraciones regionales con compatibilidad RTL.

## Uso básico

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

## Localización

El Worker incluye 45 configuraciones regionales (20 de nivel 1, 15 africanas y 10 asiáticas) y negocia las respuestas mediante los valores de calidad de `Accept-Language` según RFC 9110, estableciendo `Content-Language` y `Vary: Accept-Language`. Las configuraciones regionales RTL (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) emiten `dir="rtl"`. Los valores personalizados de `maintenance_title`, `maintenance_message`, `pages` y las anulaciones de KV se conservan literalmente.

## Pruebas y licencia

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

Consulta el [README completo en inglés](../../../README.md) para ver las tablas de entrada y salida generadas. Publicado bajo la licencia [MIT](../../../LICENSE).
