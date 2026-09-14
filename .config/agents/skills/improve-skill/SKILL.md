---
name: improve-skill
description: Run a retrospective on a skill that was just used, harvest the friction from what actually happened, and rewrite the skill so the next run does not hit it again. Use when the user asks how to improve a skill, says a skill run went badly or had rough edges, asks "what did we learn from that run", or invokes /improve-skill after finishing work with another skill.
---

# Improve Skill

A skill is a set of instructions for doing a job well. Every time it runs, the run leaves
evidence of where the instructions were thin: the places the agent improvised, the work it did
by hand, the things the user had to correct. This skill harvests that evidence while it is
still warm and turns it into edits.

The deliverable is **edited skill files plus proof they work** — a re-run of the skill with
the new version. A retrospective that ends in a list of suggestions is not a retrospective, it
is a wishlist. If you cannot prove the change, say so instead of claiming it.

One skill per run. "Improve my skills" is a request to pick one.

## Timing

Best immediately after a run, in the same conversation, while the run's tool calls and dead
ends are still in context. That context is the single richest source and it is not
recoverable later — a transcript read after the fact shows what happened but not what was
almost done, what was rejected, or what took three attempts.

If the run is not in context, say so plainly and work from artifacts: the files the run
produced, the skill's own text, and what the user remembers. The retro is still worth doing;
it is just shallower, and you should not pretend otherwise.

## Workflow

1. **Locate the target.** User skills live in **`~/.config/agents/skills/<name>/`**. That is
   the canonical path and the one to write in reports. `~/.claude/skills` is a symlink to it,
   so edits through either path land in the same files — but tools that resolve real paths
   (node stack traces, `realpath`, some editors) print the `.config/agents` form, and a run
   that only knows the `.claude` spelling reads that as a different location and gets confused.
   Also check `.claude/skills/` inside the project and plugin skills under
   `~/.claude/plugins/`.

   Read `SKILL.md` and every file in `references/`. You are about to edit them; read them
   whole, not by grep.
2. **Harvest friction.** See below. Produce a concrete, evidence-backed list — no generic
   software-quality advice.
3. **Ask the user only what you cannot observe.** See "What to ask".
4. **Classify each item into a fix type.** See the table. This is where most of the value is:
   the same friction has a cheap wrong fix and an expensive right one, and the right one is
   usually code.
5. **Make the edits.** Prefer deleting and tightening over appending.
6. **Prove it: re-run the skill.** Non-negotiable — see "Close the loop".
7. **Record it** in the target skill's `## Changelog`, one line, dated.
8. **Report**: what changed, what it removes from every future run, what you chose not to do.

## Harvesting friction

Four sources, in descending order of signal. Walk the run and look for each explicitly.

**Improvisation — the agent decided something the skill did not cover.**
Every judgment call made without a rule is a gap. In a run that had to invent a filename
because the obvious one was taken, the gap is not "naming is hard", it is "the skill has no
collision rule". Improvisation is the highest-signal source because it is invisible in the
output: the run looks fine, and the next run improvises differently.

**Manual labor — the agent did by hand what a script could do.**
Any helper written inline during the run should have been in the skill's library. Any property
checked by eye should have been checked by a program. Any search for a lucky constant should
have been a guarantee. This is the source that pays off most, because it converts per-run cost
into one-time cost.

**Corrections — the user changed direction, rejected output, or fixed something.**
Each correction is ambiguity that resolved the wrong way. Ask what the instruction should have
said to make the first attempt right.

**Dead text — the skill said something the run did not do, or could not do.**
A rule nobody follows is worse than no rule: it trains the reader to skim. Either the rule is
wrong, or it is unreachable (buried, contradicted elsewhere, or requires a tool that isn't
there). Find out which, then fix or cut it. A skill that only grows becomes a skill nobody
reads to the end.

Also worth a look: steps that took several attempts, anything the run verified twice because
it did not trust the first check, and anything the run apologised for.

## What to ask the user

Ask only what you genuinely cannot observe. You can read the files; you can see the run. What
you cannot see is intent and taste.

