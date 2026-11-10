// The runtime toggle: an optional override read from Workers KV, written by
// scripts/maintenance. Terraform's bindings are the defaults; any field the
// override sets replaces them until the override is cleared.

import { type MaintenanceWindow, parseWindow } from "./schedule";

/** The KV key scripts/maintenance writes. */
export const STATE_KEY = "state";

/** Fields of the override; a field that is absent keeps the binding's value. */
export interface Override {
  enabled?: boolean;
  /** null removes the Terraform window. */
  window?: MaintenanceWindow | null;
  title?: string;
  message?: string;
}

export type ToggleResult = { kind: "none" } | { kind: "override"; override: Override } | { kind: "error" };

/**
 * Validates the stored JSON. Anything malformed is an error, not "no
 * override", so a bad write follows the configured failure mode instead of
 * silently reverting to the Terraform defaults.
 */
export function parseOverride(value: unknown): Override | null {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return null;
  const raw = value as Record<string, unknown>;
  const override: Override = {};

  if ("enabled" in raw) {
    if (typeof raw.enabled !== "boolean") return null;
    override.enabled = raw.enabled;
  }
  if ("window" in raw) {
    if (raw.window === null) {
      override.window = null;
    } else {
      const w = raw.window as Record<string, unknown> | undefined;
      const start = typeof w?.start_time === "string" ? w.start_time : undefined;
      const end = typeof w?.end_time === "string" ? w.end_time : undefined;
      const window = parseWindow(start, end);
      if (!window || window.end <= window.start) return null;
      override.window = window;
    }
  }
  for (const field of ["title", "message"] as const) {
    if (field in raw) {
      const text = raw[field];
      if (typeof text !== "string") return null;
      override[field] = text;
    }
  }
  return override;
}

/** Reads the override, caching it at the edge for cacheTtl seconds. */
export async function readOverride(kv: KVNamespace, cacheTtl: number): Promise<ToggleResult> {
  let value: unknown;
  try {
    value = await kv.get(STATE_KEY, { type: "json", cacheTtl });
  } catch {
    return { kind: "error" };
  }
  if (value === null) return { kind: "none" };
  const override = parseOverride(value);
  return override ? { kind: "override", override } : { kind: "error" };
}

/** KV's minimum edge cache time is 30 seconds; default to 60. */
export function cacheTtlSeconds(configured: string | undefined): number {
  const value = Number(configured);
  return Number.isInteger(value) && value >= 30 ? value : 60;
}
