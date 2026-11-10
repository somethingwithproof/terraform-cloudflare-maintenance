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
  new URL("../../../modules/notifications/notify.sh", import.meta.url),
);

// Records curl's stdin config, arguments and request body, then succeeds,
// or fails when $STUB_DIR/fail exists. Bodies of every call are appended to
// $STUB_DIR/bodies, one JSON document per line.
const stubCurl = `#!/bin/sh
[ -e "$STUB_DIR/fail" ] && exit 22
cat > "$STUB_DIR/config"
printf '%s\\n' "$@" > "$STUB_DIR/args"
prev=
for arg in "$@"; do
  if [ "$prev" = "--data-binary" ]; then
    cp "\${arg#@}" "$STUB_DIR/body"
    jq -c . "\${arg#@}" >> "$STUB_DIR/bodies"
  fi
  prev=$arg
done
`;

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "notify-"));
  writeFileSync(join(dir, "curl"), stubCurl);
  chmodSync(join(dir, "curl"), 0o755);
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

/** The fields of the bodies notify.sh sends that these tests read. */
interface Body {
  text?: string;
  blocks?: unknown[];
  status?: string;
  schedule_name?: string;
  routing_key?: string;
  event_action?: string;
  dedup_key?: string;
  payload?: Record<string, unknown>;
}

interface Sent {
  status: number | null;
  stderr: string;
  config: string;
  args: string[];
  body: Body | null;
  bodies: Body[];
}

function notify(url: string, overrides: Record<string, string> = {}): Sent {
  const result = spawnSync("/bin/sh", [script], {
    encoding: "utf8",
    env: {
      PATH: `${dir}:${process.env.PATH ?? ""}`,
      STUB_DIR: dir,
      NOTIFY_URL: url,
      NOTIFY_STATUS: "ENABLED",
      NOTIFY_ACTION: "trigger",
      NOTIFY_SCHEDULE: "weekly",
      NOTIFY_ENVIRONMENT: "production",
      NOTIFY_START: "2030-04-06T08:00:00Z",
      NOTIFY_END: "2030-04-06T10:00:00Z",
      NOTIFY_DEDUP_KEY: "terraform-cloudflare-maintenance/production/weekly",
      ...overrides,
    },
  });
  const read = (name: string): string => {
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
    body: read("body") ? (JSON.parse(read("body")) as Body) : null,
    bodies: read("bodies")
      .split("\n")
      .filter(Boolean)
      .map((line) => JSON.parse(line) as Body),
  };
}

