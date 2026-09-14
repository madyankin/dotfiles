#!/usr/bin/env python3
"""Print a direct download URL for a workflow's .alfredworkflow, or nothing.

Two strategies, in order:
  1. the latest GitHub release's .alfredworkflow asset;
  2. a .alfredworkflow file committed in the default branch's tree.

(2) matters: several workflows ship the file in the repo instead of cutting
releases, and the release API returns 404 for them.

Takes a repo ("owner/name"), a URL to extract one from, or a direct link to a
.alfredworkflow (returned unchanged). Stdlib only; /usr/bin/python3 (3.9).
"""
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.github.com"


def get(url):
    req = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": "dotfiles-alfred-installer",
    })
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.load(r)
    except (urllib.error.HTTPError, urllib.error.URLError, ValueError):
        return None


def repo_from(s):
    if re.fullmatch(r"[\w.-]+/[\w.-]+", s):
        return s.rstrip("/")
    m = re.search(r"github\.com/([\w.-]+)/([\w.-]+)", s)
    if m:
        return "%s/%s" % (m.group(1), m.group(2).rstrip("/"))
    return None


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        return 1
    src = sys.argv[1].strip()

    if src.endswith(".alfredworkflow") and src.startswith("http"):
        print(src)
        return 0

    repo = repo_from(src)
    if not repo:
        return 1

    rel = get("%s/repos/%s/releases/latest" % (API, repo))
    if rel:
        for a in rel.get("assets") or []:
            if a.get("name", "").endswith(".alfredworkflow"):
                print(a["browser_download_url"])
                return 0

    tree = get("%s/repos/%s/git/trees/HEAD?recursive=1" % (API, repo))
    if tree:
        # Shallowest path wins: a top-level build is the shipped one, not a
        # copy buried in a test fixture or docs directory.
        hits = sorted((x.get("path", "") for x in tree.get("tree") or []
                       if x.get("path", "").endswith(".alfredworkflow")),
                      key=lambda p: (p.count("/"), len(p)))
        if hits:
            print("https://raw.githubusercontent.com/%s/HEAD/%s"
                  % (repo, urllib.parse.quote(hits[0])))
            return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
