# Report template

Keep it short. Facts and evidence, no narrative. Copy this shape:

````markdown
# <Feature> — tracer bullet: <PASS | FAIL | BLOCKED>

Mode: <permanent test at path/to/test | throwaway check in /tmp/...>
Target: <local URL / binary / simulator + backend URL>

## Bullet

Given <state>, when <action>, then <far-end result>.

| # | Layer | Touched by |
|---|-------|------------|
| 1 | <entry: page / endpoint / command / screen> | <step> |
| 2 | <service / handler> | <step> |
| 3 | <storage / queue / file> | <far-end check> |

## Run

```bash
<exact command that runs the test>
```

- Bite check: <what was broken, e.g. "returned early in OrderService#create"> → red at
  <assertion> → mutation undone, `git diff` clean → green
- Flake gate: 3/3 green

## Evidence

- <path to screenshot / trace / xcresult / log / response body>

## Bugs found

1. <title> — steps: <1, 2, 3>; expected <x>; got <y>; evidence <path>

(or "None")

## Not checked

- <what this bullet does not cover and why>

## Next bullets

1. <error path>
2. <permission / auth>
3. <empty or boundary value>
4. <concurrency / retry / idempotency>
````

Verdicts:

- **PASS** — bite check red, then 3/3 green, no bugs found.
- **FAIL** — the feature does not do what the bullet expects. List the bugs.
- **BLOCKED** — the environment or test data could not be brought up. Say what blocked it and
  what you tried.