Worth asking:

- Which of the rough edges actually bothered them — some friction is fine, and fixing it costs
  clarity elsewhere.
- Whether an output they accepted was actually what they wanted, or merely tolerable.
- Whether a judgment call the run made should become the rule, or should stay a judgment call.
- How much weight to give one-off situations: does this case recur, or was it this subject
  only?

Not worth asking: anything in the files, anything in the run, or "should I improve it?" — they
already said yes. Batch the questions into one round; a retro that interrogates is worse than
one that proposes and gets corrected.

## Fix types

The cheap fix is almost always "add a line to the checklist". It is almost always wrong: a
checklist is a list of things that can be forgotten.

| Friction | Cheap wrong fix | Right fix |
|---|---|---|
| Same helper re-derived every run | "remember to write X" | Ship X in the skill's library, with an API doc and one worked call |
| Correctness checked by eyeball | "verify carefully" | Ship a harness that runs the artifact and fails loudly |
| Property hand-checked after generation | Add a checklist item | Make the generator guarantee it by construction |
| Agent improvised a decision | Leave it, it worked | Write the rule *with its branches*, and require the run to say which branch it took |
| Numbers or citations from memory | "be accurate" | Name the tool and the exact command that verifies them |
| Instruction ignored every run | Repeat it louder | Find out why: wrong, buried, or contradicted — then fix or cut |
| Template and prose disagree | Patch whichever you noticed | Decide which is right, fix the other, put the fact in one place only |
| Output was bloated | "be concise" | Give a budget with a unit, and a rule for what to drop first |

Two rules of thumb:

- **Code beats prose.** An instruction is a thing that can be forgotten. A script is a thing
  that cannot. If a checklist item can be a script, it must be.
- **Construction beats verification.** If the generator can make a property impossible to
  violate, do that instead of checking for the violation afterwards.

## Keep the skill readable

The skill is read in full, every run. Growth is a real cost.

- Adding a section? Look for one to delete or fold in. Say what you considered cutting.
- A rule that applies to one subject belongs in the run, not the skill. The specifics of what
  a run happened to be *about* must not leak into the instructions.
- Prefer a table to a paragraph, a command to a description of a command, and one example to
  three.
- If a reference file is over ~500 lines, split it by *when it gets read*, not by topic.
- Never encode the user's one-off preference as a universal rule without asking.

## Close the loop

An edit you have not exercised is a guess.

1. Re-run the target skill — ideally on the same input, so the two outputs are comparable.
2. Confirm each change did what it was for: the improvised decision now has a rule the run
   followed; the hand-written helper is now a library call; the harness catches the thing it
   was built to catch.
3. If the skill ships a verifier, it must pass on the new output.
4. Replace the earlier artifacts, unless the user wants both kept.

If a change cannot be exercised — it only fires on input you don't have — say which one, and
why, rather than reporting it as proven.

Beware the loop that only confirms: re-running on the same input proves the change did not
break anything, not that it generalises. When a change is about a case the re-run does not hit
(the collision rule, the empty-input guard), test that case directly, even if only with a
throwaway call.

## Changelog

Append one line to a `## Changelog` at the bottom of the target `SKILL.md`; create the
section if it isn't there.

```markdown
## Changelog

- 2026-09-13 — shipped `verify.js`; `Viz.tree` replaces hand-rolled layouts; quiz balances
  answer positions by construction instead of by seed search.
```

Its job is to stop the next retro from re-litigating a settled decision, and to make a rule
that was deliberately *removed* stay removed. Keep it to one line per retro; it is a record,
not a diary. If it grows past ~15 lines, collapse the old ones into a sentence.

## Report

State plainly:

- What changed, file by file, and what each change removes from every future run.
- What the re-run proved, and what it could not.
- What you chose **not** to fix, and why — one-off, user's deliberate choice, or costs more
  clarity than it buys.
- Anything you now believe is wrong with the skill but could not fix without a decision from
  the user.

Never report an improvement you did not exercise as if you had.
