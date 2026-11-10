// The KV toggle against workerd's local KV, with the Worker's other
// bindings from wrangler.json.

import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { type Env, handleRequest } from "../../src/index";
import { cacheTtlSeconds, parseOverride, STATE_KEY } from "../../src/toggle";

const now = new Date("2030-04-06T09:00:00Z");

beforeEach(() => {
  vi.spyOn(globalThis, "fetch").mockImplementation(() => Promise.resolve(new Response("Origin response")));
});

afterEach(async () => {
  vi.restoreAllMocks();
  await env.MAINTENANCE_KV?.delete(STATE_KEY);
});

function setState(state: unknown): Promise<void> {
  const kv = env.MAINTENANCE_KV;
  if (!kv) throw new Error("wrangler.json should bind MAINTENANCE_KV");
  return kv.put(STATE_KEY, typeof state === "string" ? state : JSON.stringify(state));
}

async function serve(overrides: Partial<Env> = {}, path = "/"): Promise<Response> {
  return handleRequest(new Request(`https://example.com${path}`), { ...env, ...overrides }, now);
}

const failingKv = {
  get: () => Promise.reject(new Error("KV unavailable")),
} as unknown as KVNamespace;

describe("without an override", () => {
  it("uses the Terraform bindings", async () => {
    expect((await serve()).status).toBe(503);
    expect((await serve({ MAINTENANCE_ENABLED: "false" })).status).toBe(200);
  });
});

describe("with an override", () => {
  it("turns maintenance on and off over the bindings", async () => {
    await setState({ enabled: true });
    expect((await serve({ MAINTENANCE_ENABLED: "false" })).status).toBe(503);
    await setState({ enabled: false });
    expect((await serve({ MAINTENANCE_ENABLED: "true" })).status).toBe(200);
  });

  it("replaces the Terraform window, or removes it with null", async () => {
    const tfWindow = { MAINTENANCE_WINDOW_START: "2030-04-06T08:00:00Z", MAINTENANCE_WINDOW_END: "2030-04-06T10:00:00Z" };
    await setState({ window: { start_time: "2030-04-07T08:00:00Z", end_time: "2030-04-07T10:00:00Z" } });
    expect((await serve(tfWindow)).status).toBe(200);
    await setState({ window: null, enabled: false });
    expect((await serve(tfWindow)).status).toBe(200);
    await setState({ window: null, enabled: true });
    const response = await serve({ MAINTENANCE_ENABLED: "false", ...tfWindow });
    expect(response.status).toBe(503);
    expect(response.headers.get("Retry-After")).toBe("3600");
  });

  it("serves the page for on, outside a future Terraform window", async () => {
    // What scripts/maintenance on stores.
    await setState({ enabled: true, window: null });
    const response = await serve({
      MAINTENANCE_ENABLED: "false",
      MAINTENANCE_WINDOW_START: "2030-04-07T08:00:00Z",
      MAINTENANCE_WINDOW_END: "2030-04-07T10:00:00Z",
    });
    expect(response.status).toBe(503);
    expect(response.headers.get("Retry-After")).toBe("3600");
  });

  it("counts Retry-After down to the end of an override window", async () => {
    await setState({ window: { start_time: "2030-04-06T08:00:00Z", end_time: "2030-04-06T09:30:00Z" } });
    const response = await serve({ MAINTENANCE_ENABLED: "false" });
    expect(response.status).toBe(503);
    expect(response.headers.get("Retry-After")).toBe("1800");
  });

  it("sets the text on every page, pages included", async () => {
    await setState({ enabled: true, title: "Database failover", message: "Back in 10 minutes." });
    const pages = JSON.stringify([{ path_prefix: "/shop", title: "Shop closed" }]);
    const html = await (await serve({ PAGES: pages }, "/shop")).text();
    expect(html).toContain("<title>Database failover</title>");
    expect(html).toContain("<p>Back in 10 minutes.</p>");
  });

  it("keeps binding text for fields it leaves out", async () => {
    await setState({ enabled: true });
    expect(await (await serve()).text()).toContain("<title>Maintenance Mode</title>");
  });

  it("is what the status endpoint reports", async () => {
    await setState({ enabled: false });
    const response = await serve({}, "/__maintenance/status");
    expect(await response.json()).toEqual({ maintenance: false, window: null, retry_after_seconds: null });
  });
});

