# Stage card

Fill each section in 1-3 lines. Leave out a section that has nothing to say.

```markdown
## Stage N of M: <behavior, as a short sentence>

**Build:** <what the code must do after this stage, in terms of input and output>

**Why:** <how this stage serves the goal, and what the next stage builds on it>

**Where:** <directory or file to work in; the existing class or function it plugs into>

**Test:** `<path to the test>` checks that <the observable result>.
Run: `<exact command, the way the project runs tests>`

**Notes:**
- <a trap in this stage: an edge value, a library quirk, an existing convention to follow>
```

Example:

```markdown
## Stage 3 of 7: Sum hourly totals inside a window

**Build:** given hourly rows and a time window, return one total per series that counts only
the full hours inside the window.

**Why:** the comparison in stage 4 must compare the same hours for both sides.

**Where:** the totals object from stage 2.

**Test:** `spec/totals_window_spec.rb` checks that an hour cut by the window end is left out.
Run: `bin/test spec/totals_window_spec.rb`

**Notes:**
- The window end is exclusive.
- An empty window gives zeros, not nil.
```
