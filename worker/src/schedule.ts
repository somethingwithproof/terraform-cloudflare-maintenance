// Whether maintenance is on, from the enabled flag and the optional window.

export interface MaintenanceWindow {
  start: Date;
  end: Date;
}

/** The window from its RFC3339 bounds, or null if either is missing or invalid. */
export function parseWindow(start: string | undefined, end: string | undefined): MaintenanceWindow | null {
  if (!start || !end) return null;
  const window = { start: new Date(start), end: new Date(end) };
  if (Number.isNaN(window.start.getTime()) || Number.isNaN(window.end.getTime())) {
    return null;
  }
  return window;
}

export function isInWindow(window: MaintenanceWindow, now: Date): boolean {
  return now >= window.start && now < window.end;
}

/**
 * With a window the page is served only from its start (inclusive) to its
 * end (exclusive), whatever enabled says. Without one, enabled alone decides.
 */
export function isMaintenanceActive(enabled: boolean, window: MaintenanceWindow | null, now: Date): boolean {
  return window ? isInWindow(window, now) : enabled;
}

export const DEFAULT_RETRY_AFTER = 3600;

/**
 * Seconds until the window ends while inside one, otherwise the configured
 * value (default 3600). Never less than 1.
 */
export function retryAfterSeconds(window: MaintenanceWindow | null, configured: string | undefined, now: Date): number {
  if (window && isInWindow(window, now)) {
    return Math.max(1, Math.ceil((window.end.getTime() - now.getTime()) / 1000));
  }
  const value = Number.parseInt(configured ?? "", 10);
  return Number.isInteger(value) && value > 0 ? value : DEFAULT_RETRY_AFTER;
}

/** A JSON array binding; anything else counts as an empty list. */
export function parseJsonList(json: string | undefined): unknown[] {
  try {
    const list: unknown = JSON.parse(json ?? "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}