describe("notify.sh", () => {
  it("posts Slack messages to the hooks.slack.com webhook", () => {
    const sent = notify("slack://T000/B000/XXXX");
    expect(sent.status).toBe(0);
    expect(sent.config).toBe(
      'url = "https://hooks.slack.com/services/T000/B000/XXXX"\n',
    );
    expect(sent.body?.text).toBe("Maintenance ENABLED");
    expect(JSON.stringify(sent.body?.blocks)).toContain("weekly");
  });

  it("triggers a PagerDuty event with a dedup key", () => {
    const sent = notify("pagerduty://routing-key-123");
    expect(sent.status).toBe(0);
    expect(sent.config).toBe('url = "https://events.pagerduty.com/v2/enqueue"\n');
    expect(sent.body).toMatchObject({
      routing_key: "routing-key-123",
      event_action: "trigger",
      dedup_key: "terraform-cloudflare-maintenance/production/weekly",
      payload: { severity: "warning", custom_details: { status: "ENABLED" } },
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
      status: "ENABLED",
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
    expect(sent.body?.schedule_name).toBe(`"}' ; $(touch pwned) \``);
  });

  it("rejects unknown actions without calling curl", () => {
    const sent = notify("pagerduty://routing-key-123", { NOTIFY_ACTION: "page" });
    expect(sent.status).toBe(1);
    expect(sent.config).toBe("");
  });

  it("rejects unsupported schemes without calling curl", () => {
    const sent = notify("webhook://http://hooks.example.com/x");
    expect(sent.status).toBe(1);
    expect(sent.stderr).toContain("unsupported notification URL scheme");
    expect(sent.config).toBe("");
  });

  describe("scheduled windows", () => {
    const scheduled = { NOTIFY_STATUS: "SCHEDULED", NOTIFY_ACTION: "none" };

    it("send PagerDuty nothing", () => {
      const sent = notify("pagerduty://routing-key-123", scheduled);
      expect(sent.status).toBe(0);
      expect(sent.bodies).toEqual([]);
    });

    it("still inform Slack and webhooks", () => {
      expect(notify("slack://T000/B000/XXXX", scheduled).body?.text).toBe(
        "Maintenance SCHEDULED",
      );
      expect(
        notify("webhook://https://hooks.example.com/x", scheduled).body?.status,
      ).toBe("SCHEDULED");
    });
  });

  describe("incident handoff across a replacement", () => {
    const stateFile = () => join(dir, "state", "target.json");
    const record = (key: string, action: string) =>
      notify("pagerduty://ignored", {
        NOTIFY_MODE: "record",
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: key,
        NOTIFY_ACTION: action,
        NOTIFY_URL: "",
      });
    const oldKey = "terraform-cloudflare-maintenance/staging/weekly";
    const newKey = "terraform-cloudflare-maintenance/production/weekly";

    it("records only the key and action, without calling curl", () => {
      const recorded = record(oldKey, "trigger");
      expect(recorded.status).toBe(0);
      expect(recorded.bodies).toEqual([]);
      expect(JSON.parse(readFileSync(stateFile(), "utf8"))).toEqual({
        dedup_key: oldKey,
        action: "trigger",
      });
    });

    it("resolves the old incident when the key changes", () => {
      record(oldKey, "trigger");
      const sent = notify("pagerduty://routing-key-123", {
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: newKey,
      });
      expect(sent.status).toBe(0);
      expect(sent.bodies.map((b) => [b.event_action, b.dedup_key])).toEqual([
        ["resolve", oldKey],
        ["trigger", newKey],
      ]);
      expect(() => readFileSync(stateFile())).toThrow();
    });

    it("resolves the incident when maintenance becomes only scheduled", () => {
      record(newKey, "trigger");
      const sent = notify("pagerduty://routing-key-123", {
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: newKey,
        NOTIFY_STATUS: "SCHEDULED",
        NOTIFY_ACTION: "none",
      });
      expect(sent.bodies.map((b) => [b.event_action, b.dedup_key])).toEqual([
        ["resolve", newKey],
      ]);
    });

    it("keeps one incident when the key is unchanged", () => {
      record(newKey, "trigger");
      const sent = notify("pagerduty://routing-key-123", {
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: newKey,
        NOTIFY_STATUS: "ACTIVE",
      });
      expect(sent.bodies.map((b) => b.event_action)).toEqual(["trigger"]);
    });

    it("does not resolve an incident that was never triggered", () => {
      record(oldKey, "resolve");
      const sent = notify("pagerduty://routing-key-123", {
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: newKey,
      });
      expect(sent.bodies.map((b) => [b.event_action, b.dedup_key])).toEqual([
        ["trigger", newKey],
      ]);
    });

    it("keeps the record when delivery fails, so a retry still resolves", () => {
      record(oldKey, "trigger");
      writeFileSync(join(dir, "fail"), "");
      const sent = notify("pagerduty://routing-key-123", {
        NOTIFY_STATE_FILE: stateFile(),
        NOTIFY_DEDUP_KEY: newKey,
      });
      expect(sent.status).not.toBe(0);
      expect((JSON.parse(readFileSync(stateFile(), "utf8")) as Body).dedup_key).toBe(
        oldKey,
      );
    });
  });
});
