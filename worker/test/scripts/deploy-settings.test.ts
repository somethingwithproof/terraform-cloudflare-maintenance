// Tests of .github/scripts/deploy-settings.sh, which cd.yml and drift.yml
// run to turn a GitHub environment's settings into TF_VAR_ lines.

import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const script = fileURLToPath(new URL("../../../.github/scripts/deploy-settings.sh", import.meta.url));

const required = {
  TF_CLOUD_ORGANIZATION: "org",
  TF_TOKEN_app_terraform_io: "hcp-token",
  CLOUDFLARE_API_TOKEN: "cf-token",
  TF_VAR_cloudflare_account_id: "account",
  TF_VAR_cloudflare_zone_id: "zone",
  TF_VAR_worker_route: "example.com/*",
};

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "deploy-settings-"));
});

afterEach(() => {
  rmSync(dir, { recursive: true, force: true });
});

function resolve(env: Record<string, string>) {
  const githubEnv = join(dir, "env");
  const githubOutput = join(dir, "output");
  writeFileSync(githubEnv, "");
  writeFileSync(githubOutput, "");
  const result = spawnSync("bash", [script], {
    encoding: "utf8",
    env: { PATH: process.env.PATH ?? "", GITHUB_ENV: githubEnv, GITHUB_OUTPUT: githubOutput, ...env },
  });
  const vars = Object.fromEntries(
    readFileSync(githubEnv, "utf8")
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        const at = line.indexOf("=");
        return [line.slice(0, at), line.slice(at + 1)];
      }),
  ) as Record<string, string>;
  return { status: result.status, stdout: result.stdout, vars, output: readFileSync(githubOutput, "utf8") };
}

describe("deploy-settings.sh", () => {
  it("passes the environment's settings through as single-line TF_VAR_ values", () => {
    const result = resolve({
      ...required,
      ENV_ENABLED: "true",
      ENV_WINDOW: '{"start_time": "2030-01-01T00:00:00Z", "end_time": "2030-01-01T02:00:00Z", "extra": 1}',
      ENV_ALLOWED_IPS: '[\n  "2001:db8::/32",\n  "192.0.2.1"\n]',
      ENV_ALLOWED_REGIONS: '["US"]',
      ENV_CONTACT_EMAIL: "ops@example.com",
      ENV_RUNTIME_TOGGLE: "true",
    });
    expect(result.status).toBe(0);
    expect(result.vars).toEqual({
      TF_VAR_enabled: "true",
      TF_VAR_maintenance_window: '{"start_time":"2030-01-01T00:00:00Z","end_time":"2030-01-01T02:00:00Z"}',
      TF_VAR_allowed_ips: '["2001:db8::/32","192.0.2.1"]',
      TF_VAR_allowed_regions: '["US"]',
      TF_VAR_runtime_toggle: "true",
      TF_VAR_contact_email: "ops@example.com",
    });
    expect(result.output).toBe("ready=true\n");
  });

  it("defaults to maintenance off, no window and no toggle", () => {
    expect(resolve(required).vars).toEqual({ TF_VAR_enabled: "false", TF_VAR_runtime_toggle: "false" });
  });

  it("lets a dispatch override enabled and clear the window for one run", () => {
    const result = resolve({
      ...required,
      ENV_ENABLED: "true",
      ENV_WINDOW: '{"start_time": "a", "end_time": "b"}',
      INPUT_ENABLED: "false",
      INPUT_CLEAR_WINDOW: "true",
    });
    expect(result.vars.TF_VAR_enabled).toBe("false");
    expect(result.vars).not.toHaveProperty("TF_VAR_maintenance_window");
  });

  it("lets a dispatch replace the window", () => {
    const result = resolve({
      ...required,
      ENV_WINDOW: '{"start_time": "a", "end_time": "b"}',
      INPUT_WINDOW_START: "2030-01-01T00:00:00Z",
      INPUT_WINDOW_END: "2030-01-01T01:00:00+01:00",
    });
    expect(result.vars.TF_VAR_maintenance_window).toBe(
      '{"start_time":"2030-01-01T00:00:00Z","end_time":"2030-01-01T01:00:00+01:00"}',
    );
  });

  it.each([
    ["half a window override", { INPUT_WINDOW_START: "2030-01-01T00:00:00Z" }, "Set both window_start and window_end"],
    ["a non-RFC3339 override", { INPUT_WINDOW_START: "tomorrow", INPUT_WINDOW_END: "later" }, "RFC3339"],
    ["a window that is not an object", { ENV_WINDOW: '["a", "b"]' }, "MAINTENANCE_WINDOW must be"],
    ["an allowlist that is not an array", { ENV_ALLOWED_IPS: '"1.2.3.4"' }, "ALLOWED_IPS must be"],
    ["an allowlist with a non-string", { ENV_ALLOWED_REGIONS: '["US", 1]' }, "ALLOWED_REGIONS must be"],
    ["an enabled that is not a boolean", { ENV_ENABLED: "yes" }, "MAINTENANCE_ENABLED must be"],
    ["a toggle that is not a boolean", { ENV_RUNTIME_TOGGLE: "1" }, "RUNTIME_TOGGLE must be"],
    ["a multi-line contact", { ENV_CONTACT_EMAIL: "a@example.com\nTF_VAR_enabled=true" }, "CONTACT_EMAIL must be one line"],
  ])("rejects %s", (_name, env, message) => {
    const result = resolve({ ...required, ...env });
    expect(result.status).toBe(1);
    expect(result.stdout).toContain(message);
    expect(result.output).not.toContain("ready=true");
  });

  it("fails a deploy that is missing a required setting", () => {
    const result = resolve({ ...required, CLOUDFLARE_API_TOKEN: "" });
    expect(result.status).toBe(1);
    expect(result.stdout).toContain("missing: CLOUDFLARE_API_TOKEN");
    expect(result.vars).toEqual({});
  });

  it("skips a plan that is missing a required setting", () => {
    const result = resolve({ DEPLOY_SETTINGS_MODE: "plan" });
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("::notice::Skipped");
    expect(result.output).toBe("ready=false\n");
    expect(result.vars).toEqual({});
  });
});
