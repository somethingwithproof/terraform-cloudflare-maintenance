> [English](../../../README.md)

# תחזוקת Cloudflare עם Terraform

[![רישיון](https://img.shields.io/github/license/thomasvincent/terraform-cloudflare-maintenance.svg)](../../../LICENSE)
[![גרסת OpenTofu](https://img.shields.io/badge/OpenTofu-%3E%3D1.6.0-blue)](../../../versions.tf)

פתרון מצב תחזוקה עבור יישומים המתארחים ב-Cloudflare, בנוי באמצעות OpenTofu/Terraform ו-Cloudflare Worker ב-TypeScript.

## תכונות

- דף תחזוקה מותאם אישית ב-HTML/CSS עם תמיכה בלוגו HTTPS וסימון בריחה (escaping) קפדני.
- רשימת היתר של כתובות IPv4/IPv6 CIDR באמצעות `CF-Connecting-IP` ועקיפה לפי אזור בתקן ISO 3166-1 alpha-2.
- חלונות תחזוקה מתוזמנים בפורמט RFC3339 עם כותרות `Retry-After` אוטומטיות ונקודת קצה לסטטוס בפורמט JSON.
- החלפת מצב בזמן ריצה ללא השבתה באמצעות Workers KV והתראות אופציונליות ל-Slack/PagerDuty/webhook.
- לוקליזציה אוטומטית לפי `Accept-Language` עבור 45 אזורי שפה עם תמיכה ב-RTL.

## שימוש בסיסי

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

## לוקליזציה

ה-Worker מאגד 45 אזורי שפה (20 אזורי Tier 1, 15 אזורים אפריקאיים ו-10 אזורים אסייתיים) ומנהל משא ומתן על תגובות באמצעות ערכי איכות של `Accept-Language` לפי תקן RFC 9110, תוך הגדרת `Content-Language` ו-`Vary: Accept-Language`. אזורי שפה הנכתבים מימין לשמאל (`ar`, `ar-EG`, `ar-MA`, `fa`, `he`, `ur`) מפיקים `dir="rtl"`. ערכים מותאמים אישית עבור `maintenance_title`, `maintenance_message`, `pages` ועקיפות KV נשמרים כלשונם.

## בדיקות ורישיון

```bash
tofu init -backend=false && tofu test
cd worker && npm ci --ignore-scripts && npm test && npm run typecheck && npm run lint
```

ראו את קובץ ה-[README המלא באנגלית](../../../README.md) לטבלאות קלט/פלט שנוצרו אוטומטית. מורשה תחת [MIT](../../../LICENSE).
