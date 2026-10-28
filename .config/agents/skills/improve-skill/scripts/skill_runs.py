#!/usr/bin/env python3
"""Find past runs of a skill in Claude Code and Codex transcripts.

Prints a markdown digest of what the user said, rejected, or interrupted during
each run, so a retro can work from history instead of memory.

  skill_runs.py <skill> [--since 90d] [--max-runs 30]
  skill_runs.py --all [--since-last] [--top 5]
  skill_runs.py --commit-scan

--since-last starts at the last committed scan and records this scan as pending;
--commit-scan makes it the new start. A scan whose output is lost is then repeated.
"""
import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path

USER_MAX = 400
ASSISTANT_MAX = 250
WINDOW_USER_TURNS = 15

HINT = re.compile(
    r"\b(нет|не так|не надо|не нужно|неправильно|неверно|зачем|почему ты|стоп|хватит|опять|снова|"
    r"я же|а не|вместо|no|nope|don'?t|wrong|instead|not what|stop|again|why did|should have|i said)\b",
    re.IGNORECASE,
)
SKIP_PREFIXES = (
    "<local-command-", "<task-notification", "<system-reminder", "<bash-input", "<bash-stdout",
    "<bash-stderr", "Caveat:",
    # Subagent hand-backs, other sessions' notes, and app events land as user turns but carry no user words.
    "<agent-message", "<side-sessions-event", "<ci-monitor-event",
)
CODEX_SKIP_PREFIXES = ("<environment_context", "<user_instructions", "# AGENTS.md", "<permissions")


@dataclass
class Event:
    kind: str  # invoke | end | user | assistant | reject | interrupt | compact
    ts: str
    text: str = ""
    skill: str = ""
    args: str = ""
    by_user: bool = False  # slash command or $skill, not the agent calling the Skill tool
    uid: str = ""  # transcript line uuid; a forked session copies its parent's lines with the same uuids
    tool_id: str = ""  # Skill tool_use id; an `end` event with the same id closes a skill that ran in a subagent


@dataclass
class Session:
    source: str
    path: Path
    sid: str = ""
    cwd: str = ""
    events: list = field(default_factory=list)


@dataclass
class Run:
    skill: str
    session: Session
    ts: str
    args: str
    trigger: str
    via: str
    outer: str  # skill whose run this one was called inside, if any
    items: list  # (kind, text, context, hinted)
    item_uids: list = field(default_factory=list)
    uid: str = ""  # uuid of the invoking line
    forks: list = field(default_factory=list)  # (Session, items only that fork has)
    forked: bool = False  # ran in a subagent; its own turns are in the subagent transcript, not here

    @property
    def signals(self):
        every = self.items + [i for _, extra in self.forks for i in extra]
        return sum(1 for kind, _, _, hinted in every if kind in ("reject", "interrupt") or hinted)

    @property
    def key(self):
        return (self.skill, self.uid) if self.uid else (self.skill, self.ts, self.args)


def bare(name):
    return name.strip().lstrip("/").split(":")[-1]


def clip(text, limit):
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


def parse_since(value):
    if value is None:
        return None
    m = re.fullmatch(r"(\d+)([dw])", value)
    if m:
        days = int(m.group(1)) * (7 if m.group(2) == "w" else 1)
        return datetime.now(timezone.utc) - timedelta(days=days)
    return datetime.fromisoformat(value).replace(tzinfo=timezone.utc)


def blocks_text(content, kind="text"):
    return "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == kind)


def add_user_text(session, ts, text):
    text = text.strip()
    if not text or text.startswith(SKIP_PREFIXES):
        return
    if text.startswith("[Request interrupted"):
        session.events.append(Event("interrupt", ts))
        rest = text.split("]", 1)[1].strip() if "]" in text else ""
        if rest:
            session.events.append(Event("user", ts, rest))
        return
    # A message typed while the agent was busy is logged as queued_command and again as a user turn.
    recent = [e.text for e in session.events[-6:] if e.kind == "user"]
    if text in recent:
        return
    session.events.append(Event("user", ts, text))


def parse_claude(path):
    session = Session("claude", path, sid=path.stem)
    lines = []
    for raw in path.open(errors="replace"):
        try:
            lines.append(json.loads(raw))
        except json.JSONDecodeError:
            continue
    for i, d in enumerate(lines):
        if d.get("isSidechain"):
            continue
        before = len(session.events)
        parse_claude_line(session, lines, i, d)
        for e in session.events[before:]:
            e.uid = d.get("uuid", "")
    return session


