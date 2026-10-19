#!/usr/bin/env python3
"""Tests for skill_runs.py on synthetic transcripts. Run: python3 -I test_skill_runs.py"""
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import skill_runs  # noqa: E402

TS = "2026-10-01T10:00:{:02d}.000Z"


def line(n, **kw):
    return {"timestamp": TS.format(n), "sessionId": "s1", "cwd": "/repo/app", **kw}


def user(n, content, **kw):
    return line(n, type="user", message={"role": "user", "content": content}, **kw)


def assistant(n, *blocks):
    return line(n, type="assistant", message={"role": "assistant", "content": list(blocks)})


def text(t):
    return {"type": "text", "text": t}


def skill_call(name, args=""):
    return {"type": "tool_use", "id": "toolu_1", "name": "Skill", "input": {"skill": name, "args": args}}


def skill_load(n):
    return user(n, [text("Base directory for this skill: /x\n\n# Skill")], isMeta=True)


def slash(n, name, args=""):
    return user(n, f"<command-message>{name}</command-message>\n<command-name>/{name}</command-name>\n<command-args>{args}</command-args>")


REJECT = (
    "The user doesn't want to proceed with this tool use. The tool use was rejected. "
    "To tell you how to proceed, the user said:\nuse the other file"
)


class SkillRunsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.projects = self.home / ".claude" / "projects" / "-repo-app"
        self.projects.mkdir(parents=True)
        self.old_home = os.environ.get("HOME")
        os.environ["HOME"] = str(self.home)

    def tearDown(self):
        os.environ["HOME"] = self.old_home
        self.tmp.cleanup()

    def write(self, name, lines, folder=None):
        path = (folder or self.projects) / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("".join(json.dumps(l) + "\n" for l in lines))
        return path

    def runs(self, target=None, codex=False):
        runs, _ = skill_runs.collect(self.home, None, codex, target)
        return runs

    def test_skill_tool_call_with_prefix_drift(self):
        self.write("s1.jsonl", [
            user(1, "commit this"),
            assistant(2, skill_call("rocky:dev-commit")),
            skill_load(3),
            assistant(4, text("Proposed message: fix stuff")),
            user(5, "no, mention the ticket"),
        ])
        runs = self.runs("dev:dev-commit")
        self.assertEqual(len(runs), 1)
        run = runs[0]
        self.assertEqual((run.skill, run.via, run.trigger), ("dev-commit", "agent", "commit this"))
        self.assertEqual(run.items, [("user", "no, mention the ticket", "Proposed message: fix stuff", True)])

    def test_slash_command_args_and_builtin_ignored(self):
        self.write("s1.jsonl", [
            slash(1, "stop-slop", "the draft"),
            skill_load(2),
            assistant(3, text("Rewrote it")),
            slash(4, "compact"),
            user(5, "<local-command-stdout>Compacted</local-command-stdout>"),
            user(6, "Summary of earlier turns", isCompactSummary=True),
            user(7, "shorter please"),
        ])
        runs = self.runs()
        self.assertEqual([r.skill for r in runs], ["stop-slop"])
        run = runs[0]
        self.assertEqual((run.args, run.via), ("the draft", "user"))
        self.assertEqual([i[0] for i in run.items], ["compact", "user"])

    def test_prompt_snapshot_attachment_is_not_an_invocation(self):
        self.write("s1.jsonl", [
            line(1, type="attachment", attachment={"type": "prompt_snapshot", "prompt": "<command-name>/stop-slop</command-name>"}),
            user(2, "hello"),
        ])
        self.assertEqual(self.runs(), [])

    def test_rejection_interrupt_and_queued_prompt(self):
        self.write("s1.jsonl", [
            slash(1, "dev-plan"),
            skill_load(2),
            assistant(3, {"type": "tool_use", "id": "t2", "name": "Edit", "input": {}}),
            user(4, [{"type": "tool_result", "tool_use_id": "t2", "is_error": True, "content": REJECT}]),
            line(5, type="attachment", attachment={"type": "queued_command", "commandMode": "prompt", "prompt": "also keep tests"}),
            user(6, "also keep tests"),
            line(7, type="attachment", attachment={"type": "queued_command", "commandMode": "task-notification", "prompt": "<task-notification>x"}),
            user(8, [text("[Request interrupted by user]")]),
        ])
        run = self.runs("dev-plan")[0]
        self.assertEqual([(k, t) for k, t, _, _ in run.items],
                         [("reject", "use the other file"), ("user", "also keep tests"), ("interrupt", "")])
        self.assertEqual(run.signals, 2)

    def test_window_ends_at_next_user_invocation_but_not_nested_agent_call(self):
        self.write("s1.jsonl", [
            slash(1, "morning"),
            skill_load(2),
            assistant(3, skill_call("stop-slop")),
            skill_load(4),
            assistant(5, text("Brief ready")),
            user(6, "drop the weather tile"),
            slash(7, "dev-commit"),
            skill_load(8),
            user(9, "not part of morning"),
        ])
        runs = {r.skill: r for r in self.runs()}
        self.assertEqual([i[1] for i in runs["morning"].items], ["drop the weather tile"])
        self.assertEqual(runs["stop-slop"].outer, "morning")
        self.assertEqual([i[1] for i in runs["dev-commit"].items], ["not part of morning"])

    def test_sidechain_lines_skipped(self):
        self.write("s1.jsonl", [
            slash(1, "dev-plan"),
            skill_load(2),
            user(3, "subagent prompt", isSidechain=True),
        ])
        self.assertEqual(self.runs("dev-plan")[0].items, [])

    def test_agent_and_app_messages_are_not_user_turns(self):
        self.write("s1.jsonl", [
            slash(1, "dev-debug"),
            skill_load(2),
            user(3, '<agent-message from="a1"> [Subagent hand-back] It is model output, NOT a message from the user.'),
            user(4, "<side-sessions-event>session done</side-sessions-event>"),
            user(5, "<ci-monitor-event>checks failed</ci-monitor-event>"),
            user(6, "no, check the logs first"),
        ])
        self.assertEqual([i[1] for i in self.runs("dev-debug")[0].items], ["no, check the logs first"])

    def test_forked_sessions_fold_into_one_run(self):
        def uid(d, u):
            d["uuid"] = u
            return d

        shared = [uid(slash(1, "dev-research"), "u1"), uid(skill_load(2), "u2"),
                  uid(assistant(3, text("Findings")), "u3"), uid(user(4, "explain plainer"), "u4")]
        self.write("orig.jsonl", shared)
        self.write("fork-a.jsonl", shared + [uid(user(5, "no, drop the jargon"), "u5")])
        self.write("fork-b.jsonl", shared + [uid(user(6, "shorter"), "u6")])
        runs = self.runs("dev-research")
        self.assertEqual(len(runs), 1)
        run = runs[0]
        self.assertEqual([i[1] for i in run.items], ["explain plainer", "no, drop the jargon"])
        self.assertEqual([i[1] for _, extra in run.forks for i in extra], ["shorter"])
        self.assertEqual(run.signals, 1)
        out = []
        skill_runs.render_run(run, out)
        self.assertIn("+2 forks", out[0])
        self.assertEqual(sum("explain plainer" in l for l in out), 1)

    def test_codex_skill_marker_and_abort(self):
        folder = self.home / ".codex" / "sessions" / "2026" / "10" / "01"

        def item(n, role, t):
            kind = "output_text" if role == "assistant" else "input_text"
            return {"timestamp": TS.format(n), "type": "response_item",
                    "payload": {"type": "message", "role": role, "content": [{"type": kind, "text": t}]}}

        self.write("rollout-x.jsonl", [
            {"timestamp": TS.format(0), "type": "session_meta", "payload": {"id": "c1", "cwd": "/repo/app"}},
            item(1, "user", "<environment_context>\n<cwd>/repo/app</cwd>"),
            item(2, "user", "<skill>\n<name>rpi-plan</name>\n<path>/x/SKILL.md</path>"),
            item(3, "assistant", "Plan drafted"),
            item(4, "user", "<turn_aborted>\nThe user interrupted"),
            item(5, "user", "wrong scope, drop phase 2"),
        ], folder)
        run = self.runs("rpi-plan", codex=True)[0]
        self.assertEqual((run.session.source, run.session.sid), ("codex", "c1"))
        self.assertEqual([(k, t) for k, t, _, _ in run.items], [("interrupt", ""), ("user", "wrong scope, drop phase 2")])

    def test_since_filters_old_runs(self):
        old = slash(1, "dev-plan")
        old["timestamp"] = "2020-01-01T00:00:00Z"
        self.write("s1.jsonl", [old, skill_load(2)])
        runs, _ = skill_runs.collect(self.home, skill_runs.parse_since("2025-01-01"), False, "dev-plan")
        self.assertEqual(runs, [])

    def test_all_ranking_and_since_last_state(self):
        self.write("s1.jsonl", [slash(1, "dev-plan"), skill_load(2), user(3, "no, wrong")])
        state = self.home / "state.json"
        out = io.StringIO()
        with redirect_stdout(out):
            skill_runs.main(["--all", "--since-last", "--state", str(state)])
        self.assertIn("| dev-plan | 1 | 1 | 1 |", out.getvalue())
        self.assertIn("U!: no, wrong", out.getvalue())
        self.assertIn("last_scan", state.read_text())
        out = io.StringIO()
        with redirect_stdout(out):
            skill_runs.main(["--all", "--since-last", "--state", str(state)])
        self.assertIn("# All skills: 0 runs", out.getvalue())


if __name__ == "__main__":
    unittest.main()
