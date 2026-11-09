# Roadmap Progress Tracking Instructions

The project roadmap is maintained in `docs/roadmap/`.

Files:
- `docs/roadmap/README.md` — overall project roadmap and status
- `docs/roadmap/phase_1.md` — Phase 1 tasks and completion record
- `docs/roadmap/phase_2.md` — Phase 2 tasks and completion record
- Create subsequent phase files using the same structure.

## Rules

1. Read the roadmap before starting any development task.
2. Follow phases sequentially. Do not start a later phase without explicit approval.
3. Update the relevant phase file whenever a task is started, completed, deferred, or blocked.
4. Track each task with one status:
   - `[ ]` Not started
   - `[/]` In progress
   - `[x]` Completed
   - `[!]` Blocked
   - `[-]` Deferred
5. Record implementation details, changed files, test results, and unresolved issues.
6. Never mark a task complete without verifying its implementation and tests.
7. Record important architecture, security, and product decisions.
8. Update `README.md` whenever phase status changes.
9. Preserve previous progress and decisions. Never silently remove completed work.
10. At the end of each phase, prepare a completion report and wait for my approval before proceeding.

## Current instruction

Inspect Phase 1 and Phase 2 roadmap files and compare them against the actual repository.

Report:
- Verified completed tasks
- Incomplete tasks
- Missing tasks
- Blockers and risks
- Recommended next steps

Do not modify application code or begin a new phase during this audit. Update only roadmap tracking information after verification.