def parse_claude_line(session, lines, i, d):
    ts = d.get("timestamp", "")
    session.cwd = session.cwd or d.get("cwd", "")
    kind = d.get("type")
    msg = d.get("message") or {}
    content = msg.get("content")
    if kind == "assistant" and isinstance(content, list):
        for b in content:
            if b.get("type") == "tool_use" and b.get("name") == "Skill":
                inp = b.get("input") or {}
                session.events.append(Event("invoke", ts, skill=bare(inp.get("skill", "")), args=str(inp.get("args", "")), tool_id=b.get("id", "")))
        text = blocks_text(content)
        if text.strip():
            session.events.append(Event("assistant", ts, text))
    elif kind == "attachment":
        att = d.get("attachment") or {}
        if att.get("type") == "queued_command" and att.get("commandMode") == "prompt":
            add_user_text(session, ts, str(att.get("prompt", "")))
    elif kind == "user":
        if d.get("isCompactSummary"):
            session.events.append(Event("compact", ts))
            return
        if d.get("isMeta"):
            return
        if isinstance(content, str):
            m = re.search(r"<command-name>(/?[^<]+)</command-name>", content)
            if m:
                # Built-ins like /compact share the marker; only skills inject their SKILL.md next.
                if is_skill_load(lines[i + 1 : i + 5]):
                    args = re.search(r"<command-args>(.*?)</command-args>", content, re.S)
                    session.events.append(Event("invoke", ts, skill=bare(m.group(1)), args=args.group(1).strip() if args else "", by_user=True))
                return
            add_user_text(session, ts, content)
        elif isinstance(content, list):
            result = d.get("toolUseResult")
            forked = isinstance(result, dict) and result.get("status") == "forked"
            for b in content:
                if forked and b.get("type") == "tool_result":
                    # A forked skill is over once its result returns; later user turns are about the parent job.
                    session.events.append(Event("end", ts, tool_id=b.get("tool_use_id", "")))
                if b.get("type") == "tool_result" and b.get("is_error"):
                    body = b.get("content")
                    body = body if isinstance(body, str) else blocks_text(body or [])
                    if "doesn't want to proceed" in body:
                        reason = body.split("the user said:", 1)[1].strip() if "the user said:" in body else ""
                        session.events.append(Event("reject", ts, reason))
            text = blocks_text(content)
            if text:
                add_user_text(session, ts, text)


def is_skill_load(following):
    for d in following:
        if d.get("type") == "user" and d.get("isMeta"):
            content = (d.get("message") or {}).get("content")
            text = content if isinstance(content, str) else blocks_text(content or [])
            if text.startswith("Base directory for this skill"):
                return True
    return False


def parse_codex(path):
    session = Session("codex", path)
    for raw in path.open(errors="replace"):
        try:
            d = json.loads(raw)
        except json.JSONDecodeError:
            continue
        p = d.get("payload") or {}
        ts = d.get("timestamp", "")
        if d.get("type") == "session_meta":
            session.sid, session.cwd = p.get("id", path.stem), p.get("cwd", "")
            continue
        if d.get("type") != "response_item" or p.get("type") != "message":
            continue
        role = p.get("role")
        content = p.get("content") or []
        if role == "assistant":
            text = blocks_text(content, "output_text")
            if text.strip():
                session.events.append(Event("assistant", ts, text))
        elif role == "user":
            for b in content:
                text = (b.get("text") or "").strip()
                m = re.match(r"<skill>\s*<name>([^<]+)</name>", text)
                if m:
                    session.events.append(Event("invoke", ts, skill=bare(m.group(1)), by_user=True))
                elif text.startswith("<turn_aborted>"):
                    session.events.append(Event("interrupt", ts))
                elif text and not text.startswith(CODEX_SKIP_PREFIXES):
                    add_user_text(session, ts, text)
    return session


