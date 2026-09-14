#!/usr/bin/env python3
"""Fetch one public HTTPS page with trafilatura and sanitize its output."""

from __future__ import annotations

import argparse
import ipaddress
import socket
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit


def validate_url(url: str) -> None:
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname:
        raise ValueError("only explicit https:// URLs are allowed")
    if parsed.username or parsed.password:
        raise ValueError("URLs containing credentials are not allowed")

    try:
        addresses = {
            ipaddress.ip_address(item[4][0])
            for item in socket.getaddrinfo(parsed.hostname, 443, type=socket.SOCK_STREAM)
        }
    except socket.gaierror as exc:
        raise ValueError(f"could not resolve host: {exc}") from exc

    for address in addresses:
        if not address.is_global:
            raise ValueError(f"host resolves to a non-public address: {address}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    try:
        validate_url(args.url)
    except ValueError as exc:
        parser.error(str(exc))

    command = ["trafilatura", "-u", args.url]
    if args.as_json:
        command.append("--json")

    extracted = subprocess.run(command, check=False, stdout=subprocess.PIPE)
    if extracted.returncode != 0:
        return extracted.returncode

    sanitized = subprocess.run(
        [sys.executable, str(Path(__file__).with_name("sanitize-web-content.py"))],
        input=extracted.stdout,
        check=False,
    )
    return sanitized.returncode


if __name__ == "__main__":
    raise SystemExit(main())
