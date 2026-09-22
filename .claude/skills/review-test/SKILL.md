---
name: review-test
description: >
  Runs the backend Jest test suite for ai-newterra (src/backend) as an
  explicit, on-demand action. Use ONLY when the user invokes /review-test or
  explicitly asks to run the tests — never run the test suite automatically
  after code changes, even after touching backend services/routes/models.
---

Run the full backend test suite and report results concisely.

## Steps

1. `cd src/backend && npm test` (Jest, mongodb-memory-server — no external DB
   needed, safe to run anytime).
2. Report a short summary: total suites/tests passed vs failed.
3. If there are failures, list each one with file:line and the assertion
   message — don't try to fix them unless the user asks.
4. If the user named specific files/areas, scope the run to just those test
   files instead of the whole suite (`npx jest <path>`).

## Boundaries

This is the *only* place test runs happen in this project. Do not run
`npm test`, `npx jest`, or any test file outside of this skill being invoked
— not after edits, not "just to check", not before declaring a change done.
If you want to verify a backend change works, say so and wait for the user to
run `/review-test`, or ask them if they want you to run it now.
