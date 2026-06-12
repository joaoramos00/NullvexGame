# Documentation Structure

Project-specific documentation layout for NullvexGame.

## Directory Tree

```
docs/
├── art_brief.md                           — Visual art direction and HD pixel art style guide
├── art_brief.txt                          — Plain text version of art brief
├── corredor_template.md                   — Reusable corridor section template (CorridorSection usage)
├── stage_00/
│   └── corredor.md                        — Stage 00 corridor 1 specification
├── superpowers/
│   ├── specs/                             — Design documents (feature specs, named *-design.md)
│   │   ├── 2026-05-19-megaman-inspired-game-design.md
│   │   ├── 2026-05-21-touch-controls-design.md
│   │   ├── 2026-05-21-stage-layouts-design.md
│   │   ├── 2026-05-21-run-shoot-animations-design.md
│   │   ├── 2026-05-22-imgdebug-panel-design.md
│   │   ├── 2026-05-22-stage00-redesign.md
│   │   ├── 2026-05-22-skills-and-context-design.md
│   │   ├── 2026-05-24-zael-missing-sprites-design.md
│   │   ├── 2026-05-26-stage00-enemies-design.md
│   │   ├── 2026-05-26-zael-gameplay-polish-design.md
│   │   ├── 2026-05-26-enemy-fly-hover-dive-retreat-design.md
│   │   ├── 2026-05-29-miniboss-room-design.md
│   │   ├── 2026-05-30-stage00-pos-corr-mb-pillars-design.md
│   │   ├── 2026-05-30-stage00-zone2-zone3-redesign.md
│   │   ├── 2026-05-31-no-wall-grab-design.md
│   │   ├── 2026-05-31-imgdebug-glass-colisoes-design.md
│   │   ├── 2026-05-31-pixellab-pipeline-design.md
│   │   ├── 2026-05-31-intro-boss-sprites-design.md
│   │   ├── 2026-05-31-intro-boss-ai-design.md
│   │   ├── 2026-06-01-stage-tilesets-design.md
│   │   └── 2026-06-01-boss-sprites-design.md
│   └── plans/                             — Implementation plans (named *-plan.md)
│       ├── 2026-05-19-plan-01-foundation.md
│       ├── 2026-05-19-plan-02-zael-single-shot.md
│       ├── 2026-05-21-touch-controls.md
│       ├── 2026-05-21-stage-layouts.md
│       ├── 2026-05-21-run-shoot-animations.md
│       ├── 2026-05-22-imgdebug-panel.md
│       ├── 2026-05-22-stage00-redesign.md
│       ├── 2026-05-22-skills-and-context.md
│       ├── 2026-05-24-zael-missing-sprites.md
│       ├── 2026-05-26-zael-gameplay-polish.md
│       ├── 2026-05-29-miniboss-room.md
│       ├── 2026-05-30-stage00-pos-corr-mb-pillars.md
│       ├── 2026-05-31-stage00-zone2-zone3-redesign.md
│       ├── 2026-05-31-no-wall-grab.md
│       ├── 2026-05-31-imgdebug-glass-colisoes.md
│       ├── 2026-05-31-pixellab-pipeline.md
│       ├── 2026-05-31-intro-boss-sprites-plan.md
│       ├── 2026-05-31-intro-boss-ai-plan.md
│       ├── 2026-06-01-stage-tilesets-plan.md
│       └── 2026-06-01-boss-sprites-plan.md
└── web/                                   — Cached web export artifacts (snapshot; active export is at export/web/)
    ├── index.html
    ├── index.pck
    ├── index.js
    ├── index.wasm
    ├── index.audio.worklet.js
    └── index.audio.position.worklet.js
```

## OpenCastle Docs

```
.opencastle/
├── README.md                  — Index of all .opencastle/ config files
├── project.instructions.md    — Project context loaded by all agents
├── LESSONS-LEARNED.md         — Agent knowledge base: pitfalls and workarounds
├── KNOWN-ISSUES.md            — Tracked issues, limitations, accepted risks
├── AGENT-FAILURES.md          — Dead letter queue for failed delegations
├── AGENT-PERFORMANCE.md       — Agent success/failure tracking
├── AGENT-EXPERTISE.md         — Agent strengths by task area
├── KNOWLEDGE-GRAPH.md         — Append-only file dependency relationships
├── DISPUTES.md                — Logged agent disagreements and resolutions
├── agents/
│   ├── agent-registry.md      — Agent model assignments
│   ├── skill-matrix.json      — Skill-to-slot bindings (machine-readable)
│   └── skill-matrix.md        — Skill matrix explanation
├── stack/
│   ├── api-config.md          — PixelLab API integration
│   ├── deployment-config.md   — GitHub Pages deployment
│   └── testing-config.md      — Godot headless test runner
├── project/
│   ├── docs-structure.md      — This file
│   ├── roadmap.md             — Feature roadmap
│   └── decisions.md           — Architecture Decision Records
└── logs/
    ├── README.md              — NDJSON log schema
    └── events.ndjson          — Append-only session/delegation log
```

## Conventions

- **Spec before plan:** Every feature starts with a `*-design.md` spec in `docs/superpowers/specs/`, then a `*-plan.md` in `docs/superpowers/plans/`
- **Date prefix:** All specs/plans use `YYYY-MM-DD-` prefix for chronological ordering
- **Check Known Issues** before starting any task (`.opencastle/KNOWN-ISSUES.md`)
- **Update roadmap** after completing features (`.opencastle/project/roadmap.md`)
- **Add ADR** for architecture decisions (`.opencastle/project/decisions.md`)
