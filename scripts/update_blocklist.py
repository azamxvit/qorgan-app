#!/usr/bin/env python3
"""Regenerate the bundled phishing blocklist seed.

The seed is what protects a fresh install before it has ever seen a network.
It is deliberately a snapshot: the app fetches a current list at runtime, and
this file only has to be better than nothing on day one.

Source: https://gitlab.com/malware-filter/phishing-filter (filters are
CC BY-SA 4.0, aggregating OpenPhish, IPThreat and PhishTank). The filtered
output written here is an adaptation and stays under CC BY-SA 4.0 — see
THIRD_PARTY_NOTICES.md.

Usage:
    python3 scripts/update_blocklist.py
    python3 scripts/update_blocklist.py --check   # fail if the asset is stale
"""

from __future__ import annotations

import argparse
import datetime
import pathlib
import re
import ssl
import sys
import urllib.request

FEED = "https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt"
ASSET = pathlib.Path("assets/blocklist/seed-hosts.txt")

# Brands and markers that make an entry relevant to a Kazakhstani phone. Only
# used for the report: the shipped seed is not narrowed to these, because a
# phishing host does not have to mention a bank to be sent by SMS.
KZ_MARKERS = re.compile(
    r"kaspi|halyk|homebank|jusan|forte|bankffin|ffin|otbasy|eubank|nurbank"
    r"|egov|kazakh|beeline|kcell|tele2|altel|\.kz$|kz-|-kz\.",
    re.IGNORECASE,
)

# Mirrors _hostOf in lib/data/services/blocklist_store.dart. An entry with one
# label would block an entire TLD.
MINIMUM_LABELS = 2


def _trust_store() -> ssl.SSLContext:
    """A verified context even where Python has no system CA bundle.

    A python.org install on macOS ships without one until the bundled
    `Install Certificates.command` is run, and silently disabling verification
    would be the wrong fix for a script whose whole job is fetching a security
    list.
    """
    try:
        import certifi
    except ImportError:
        return ssl.create_default_context()
    return ssl.create_default_context(cafile=certifi.where())


def fetch(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "qorgan-blocklist"})
    with urllib.request.urlopen(
        request, timeout=120, context=_trust_store()
    ) as response:
        return response.read().decode("utf-8", errors="replace")


def hosts_from(hostfile: str) -> list[str]:
    """Parses `0.0.0.0 host` lines, dropping anything that is not a domain."""
    found: set[str] = set()
    for line in hostfile.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        host = (parts[1] if len(parts) >= 2 else parts[0]).lower()
        if host in {"localhost", "localhost.localdomain"}:
            continue
        if "/" in host or ":" in host or "_" in host:
            continue
        if len(host.split(".")) < MINIMUM_LABELS:
            continue
        if not re.fullmatch(r"[a-z0-9.-]+", host):
            continue
        found.add(host)
    return sorted(found)


def render(hosts: list[str]) -> str:
    today = datetime.date.today().isoformat()
    relevant = [host for host in hosts if KZ_MARKERS.search(host)]
    header = [
        "# Qorgan phishing blocklist seed.",
        "#",
        "# Snapshot only. The app replaces this list from the network; this file",
        "# exists so a fresh install is useful before its first update.",
        "#",
        "# Source: https://gitlab.com/malware-filter/phishing-filter",
        "# Aggregates OpenPhish, IPThreat and PhishTank.",
        "# Data licence: CC BY-SA 4.0. This filtered adaptation keeps that licence.",
        f"# Snapshot taken: {today}",
        f"# Hosts: {len(hosts)} ({len(relevant)} naming a Kazakhstani brand or .kz)",
        "#",
        "# Regenerate with: python3 scripts/update_blocklist.py",
        "",
    ]
    return "\n".join(header + hosts) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero if the asset differs from the current feed",
    )
    args = parser.parse_args()

    hosts = hosts_from(fetch(FEED))
    if not hosts:
        print("feed returned no usable hosts, refusing to write", file=sys.stderr)
        return 1

    rendered = render(hosts)
    relevant = sum(1 for host in hosts if KZ_MARKERS.search(host))

    if args.check:
        if not ASSET.exists():
            print(f"{ASSET} is missing", file=sys.stderr)
            return 1
        # Compare hosts only: the header carries a date and would always differ.
        current = hosts_from(ASSET.read_text())
        if current != hosts:
            print(
                f"{ASSET} is stale: {len(current)} hosts on disk, "
                f"{len(hosts)} in the feed",
                file=sys.stderr,
            )
            return 1
        print(f"{ASSET} matches the feed ({len(hosts)} hosts)")
        return 0

    ASSET.parent.mkdir(parents=True, exist_ok=True)
    ASSET.write_text(rendered)
    print(
        f"wrote {ASSET}: {len(hosts)} hosts, {len(rendered) / 1024:.0f} KB, "
        f"{relevant} naming a Kazakhstani brand or .kz"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
