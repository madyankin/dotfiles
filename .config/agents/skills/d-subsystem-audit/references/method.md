# Method

## Five questions per node

| Question | Answer must contain |
|---|---|
| MECHANISM | steps precise enough to predict behaviour after a crash |
| COST | units: s, µs/item, bytes/item, resource-hours, msg/s, $ |
| BOUNDARY | where a guarantee ends: transaction, consistency, failure, ownership |
| TRADE-OFF | what was given up for what |
| EVIDENCE | prod metric/log > experiment > code at default branch > tests > docs > words |

Labels: **F** with pointer (`file:line`, metric, log line). **I** with the
facts, the chain and the refuting observation. **Q** with the command, metric
or person that answers it. A question without a plan is noise.

## Failure patterns to check

- A process reads "current state" from an async downstream copy (search index,
  cache, replica, analytics store) and writes based on it → no read-your-writes.
- A cache or snapshot is written before the downstream acknowledges.
- Resume/retry reuses a record still owned by an in-flight run.
- Process-wide locks combined with raised concurrency.
- Runtime limits: interpreter lock (Ruby GVL, Python GIL), single consumer
  goroutine, partition count, connection pools.
- Deploys restart workers more often than the longest job lasts, and jobs have
  no checkpoints → endless restarts. Check graceful-shutdown timeout vs job
  length and what the queue does on SIGTERM vs SIGKILL.
- Hop timeouts that disagree (server shorter than client) → duplicate work.
- Fire-and-forget producers or consumers that commit before the write →
  silent loss, downstream drift.
- Scheduler fan-out of all items regardless of change; FIFO without size
  classes → small work waits behind huge work.
- Unbounded memory: whole input materialized, several copies at once.
- Secrets or PII copied into logs, audit tables, replication streams, dumps.

## Cost {#cost}

- Share of runs vs share of resource-time per duration bucket: the long tail
  usually owns most of the time.
- Restart survival without checkpoints: `P = e^(−T/MTBR)`; expected wall time
  `MTBR · (e^(T/MTBR) − 1)`. MTBR = hours ÷ restarts per instance.
- Capacity: workers × hours vs used; waste = time of failed or killed runs.
- Per-phase split from logs for one real large case; name which phases are CPU
  and which are waiting.

## Pages {#pages}

Shared design: tokens for both themes (paper, sheet, ink, muted, rule; water =
flow accent, fire = failure, amber = inference, ok = new). Display, body and
mono faces that cover the user's language. Tables and wide SVG scroll inside their own
`overflow-x:auto` wrappers.

**Map**: stat tiles (prod numbers) → flow SVG in vertical ownership bands
(processor / store / queue shapes; feedback loops thick red; R-pins on nodes;
each node `<g data-id tabindex=0>` opens a panel with the five questions) →
crash-after-step table → runtime & deploy SVG (instances, processes, threads,
locks, rollout policy) → one real case timeline → cost model (slider + bars)
→ filterable register → "what cannot change".

**Options**: root-cause cards → quick-fix table (change, file:line, R-ids,
expected effect) → one SVG on a fixed grid, tabs re-render from a config
`{nodes:{id:[title,sub,'n'|'c'|'g']}, edges:{id:[label,'n'|'c']}, gone:[], fire:[]}`
(green new, amber changed, red-dashed removed) → per-option card: mechanism,
cost, risk, Ask-first boundary, when to choose, module tree → coverage matrix
R × option (✓ ◐ — ✗) with cost/risk rows → recommended change set: one PR per
repo, shipped together, one after-deploy check (no phases or gates between
them) → invariants every option keeps.

Typical option axis, cheapest first: fix in place with stages and checkpoints
→ move the heavy part into a dedicated service with a lease → decouple via a
stream/topic → change the data model. The cheapest option's core is often a
prerequisite for the rest — say so.

**Experiment**: verdict tiles → answer → charts per measured dimension →
projection onto a real prod case per scenario → "fixes / does not touch" →
packaging or rollout options table → explainer of any unfamiliar tool →
method and what was not measured.
