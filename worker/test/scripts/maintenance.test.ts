// Tests of scripts/maintenance with a stub curl, so nothing reaches
// Cloudflare or a notification service.

import { spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const script = fileURLToPath(new URL("../../../scripts/maintenance", import.meta.url));

const account = "0123456789abcdef0123456789abcdef";
const namespace = "fedcba9876543210fedcba9876543210";
const kvUrl = `https://api.cloudflare.com/client/v4/accounts/${account}/storage/kv/namespaces/${namespace}/values/state`;

// Logs every call to $STUB_DIR/calls as one JSON line {method, url, config,
// body, argv}. Answers with the HTTP status in $STUB_DIR/code (default 200)
// and the body in $STUB_DIR/response, and fails like curl -f would for
// notification posts when $STUB_DIR/notify-fail exists.
const stubCurl = `#!/bin/sh
config=$(cat)
method=GET url= out= fmt= body=
while [ $# -gt 0 ]; do
  case "$1" in
  -X) method=$2; shift ;;
  -o) out=$2; shift ;;
  -w) fmt=$2; shift ;;
  --data-binary) body=$(cat "\${2#@}"); shift ;;
  -H | --max-time | --retry | --config) shift ;;
  -*) ;;
  *) url=$1 ;;
  esac
  shift
done
jq -cn --arg method "$method" --arg url "$url" --arg config "$config" --arg body "$body" \\
  '{method: $method, url: $url, config: $config, body: $body}' >> "$STUB_DIR/calls"
if [ -z "$url" ]; then
  [ -e "$STUB_DIR/notify-fail" ] && exit 22
  exit 0
fi
code=200
[ -e "$STUB_DIR/code" ] && code=$(cat "$STUB_DIR/code")
if [ -n "$out" ] && [ -e "$STUB_DIR/response" ]; then cp "$STUB_DIR/response" "$out"; fi
[ -n "$fmt" ] && printf '%s' "$code"
exit 0
`;

interface Call {
  method: string;
  url: string;
  config: string;
  body: string;
}

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "maintenance-"));
  writeFileSync(join(dir, "curl"), stubCurl);
  chmodSync(join(dir, "curl"), 0o755);
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

function run(args: string[], env: Record<string, string> = {}) {
  rmSync(join(dir, "calls"), { force: true });
  const result = spawnSync("bash", [script, ...args], {
    encoding: "utf8",
    env: {
      PATH: `${dir}:${process.env.PATH ?? ""}`,
      STUB_DIR: dir,
      CLOUDFLARE_API_TOKEN: "test-token",
      CF_ACCOUNT_ID: account,
      KV_NAMESPACE_ID: namespace,
      ...env,
    },
  });
  let calls: Call[] = [];
  try {
    calls = readFileSync(join(dir, "calls"), "utf8")
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line) as Call);
  } catch {
    // No calls.
  }
  const kv = calls.filter((call) => call.url === kvUrl);
  const notifications = calls.filter((call) => call.url === "");
  return { status: result.status, stdout: result.stdout, stderr: result.stderr, kv, notifications };
}

function stored(call: Call | undefined): Record<string, unknown> {
  expect(call?.method).toBe("PUT");
  return JSON.parse(call?.body ?? "null") as Record<string, unknown>;
}