describe("when the toggle cannot be read", () => {
  // Terraform settings, from wrangler.json's MAINTENANCE_ENABLED=true default.
  const terraform = {
    enabled: { MAINTENANCE_ENABLED: "true" },
    "in its window": {
      MAINTENANCE_ENABLED: "false",
      MAINTENANCE_WINDOW_START: "2030-04-06T08:00:00Z",
      MAINTENANCE_WINDOW_END: "2030-04-06T10:00:00Z",
    },
    "off": { MAINTENANCE_ENABLED: "false" },
    "outside its window": {
      MAINTENANCE_ENABLED: "true",
      MAINTENANCE_WINDOW_START: "2030-04-07T08:00:00Z",
      MAINTENANCE_WINDOW_END: "2030-04-07T10:00:00Z",
    },
  } satisfies Record<string, Partial<Env>>;

  it.each([
    ["open", "enabled", 503],
    ["open", "in its window", 503],
    ["open", "off", 200],
    ["open", "outside its window", 200],
    ["closed", "enabled", 503],
    ["closed", "in its window", 503],
    ["closed", "off", 503],
    ["closed", "outside its window", 503],
  ] as const)("failing %s with Terraform %s answers %i", async (mode, settings, status) => {
    const bindings = { ...terraform[settings], KV_FAILURE_MODE: mode };
    expect((await serve({ ...bindings, MAINTENANCE_KV: failingKv })).status).toBe(status);
    // A malformed override is a failure too, not "no override".
    for (const state of ["not-json", '"on"', '{"enabled": "yes"}', '{"window": {"start_time": "x"}}', '{"title": 1}']) {
      await setState(state);
      expect((await serve(bindings)).status, state).toBe(status);
    }
  });

  it("defaults to failing open", async () => {
    const unset: Env = { ...env };
    delete unset.KV_FAILURE_MODE;
    const request = () => new Request("https://example.com/");
    const off = { ...unset, ...terraform.off, MAINTENANCE_KV: failingKv };
    expect((await handleRequest(request(), off, now)).status).toBe(200);
    const enabled = { ...unset, ...terraform.enabled, MAINTENANCE_KV: failingKv };
    expect((await handleRequest(request(), enabled, now)).status).toBe(503);
  });
});

describe("parseOverride", () => {
  it("accepts the fields scripts/maintenance writes", () => {
    expect(
      parseOverride({ enabled: true, window: null, title: "T", message: "M", updated_at: "2030-04-06T09:00:00Z" }),
    ).toEqual({ enabled: true, window: null, title: "T", message: "M" });
  });

  it("rejects a window that ends before it starts", () => {
    expect(parseOverride({ window: { start_time: "2030-04-06T10:00:00Z", end_time: "2030-04-06T08:00:00Z" } })).toBeNull();
  });

  it("rejects non-objects", () => {
    for (const value of [null, [], "x", 1, true]) expect(parseOverride(value)).toBeNull();
  });
});

describe("cacheTtlSeconds", () => {
  it("defaults to 60 and enforces KV's 30 second minimum", () => {
    expect(cacheTtlSeconds(undefined)).toBe(60);
    expect(cacheTtlSeconds("")).toBe(60);
    expect(cacheTtlSeconds("10")).toBe(60);
    expect(cacheTtlSeconds("1.5")).toBe(60);
    expect(cacheTtlSeconds("30")).toBe(30);
    expect(cacheTtlSeconds("300")).toBe(300);
  });
});