def runs_in(session, target=None):
    runs = []
    events = session.events
    for i, e in enumerate(events):
        if e.kind != "invoke" or not e.skill or (target and e.skill != target):
            continue
        trigger, outer, ended = "", "", set()
        for prev in reversed(events[:i]):
            if prev.kind == "user":
                trigger = prev.text
                break
            if prev.kind == "end":
                ended.add(prev.tool_id)
            if prev.kind == "invoke" and not outer and not (prev.tool_id and prev.tool_id in ended):
                outer = prev.skill
        items, uids, context, users, limit, forked = [], [], "", 0, WINDOW_USER_TURNS, False
        for nxt in events[i + 1 :]:
            if nxt.kind == "end":
                if e.tool_id and nxt.tool_id == e.tool_id:
                    # The parent never loaded this skill; only the user's reply to the relayed result is about it.
                    forked, limit = True, users + 1
                continue
            # A skill the agent calls before the user speaks is a step of this run, not a new run.
            # A forked run has no steps in the parent, so any later skill starts a new run.
            if (nxt.kind == "invoke" and (nxt.by_user or users or forked)) or users >= limit:
                break
            if nxt.kind == "invoke":
                continue
            if nxt.kind == "assistant":
                context = nxt.text
            elif nxt.kind == "user":
                users += 1
                items.append(("user", nxt.text, context, bool(HINT.search(nxt.text))))
                uids.append(nxt.uid)
                context = ""
            else:
                items.append((nxt.kind, nxt.text, context, False))
                uids.append(nxt.uid)
                context = ""
        runs.append(Run(e.skill, session, e.ts, e.args, trigger, "user" if e.by_user else "agent", outer, items, uids, e.uid, forked=forked))
    return runs


def transcript_files(home, since, codex):
    claude = sorted((home / ".claude" / "projects").glob("*/*.jsonl"))
    files = [("claude", f) for f in claude]
    if codex:
        files += [("codex", f) for f in sorted((home / ".codex" / "sessions").glob("**/*.jsonl"))]
    if since:
        files = [(s, f) for s, f in files if datetime.fromtimestamp(f.stat().st_mtime, timezone.utc) >= since]
    return files


def collect(home, since, codex, target=None, project=None):
    runs, unreadable = [], 0
    target = bare(target) if target else None
    for source, path in transcript_files(home, since, codex):
        try:
            raw = path.read_text(errors="replace")
        except OSError:
            unreadable += 1
            continue
        if target and target not in raw:
            continue
        try:
            session = parse_claude(path) if source == "claude" else parse_codex(path)
        except Exception:  # one corrupt transcript must not end the scan
            unreadable += 1
            continue
        if project and project not in session.cwd:
            continue
        for run in runs_in(session, target):
            if not since or (run.ts and datetime.fromisoformat(run.ts.replace("Z", "+00:00")) >= since):
                runs.append(run)
    runs = merge_forks(runs)
    runs.sort(key=lambda r: r.ts, reverse=True)
    return runs, unreadable


def merge_forks(runs):
    """Fold copies of one invocation (forked sessions) into the copy with the most items."""
    groups = {}
    for r in runs:
        groups.setdefault(r.key, []).append(r)
    merged = []
    for copies in groups.values():
        copies.sort(key=lambda r: len(r.items), reverse=True)
        main, seen = copies[0], {u for u in copies[0].item_uids if u}
        for other in copies[1:]:
            extra = [i for i, u in zip(other.items, other.item_uids) if not u or u not in seen]
            seen.update(u for u in other.item_uids if u)
            main.forks.append((other.session, extra))
        merged.append(main)
    return merged


def render_run(run, out):
    s = run.session
    head = f"## {run.ts[:16].replace('T', ' ')} · {s.source} · {s.cwd or '?'} · {s.sid[:8]} · via {run.via}"
    if run.outer:
        head += f" inside {run.outer}"
    if run.forked:
        head += " · forked"
    if run.forks:
        head += f" · +{len(run.forks)} forks"
    if run.args:
        head += f" · args: {clip(run.args, 120)}"
    out.append(head)
    if run.trigger:
        out.append(f"trigger: {clip(run.trigger, USER_MAX)}")
    render_items(run.items, out)
    for session, extra in run.forks:
        if any(kind != "compact" for kind, *_ in extra):
            out.append(f"fork {session.sid[:8]}, turns after it split off:")
            render_items(extra, out)
    out.append("")


def render_items(items, out):
    for kind, text, context, hinted in items:
        if context:
            out.append(f"- A: {clip(context, ASSISTANT_MAX)}")
        if kind == "user":
            out.append(f"  U{'!' if hinted else ''}: {clip(text, USER_MAX)}")
        elif kind == "reject":
            out.append(f"- REJECTED tool call{': ' + clip(text, USER_MAX) if text else ''}")
        elif kind == "interrupt":
            out.append("- INTERRUPTED")
        elif kind == "compact":
            out.append("- COMPACTED (earlier turns only summarized)")


