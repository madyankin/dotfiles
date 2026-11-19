# Prod evidence recipes

Use whatever observability access the session has (Grafana MCP, Prometheus,
Loki, Datadog, cloud logs). With Grafana MCP, find datasource UIDs with
`list_datasources` — never guess them. Use a 7-day window; instant queries
with `endRfc3339` = now for totals. Examples below are Prometheus/LogQL;
translate them for other backends.

## What to collect

| Question | Source |
|---|---|
| Backlog over time | queue length / consumer lag metric, range, step 6h |
| Throughput and duration | job/handler duration `_sum/_count`; distribution from logs |
| Where time goes | per-phase log lines of one large case |
| Failures by class | error class regexp over logs |
| Restarts | shutdown lines or instance start events per instance |
| CPU vs waiting | per-instance CPU % vs wall time per phase |

Summary quantiles exported per process are usually meaningless across a
fleet; use means from `_sum/_count` and distributions from logs.

## Loki patterns

```logql
# duration buckets × outcome (adapt the regexp to the log format)
sum by (bucket) (count_over_time({<selector>} |= "<marker>"
 | regexp "elapsed=(?P<el>[0-9.]+).*(?P<res>done|fail)"
 | label_format bucket=`{{ if gt (float64 .el) 3600.0 }}c_gt1h{{ else if gt (float64 .el) 600.0 }}b_10to60m{{ else }}a_lt10m{{ end }}_{{ .res }}` [7d]))
# resource-seconds per bucket: same pipeline + `| unwrap el`, sum_over_time
# tail listing: `| el > 1800`, limit 60
topk(15, sum by (err) (count_over_time({<selector>} |~ "WARN|ERROR"
 | regexp "(?P<err>[A-Z][A-Za-z]+(::[A-Z][A-Za-z]+)*(Error|Exception|Timeout))" [7d])))
sum(count_over_time({<selector>} |= "<shutdown marker>" [7d]))
{<selector>} |= "<job or request id>"     # trace one case across instances
```

Framework markers differ — find them in the code first. Example, Sidekiq:
`elapsed=… INFO: done|fail`, `INFO: Shutting down`, `Terminating N busy
threads`; `fail` includes shutdown kills. Custom services: use their own
handler timers and log lines.

## Deploy frequency

```bash
git -C <repo> log origin/<default> --first-parent --merges --since='14 days ago' --oneline | wc -l
git -C <repo> show origin/<default>:<ci-dir>/<deploy-workflow> | grep -n "nomad\|kubectl\|helm\|deploy"
```
Check which jobs every deploy restarts, rollout policy (canary, max_parallel),
and shutdown timeouts vs job length.
