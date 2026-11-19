---
name: d-subsystem-audit
description: Audit one component, pipeline or service of a production system for reliability and performance — map its sources, stores, processors, queues and runtime/deploy, pull prod evidence, build a problem register with F/I/Q labels, propose alternative architectures with module layouts, and optionally measure a proposed change in Docker — published as visual artifacts. Use when the user says "map the architecture of X", "find the bottlenecks", "why does X keep failing / take so long", "what can we refactor and what not", "propose alternative architectures", "will this change buy us anything", "визуализируй архитектуру X", "найди узкие места", "почему X падает / так долго", "предложи альтернативные архитектуры", "даст ли это нам что-то вообще", or plans a refactor of a component that keeps causing trouble, or invokes /d-subsystem-audit.
---

# Subsystem audit

Input: one component the user names (a job, pipeline, service, consumer,
endpoint). Output: up to 3 linked artifacts — **Map** (current state and
problems), **Options** (target architectures), **Experiment** (one proposal
measured). Reader: the engineer who will refactor it. Write in the user's
language, compact.

Mental model — a fire-brigade map: **state** (where data lives), **flows**
(how it moves), **boundaries** (transactions, consistency, failure domains,
ownership), **pressure** (sync vs async, queues, backpressure). Every claim
carries **F** (seen in code, config, logs or metrics — with a pointer), **I**
(inference — facts, chain, what would refute it) or **Q** (open — where to
look, what it costs). If the user names a textbook or model to follow, read it
first and adopt its vocabulary. Details: `references/method.md`.

## Steps

1. **Scope.** Name the component, its entry points and its exits. List the
   repos it touches (workspace architecture doc if any, each repo's
   AGENTS.md/CLAUDE.md/README).
2. **Reuse prior research**: research, design and ADR docs in the workspace
   and each repo. Read summaries only and treat them as leads. Re-verify every line ref at
   the default branch (`git -C <repo> show origin/<default>:<path>`) — the
   local checkout is often a feature branch.
3. **Read the hot path yourself**: entry point, core processing code, queue or
   consumer config, runtime config (Nomad, K8s, systemd, PaaS), deploy
   workflow. Delegate
   adjacent repos to ONE background Explore agent with a numbered question list
   and "facts + file:line + which ref you read". Do not duplicate its work.
4. **Prod evidence (7 days)** while the agent runs: throughput, backlog,
   duration distribution, time share per bucket, failure classes, restarts,
   one bad case traced end to end. Recipes: `references/queries.md`.
5. **Cost model.** Unit costs (time and memory per item), share of runs vs
   share of resource-time, retry/restart amplification. Mark it I and state
   assumptions. Formulas: `references/method.md#cost`.
6. **Crash-after-step table.** For each step: what it does, where state lives
   after it, what happens if the process dies right after. Most correctness
   bugs show up here.
7. **Problem register R1..Rn**: problem, evidence, effect, severity,
   can-change (`yes` = inside the owning repo / `careful` = the repo's
   Ask-first boundaries in AGENTS.md or CLAUDE.md, shared schemas, message
   formats, latency-critical paths, other teams' code / `no` = external
   contract). Reduce to **2–4 root causes**; judge options by those.
8. **Map artifact**: flow diagram with clickable nodes and R-pins, runtime and
   deploy diagram, real case timeline, cost model, register, invariants.
9. **Options artifact**: quick fixes (days, one repo, each mapped to R-ids),
   one diagram with fixed node positions and a tab per option, module tree
   per option, coverage matrix, recommended change set (one PR per repo,
   shipped together) with one after-deploy check.
10. **Experiment artifact** only when a proposal's value is in doubt
    ("will this buy us anything"): `references/experiment.md`.
11. **Chat reply**: links, 4–6 findings with numbers, recommended path, what
    was not verified.

Before writing pages, call Artifact `quickstart` and follow
`artifact-diagramming` rules. Page layouts: `references/method.md#pages`.

## Rules

- Lead with the answer, then evidence. Nothing decorative.
- A doc is an F about the doc, not about the system. Code at the default
  branch beats docs; prod observation beats code.
- Prod access is read-only. No ticket or chat writes, commits or PRs unless
  asked.
- Run code only in Docker; data and scratch code go to the session scratchpad.
- Link the artifacts to each other. They are private — tell the user to share
  via the page's Share menu.
- Ask the user only for decisions that are theirs; otherwise choose and say so.
