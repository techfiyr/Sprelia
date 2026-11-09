# Agent instructions — index

All agents (Claude Code, Codex, Cursor, etc.) follow the same rules.
The entry point is the repository-root `CLAUDE.md`; this folder holds the detail.

| File | Contents |
|---|---|
| `../CLAUDE.md` | Role, document precedence, non-negotiable rules, approval gates |
| `architecture.md` | System architecture, implemented decisions, API, Firebase layout, roadmap |
| `security.md` | Security requirements, threat-relevant rules, review checklist |
| `development.md` | Commands, conventions, testing rules, definition of done, phase status |
| `flutter.md` | Flutter-specific conventions (layering, theming, widgets, errors) |
| `protected-files.md` | Files that need explicit owner approval to change |

If these files and a request conflict, stop and ask. Do not edit files in
`.agents/` without approval (they are protected).
