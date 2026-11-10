/**
 * Runs modules/notifications/notify.sh with a stub curl on PATH and checks
 * what it would send. Requires sh and jq, as the provisioner does.
 */

import { spawnSync } from "node:child_process";
import {
  chmodSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const script = fileURLToPath(
  new URL("../../modules/notifications/notify.sh", import.meta.url),
);

// Records curl's stdin config, arguments and request body, then succeeds.
const stubCurl = `#!/bin/sh
cat > "$STUB_DIR/config"
printf '%s\\n' "$@" > "$STUB_DIR/args"
prev=
for arg in "$@"; do
  if [ "$prev" = "--data-binary" ]; then cp "\${arg#@}" "$STUB_DIR/body"; fi
  prev=$arg
done
`;

let dir;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "notify-"));
  writeFileSync(join(dir, "curl"), stubCurl);
  chmodSync(join(dir, "curl"), 0o755);
});

afterEach(() => rmSync(dir, { recursive: true, force: true }));

function notify(url, overrides = {}) {
  const result = spawnSync("/bin/sh", [script], {
    encoding: "utf8",
    env: {
      PATH: `${dir}:${process.env.PATH}`,
      STUB_DIR: dir,
      NOTIFY_URL: url,
      NOTIFY_STATUS: "SCHEDULED",
      NOTIFY_ACTION: "trigger",
      NOTIFY_SCHEDULE: "weekly",
      NOTIFY_ENVIRONMENT: "production",
      NOTIFY_START: "2030-04-06T08:00:00Z",
      NOTIFY_END: "2030-04-06T10:00:00Z",
      NOTIFY_DEDUP_KEY: "terraform-cloudflare-maintenance/production/weekly",
      ...overrides,
    },
  });
  const read = (name) => {
    try {
      return readFileSync(join(dir, name), "utf8");
    } catch {
      return "";
    }
  };
  return {
    status: result.status,
    stderr: result.stderr,
    config: read("config"),
    args: read("args").split("\n"),
    body: read("body") ? JSON.parse(read("body")) : null,
  };
}

describe("notify.sh", () => {
  it("posts Slack messages to the hooks.slack.com webhook", () => {
    const sent = notify("slack://T000/B000/XXXX");
    expect(sent.status).toBe(0);
    expect(sent.config).toBe(
      'url = "https://hooks.slack.com/services/T000/B000/XXXX"\n',
    );
    expect(sent.body.text).toBe("Maintenance SCHEDULED");
    expect(JSON.stringify(sent.body.blocks)).toContain("weekly");
  });

  it("triggers a PagerDuty event with a dedup key", () => {
    const sent = notify("pagerduty://routing-key-123");
    expect(sent.status).toBe(0);
    expect(sent.config).toBe('url = "https://events.pagerduty.com/v2/enqueue"\n');
    expect(sent.body).toMatchObject({
      routing_key: "routing-key-123",
      event_action: "trigger",
      dedup_key: "terraform-cloudflare-maintenance/production/weekly",
      payload: { severity: "warning", custom_details: { status: "SCHEDULED" } },
    });
  });

  it("resolves the PagerDuty event with the same dedup key", () => {
    const sent = notify("pagerduty://routing-key-123", {
      NOTIFY_STATUS: "DISABLED",
      NOTIFY_ACTION: "resolve",
    });
    expect(sent.status).toBe(0);
    expect(sent.body).toEqual({
      routing_key: "routing-key-123",
      event_action: "resolve",
      dedup_key: "terraform-cloudflare-maintenance/production/weekly",
    });
  });

  it("posts the status to a generic HTTPS webhook", () => {
    const sent = notify("webhook://https://hooks.example.com/x");
    expect(sent.status).toBe(0);
    expect(sent.config).toBe('url = "https://hooks.example.com/x"\n');
    expect(sent.body).toEqual({
      status: "SCHEDULED",
      schedule_name: "weekly",
      environment: "production",
      maintenance_window: {
        start_time: "2030-04-06T08:00:00Z",
        end_time: "2030-04-06T10:00:00Z",
      },
    });
  });

  it("keeps the URL off curl's command line and bounds the request", () => {
    const sent = notify("slack://T000/B000/SECRET");
    expect(sent.args.join(" ")).not.toContain("SECRET");
    expect(sent.args).toEqual(
      expect.arrayContaining(["-fsS", "--max-time", "10", "--retry", "2"]),
    );
  });

  it("encodes status text as JSON instead of splicing it into the body", () => {
    const sent = notify("webhook://https://hooks.example.com/x", {
      NOTIFY_SCHEDULE: `"}' ; $(touch pwned) \``,
    });
    expect(sent.status).toBe(0);
    expect(sent.body.schedule_name).toBe(`"}' ; $(touch pwned) \``);
  });

  it("rejects unsupported schemes without calling curl", () => {
    const sent = notify("webhook://http://hooks.example.com/x");
    expect(sent.status).toBe(1);
    expect(sent.stderr).toContain("unsupported notification URL scheme");
    expect(sent.config).toBe("");
  });
});
