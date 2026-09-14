#!/usr/bin/env python3
"""Print installed monospace font FAMILY names, one per line.

typefaces[].family is the family name Ghostty, VS Code and Zed want. The
top-level _name in system_profiler's output is the font FILE name (e.g.
"SauceCodeProNFP-Light"), which is why the obvious version of this listed
useless per-face names.

Stdlib only; /usr/bin/python3 (3.9).
"""
import json
import re
import subprocess
import sys


def main():
    out = subprocess.run(["system_profiler", "-json", "SPFontsDataType"],
                         capture_output=True, text=True).stdout
    try:
        data = json.loads(out).get("SPFontsDataType", [])
    except Exception:
        return 1

    fams = set()
    for entry in data:
        for tf in entry.get("typefaces") or []:
            fam = (tf.get("family") or "").strip()
            if not fam or fam.startswith("."):
                continue
            # Monospace only. "Propo" is Nerd Fonts' own proportional variant,
            # which is not what a terminal wants.
            if re.search(r"mono", fam, re.I) and not re.search(r"propo", fam, re.I):
                fams.add(fam)

    for f in sorted(fams):
        print(f)
    return 0


if __name__ == "__main__":
    sys.exit(main())
