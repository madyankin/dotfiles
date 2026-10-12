# Surfaces

Each section says how to find what the project already uses, what to fall back to, how to
select and wait, and what evidence to keep. Always prefer the project's own tool over the
fallback.

## Web UI

**Find it.** Look for `playwright.config.*`, `cypress.config.*`, `spec/system/` or
`test/system/` (Capybara), `wdio.conf.*`, Selenium setup, or e2e scripts in `package.json`.

**Fallback.** Playwright (`@playwright/test`). In permanent mode, adding it is a new
dependency: propose it and wait for a yes. In throwaway mode, run it from the scratchpad, or
drive the agent's built-in browser if one is available.

**Select.** In this order: role and accessible name (`getByRole('button', { name: 'Save' })`),
label, placeholder, visible text, then a `data-testid` the project already uses. Avoid CSS
chains and XPath tied to layout.

**Wait.** Use auto-waiting locators and web-first assertions (`await expect(locator).toBeVisible()`).
Wait for a specific network response or UI state when a step triggers a request. Never use
`waitForTimeout` or fixed sleeps.

**Far end.** After the action, check the UI state a user would see. Then reload or navigate
away and back, so the check proves the data persisted and is not only client state. For a
durable side effect, read it through the API or a project helper.

**Evidence.** Turn on trace on first retry or always for the run (`trace: 'on'`), screenshot
on failure, and keep the HTML report. Record the paths.

## HTTP API

**Find it.** The project's request or integration tests: Rails request specs, `supertest`,
`httpx` or `requests` with `pytest`, Go `httptest` or a real-server harness, REST Assured.
Check for an OpenAPI spec to validate against.

**Fallback.** `curl` in throwaway mode, with `-sS -w '\n%{http_code}\n'` to capture the
status. Use `jq` to pick fields.

**Assert.** Status code, content type, and the response shape (against the schema if one
exists) and key field values. Then make a **separate read** (a `GET`, a list call, or a
project helper) to prove the side effect landed. A `201` alone proves nothing about storage.

**Async work.** If the feature enqueues a job, either run the project's job worker in the
test, use its inline or test adapter, or poll the far end with a timeout. Say which one you
used.

**Evidence.** Request and response pairs (redact tokens), server log lines for the request ID.

## CLI

**Find it.** Existing CLI tests: `bats`, `pytest` with `subprocess`, Go tests that build and
exec the binary, `assert_cmd` in Rust, shell scripts under `test/`.

**Fallback.** A small shell or Python script in the scratchpad that runs the built binary.

**Isolate.** Run in a fresh temp directory with a controlled `HOME` and config path, so the
user's own config is never read or changed. Pass input through arguments or stdin, never
interactive prompts.

**Assert.** Exit code, stdout, stderr, and files created or changed. Compare with golden files
only if the project already uses them. For failure paths, assert both a non-zero exit code
and a helpful message.

**Evidence.** The exact command line, exit code, captured stdout and stderr, and a listing of
the output files.

## Mobile (iOS Simulator)

**Find it.** A UI test target in the Xcode project (`*UITests`), `XCUIApplication` usage,
test plans (`*.xctestplan`), or Maestro or Detox config.

**Fallback.** In throwaway mode, build the app for the simulator and drive it with the agent's
simulator tool (launch, tap, type, screenshot). In permanent mode, add an XCUITest case to the
existing UI test target. If there is no target, propose one and wait for a yes.

**Select.** By accessibility identifier first, then by accessibility label. If a needed
element has no identifier, say so in the report as a testability gap. Do not add one to the
feature code without asking.

**Wait.** `waitForExistence(timeout:)` or expectations on element state. No fixed sleeps.

**Backend.** The simulator reaches a server on the host at `localhost`. Point the app at a
local or named staging backend through its launch arguments or environment, never at
production.

**Far end.** Check the screen the user would see, then a durable effect through the backend
API, or relaunch the app to prove local persistence.

**Evidence.** Screenshots at the key steps, the `.xcresult` bundle path, and the exact
`xcodebuild test` command with its `-destination`.
