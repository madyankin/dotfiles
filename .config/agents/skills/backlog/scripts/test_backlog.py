#!/usr/bin/env python3
"""Tests for backlog.py. Run: python3 -I test_backlog.py"""
import io
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import backlog  # noqa: E402

TODAY = date.today().isoformat()


class BacklogTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.home, self.repo = base / "home", base / "work" / "app"
        self.home.mkdir()
        self.repo.mkdir(parents=True)
        self.saved = os.environ.get("HOME"), os.getcwd()
        os.environ["HOME"] = str(self.home)
        os.chdir(self.repo)

    def tearDown(self):
        os.environ["HOME"], cwd = self.saved
        os.chdir(cwd)
        self.tmp.cleanup()

    def git(self, *args):
        subprocess.run(["git", *args], check=True, capture_output=True)

    def run_cli(self, *argv):
        out = io.StringIO()
        with redirect_stdout(out):
            backlog.main(list(argv))
        return out.getvalue()

    def file(self, slug):
        return self.home / ".config" / "agents" / "backlog" / f"{slug}.md"

    def test_slug_fallbacks(self):
        self.assertEqual(backlog.repo_identity(), ("_global", "no repo"))
        self.git("init", "-q", "-b", "main")
        self.assertEqual(backlog.repo_identity(), ("app", "app"))
        self.git("remote", "add", "origin", "git@github.com:acme/widgets.git")
        self.assertEqual(backlog.repo_identity(), ("acme-widgets", "acme/widgets"))
        self.git("remote", "set-url", "origin", "https://github.com/acme/widgets")
        self.assertEqual(backlog.repo_identity(), ("acme-widgets", "acme/widgets"))

    def test_add_bump_list_done_drop(self):
        self.git("init", "-q", "-b", "feature/x")
        self.git("remote", "add", "origin", "git@github.com:acme/widgets.git")
        self.assertIn("added #1", self.run_cli("add", "N+1 in Foo#bars", "--where", "app/foo.rb:42"))
        self.assertIn("bumped #1 (seen 2×)", self.run_cli("add", "n+1 in  foo#bars", "--where", "app/foo.rb:42"))
        self.assertIn("added #2", self.run_cli("add", "N+1 in Foo#bars", "--where", "app/other.rb:1"))
        self.run_cli("add", "stale README badge")

        text = self.file("acme-widgets").read_text()
        self.assertTrue(text.startswith("# Backlog — acme/widgets\n\n## Open\n"))
        self.assertIn(f"- [ ] {TODAY} · feature/x · `app/foo.rb:42` — N+1 in Foo#bars (seen 2×)", text)

        listing = self.run_cli("list")
        self.assertIn("3. ", listing)
        self.assertIn("stale README badge", listing)

        self.assertIn("done #1", self.run_cli("done", "1", "--note", "fixed in fix/foo"))
        self.assertIn("drop #2", self.run_cli("drop", "2"))
        bl = backlog.Backlog(self.file("acme-widgets"), "")
        self.assertEqual(len(bl.open), 1)
        self.assertEqual(bl.done[0], f"- [~] {TODAY} → {TODAY} · feature/x — stale README badge — drop")
        self.assertEqual(bl.done[1], f"- [x] {TODAY} → {TODAY} · feature/x · `app/foo.rb:42` — N+1 in Foo#bars — done: fixed in fix/foo")

    def test_slug_override_and_list_all(self):
        self.run_cli("--slug", "_skills", "add", "dev-plan: agent did X, user wanted Y")
        self.run_cli("add", "outside any repo")
        self.assertTrue(self.file("_skills").exists())
        self.assertTrue(self.file("_global").exists())
        listing = self.run_cli("list", "--all")
        self.assertIn("## _skills (_skills, 1 open)", listing)
        self.assertIn("## no repo (_global, 1 open)", listing)

    def test_bad_index_exits(self):
        self.run_cli("add", "one")
        with self.assertRaises(SystemExit):
            self.run_cli("done", "5")


if __name__ == "__main__":
    unittest.main()