LEGEND = (
    "Legend: U = user turn, U! = turn with a disagreement hint word, A = agent text just before it.",
    "A run 'inside' another skill, or triggered by a scheduled task, may log turns about the outer job.",
    "'+N forks' = one invocation copied into N forked sessions, counted once; only turns a fork adds are shown.",
    "'forked' = the skill ran in a subagent: only the user's first turn after its result is shown; the subagent transcript is not read.",
)


def render_single(target, runs, max_runs, unreadable, since):
    with_items = [r for r in runs if r.items or any(extra for _, extra in r.forks)]
    out = [
        f"# {target}: {len(runs)} runs, {sum(1 for r in runs if r.signals)} with signals"
        + (f", since {since.date()}" if since else ""),
        *LEGEND,
        "",
    ]
    for run in with_items[:max_runs]:
        render_run(run, out)
    silent = len(runs) - len(with_items)
    out.append(f"{silent} runs had no user turns after the invocation. Unreadable transcripts: {unreadable}.")
    return "\n".join(out)


def render_all(runs, top, unreadable, since):
    by_skill = {}
    for r in runs:
        by_skill.setdefault(r.skill, []).append(r)
    ranked = sorted(by_skill.items(), key=lambda kv: (sum(r.signals for r in kv[1]), len(kv[1])), reverse=True)
    out = [f"# All skills: {len(runs)} runs" + (f" since {since.isoformat(timespec='minutes')}" if since else ""), *LEGEND, ""]
    out += ["| skill | runs | runs with signals | signals |", "|---|---|---|---|"]
    for skill, rs in ranked:
        out.append(f"| {skill} | {len(rs)} | {sum(1 for r in rs if r.signals)} | {sum(r.signals for r in rs)} |")
    out.append("")
    for skill, rs in ranked[:top]:
        flagged = [r for r in rs if r.signals]
        if not flagged:
            continue
        out.append(f"# {skill}")
        out.append("")
        for run in flagged:
            render_run(run, out)
    out.append(f"Unreadable transcripts: {unreadable}.")
    return "\n".join(out)


def read_state(state):
    return json.loads(state.read_text()) if state.exists() else {}


def write_state(state, data):
    state.parent.mkdir(parents=True, exist_ok=True)
    tmp = state.with_suffix(".tmp")
    tmp.write_text(json.dumps(data) + "\n")
    tmp.replace(state)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("skill", nargs="?", help="skill name; plugin prefix optional")
    ap.add_argument("--all", action="store_true", help="rank every skill and digest the top ones")
    ap.add_argument("--since", help="90d, 2w, or ISO date (default 90d; --all with --since-last uses the state file)")
    ap.add_argument("--since-last", action="store_true", help="--all only: start from the last recorded scan")
    ap.add_argument("--commit-scan", action="store_true", help="start the next --since-last scan where the pending one started")
    ap.add_argument("--state", help="state file for --since-last and --commit-scan (default ~/.config/agents/backlog/.self-heal-state.json)")
    ap.add_argument("--max-runs", type=int, default=30)
    ap.add_argument("--top", type=int, default=5)
    ap.add_argument("--project", help="only sessions whose cwd contains this substring")
    ap.add_argument("--no-codex", action="store_true")
    args = ap.parse_args(argv)
    if sum((bool(args.skill), args.all, args.commit_scan)) != 1:
        ap.error("give a skill name, --all, or --commit-scan")

    home = Path.home()
    state = Path(args.state) if args.state else home / ".config" / "agents" / "backlog" / ".self-heal-state.json"
    data = read_state(state)
    if args.commit_scan:
        if "pending" not in data:
            print(f"no pending scan in {state}", file=sys.stderr)
            return 1
        write_state(state, {"last_scan": data["pending"]})
        print(f"next --since-last scan starts at {data['pending']}")
        return 0
    since = parse_since(args.since or "90d")
    if args.since_last and "last_scan" in data:
        since = datetime.fromisoformat(data["last_scan"])
    started = datetime.now(timezone.utc)

    target = bare(args.skill) if args.skill else None
    runs, unreadable = collect(home, since, not args.no_codex, target, args.project)
    if args.all:
        print(render_all(runs, args.top, unreadable, since))
        if args.since_last:
            write_state(state, {**data, "pending": started.isoformat()})
    else:
        print(render_single(target, runs, args.max_runs, unreadable, since))


if __name__ == "__main__":
    sys.exit(main())
