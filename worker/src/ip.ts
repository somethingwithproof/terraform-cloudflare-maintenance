// IPv4 and IPv6 allowlist matching. Addresses are compared numerically, so
// every IPv6 spelling of an address matches, and IPv4-mapped IPv6
// (::ffff:192.0.2.1) matches IPv4. The allowed_ips validation in
// variables.tf accepts the same grammar; tests/fixtures/allowed-ips.json
// holds the cases both are tested against.

export interface Address {
  version: 4 | 6;
  value: bigint;
  /** Written as IPv4-mapped IPv6 and converted to IPv4. */
  mapped: boolean;
}

export interface Network {
  version: 4 | 6;
  value: bigint;
  prefix: number;
}

/** True when ip matches an allowlist entry (an address or a CIDR range). */
export function isAllowedIp(ip: string | null | undefined, entries: readonly unknown[]): boolean {
  const addr = parseIp(ip);
  if (!addr) return false;
  return entries.some((entry) => {
    const net = parseCidr(entry);
    if (net?.version !== addr.version) return false;
    const shift = BigInt((net.version === 4 ? 32 : 128) - net.prefix);
    return addr.value >> shift === net.value >> shift;
  });
}

/**
 * Parses "address" or "address/prefix". An IPv4-mapped IPv6 network needs a
 * prefix of at least 96 and is converted to the equivalent IPv4 network.
 */
export function parseCidr(entry: unknown): Network | null {
  if (typeof entry !== "string") return null;
  const [text, prefixText, extra] = entry.trim().split("/");
  if (extra !== undefined) return null;
  const addr = parseIp(text);
  if (!addr) return null;
  const written = addr.mapped || addr.version === 6 ? 128 : 32;
  let prefix = written;
  if (prefixText !== undefined) {
    if (!/^\d{1,3}$/.test(prefixText)) return null;
    prefix = Number(prefixText);
  }
  if (prefix > written) return null;
  if (addr.mapped) {
    if (prefix < 96) return null;
    prefix -= 96;
  }
  return { version: addr.version, value: addr.value, prefix };
}

/** Parses an IPv4 or IPv6 address. */
export function parseIp(text: string | null | undefined): Address | null {
  if (typeof text !== "string") return null;
  const s = text.trim();
  if (!s.includes(":")) {
    const value = parseIPv4(s);
    return value === null ? null : { version: 4, value, mapped: false };
  }
  const value = parseIPv6(s);
  if (value === null) return null;
  if (value >> 32n === 0xffffn) {
    return { version: 4, value: value & 0xffffffffn, mapped: true };
  }
  return { version: 6, value, mapped: false };
}

function parseIPv4(s: string): bigint | null {
  const parts = s.split(".");
  if (parts.length !== 4) return null;
  let value = 0n;
  for (const part of parts) {
    // Reject leading zeros, which some parsers read as octal.
    if (!/^(0|[1-9]\d{0,2})$/.test(part) || Number(part) > 255) return null;
    value = (value << 8n) | BigInt(part);
  }
  return value;
}

function parseIPv6(s: string): bigint | null {
  let text = s;
  // Rewrite a trailing dotted IPv4 part (::ffff:192.0.2.1) as two hex groups.
  const lastColon = text.lastIndexOf(":");
  if (text.slice(lastColon + 1).includes(".")) {
    const v4 = parseIPv4(text.slice(lastColon + 1));
    if (v4 === null) return null;
    const high = (v4 >> 16n).toString(16);
    const low = (v4 & 0xffffn).toString(16);
    text = `${text.slice(0, lastColon + 1)}${high}:${low}`;
  }
  const halves = text.split("::");
  if (halves.length > 2) return null;
  const left = halves[0] ? halves[0].split(":") : [];
  const right = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
  const missing = 8 - left.length - right.length;
  if (halves.length === 1 ? missing !== 0 : missing < 1) return null;
  const zeros: string[] = Array.from({ length: halves.length === 2 ? missing : 0 }, () => "0");
  let value = 0n;
  for (const group of [...left, ...zeros, ...right]) {
    if (!/^[0-9a-f]{1,4}$/i.test(group)) return null;
    value = (value << 16n) | BigInt(Number.parseInt(group, 16));
  }
  return value;
}
