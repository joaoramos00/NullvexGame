# Customizations

Project-specific configuration for the AI agent framework. Everything in this folder is **particular to NullvexGame** — the rest of the orchestrator directory (instructions, skills, agents, prompts, workflows) is project-agnostic.

## Why this exists

Skills and instructions contain generic methodology (how to write tests, how to run a panel review). This folder holds the concrete values those skills operate on — Godot paths, PixelLab API details, test scene lists, deployment config, and similar project-specific context.

## Contents

| File | Purpose |
|------|---------|
| `project.instructions.md` | Full project context: architecture, tech stack, key commands, file map |
| `LESSONS-LEARNED.md` | Agent knowledge base of pitfalls, workarounds, and gotchas — read before every session |
| `KNOWN-ISSUES.md` | Tracked issues, limitations, and accepted risks |
| `AGENT-FAILURES.md` | Dead letter queue for failed agent delegations |
| `AGENT-PERFORMANCE.md` | Agent success tracking and performance metrics |
| `AGENT-EXPERTISE.md` | Structured tracking of agent strengths/weaknesses |
| `KNOWLEDGE-GRAPH.md` | Append-only log of file dependencies and patterns |
| `DISPUTES.md` | Logged agent disagreements and resolutions |

### `agents/` — Agent framework config

| File | Purpose |
|------|---------|
| `agent-registry.md` | Specialist agents with Claude model tier assignments and scope examples |
| `skill-matrix.json` | Maps capability slots to concrete skills per agent role (machine-readable) |
| `skill-matrix.md` | Documentation explaining the skill matrix concept |

### `stack/` — Tech stack config

| File | Purpose |
|------|---------|
| `api-config.md` | PixelLab AI API: endpoints, MCP tools, auth, output paths |
| `deployment-config.md` | GitHub Pages deployment: CI workflow, local server, web export |
| `testing-config.md` | Godot headless test runner: test scene list, critical rules |

### `project/` — Project management config

| File | Purpose |
|------|---------|
| `docs-structure.md` | Full docs directory tree and documentation conventions |
| `roadmap.md` | Project roadmap with feature status |
| `decisions.md` | Architecture Decision Records |

### `logs/` — Append-only NDJSON session logs

| File | Purpose |
|------|---------|
| `README.md` | Schema documentation for the NDJSON log files |
| `events.ndjson` | All structured event log entries (sessions, delegations, reviews) |

## When to update

Update these files when the project changes — new test scenes, new API endpoints, new deployment steps, changed skill assignments. The skills themselves rarely need editing; changing a Godot path or adding a test suite is a customization change.