describe("scripts/maintenance", () => {
  it("turns maintenance on with optional text", () => {
    const result = run(["on", "--title", "Failover", "--message", "Back soon"]);
    expect(result.status).toBe(0);
    expect(stored(result.kv[0])).toMatchObject({ enabled: true, title: "Failover", message: "Back soon" });
    expect(stored(result.kv[0]).updated_at).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
  });

  it("writes only the fields it is given", () => {
    expect(Object.keys(stored(run(["on"]).kv[0])).sort()).toEqual(["enabled", "updated_at", "window"]);
  });

  it("turns maintenance on outside a Terraform window", () => {
    // With a window the Worker ignores enabled, so on must remove it as off does.
    expect(stored(run(["on"]).kv[0])).toMatchObject({ enabled: true, window: null });
  });

  it("turns maintenance off over a Terraform window", () => {
    expect(stored(run(["off"]).kv[0])).toMatchObject({ enabled: false, window: null });
  });

  it("schedules a window", () => {
    const result = run(["schedule", "2030-04-06T08:00:00Z", "2030-04-06T10:00:00Z"]);
    expect(result.status).toBe(0);
    expect(stored(result.kv[0])).toMatchObject({
      window: { start_time: "2030-04-06T08:00:00Z", end_time: "2030-04-06T10:00:00Z" },
    });
  });

  it.each([
    ["an inverted window", ["2030-04-06T10:00:00Z", "2030-04-06T08:00:00Z"]],
    ["a non-UTC time", ["2030-04-06T08:00:00+02:00", "2030-04-06T10:00:00Z"]],
    ["a date only", ["2030-04-06", "2030-04-07"]],
  ])("rejects %s without writing", (_name, times) => {
    const result = run(["schedule", ...times]);
    expect(result.status).not.toBe(0);
    expect(result.kv).toEqual([]);
  });

  it("clears the override, also when there is none", () => {
    expect(run(["clear"]).kv[0]?.method).toBe("DELETE");
    writeFileSync(join(dir, "code"), "404");
    expect(run(["clear"]).status).toBe(0);
  });

  it("prints the stored override, or says there is none", () => {
    writeFileSync(join(dir, "response"), '{"enabled":true}');
    expect(run(["status"]).stdout).toContain('"enabled": true');
    writeFileSync(join(dir, "code"), "404");
    expect(run(["status"]).stdout).toContain("No override");
  });

  it("fails when Cloudflare refuses the write", () => {
    writeFileSync(join(dir, "code"), "403");
    writeFileSync(join(dir, "response"), '{"success":false,"errors":[{"code":10000,"message":"Authentication error"}]}');
    const result = run(["on"]);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("HTTP 403");
    expect(result.stderr).toContain("Authentication error");
  });

  it("keeps the token off curl's command line", () => {
    const call = run(["on"]).kv[0];
    expect(call?.config).toBe('header = "Authorization: Bearer test-token"');
  });

  it.each([
    ["CF_ACCOUNT_ID", "../../zones"],
    ["KV_NAMESPACE_ID", "abc"],
  ])("rejects a malformed %s before calling Cloudflare", (name, value) => {
    const result = run(["on"], { [name]: value });
    expect(result.status).not.toBe(0);
    expect(result.kv).toEqual([]);
  });

  it("rejects unknown commands and options", () => {
    expect(run(["toggle"]).status).toBe(2);
    expect(run(["on", "--colour", "red"]).status).toBe(2);
    expect(run(["off", "now"]).status).toBe(2);
  });

  describe("notifications", () => {
    const notify = { NOTIFY_URL: "pagerduty://routing-key", NOTIFY_ENVIRONMENT: "production" };
    const event = (call: Call | undefined) => JSON.parse(call?.body ?? "null") as Record<string, unknown>;

    it("send nothing without NOTIFY_URL", () => {
      expect(run(["on"]).notifications).toEqual([]);
    });

    it("trigger on, resolve on off and clear, under one dedup key", () => {
      const key = "terraform-cloudflare-maintenance/production/runtime-toggle";
      expect(event(run(["on"], notify).notifications[0])).toMatchObject({ event_action: "trigger", dedup_key: key });
      expect(event(run(["off"], notify).notifications[0])).toMatchObject({ event_action: "resolve", dedup_key: key });
      expect(event(run(["clear"], notify).notifications[0])).toMatchObject({ event_action: "resolve", dedup_key: key });
    });

    it("do not page for a scheduled window", () => {
      const result = run(["schedule", "2030-04-06T08:00:00Z", "2030-04-06T10:00:00Z"], notify);
      expect(result.status).toBe(0);
      expect(result.notifications).toEqual([]);
    });

    it("use NOTIFY_SCHEDULE in the dedup key", () => {
      const result = run(["on"], { ...notify, NOTIFY_SCHEDULE: "weekly" });
      expect(event(result.notifications[0]).dedup_key).toBe("terraform-cloudflare-maintenance/production/weekly");
    });

    it("are not sent when the toggle write fails", () => {
      writeFileSync(join(dir, "code"), "500");
      expect(run(["on"], notify).notifications).toEqual([]);
    });

    it("report a failed send without undoing the toggle", () => {
      writeFileSync(join(dir, "notify-fail"), "");
      const result = run(["on"], notify);
      expect(result.status).not.toBe(0);
      expect(result.stderr).toContain("the toggle was applied but the notification failed");
      expect(result.kv).toHaveLength(1);
    });
  });
});
