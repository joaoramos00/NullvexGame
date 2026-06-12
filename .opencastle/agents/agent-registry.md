# Agent Registry

Project-specific agent-to-model assignments and scope examples for NullvexGame.

## Specialist Agent Registry

| Agent | Model | Tier | Best For |
|-------|-------|------|----------|
| **Developer** | Claude Sonnet 4.6 | Quality | GDScript implementation, game mechanics, character scripts, stage scenes |
| **Testing Expert** | Claude Sonnet 4.6 | Quality | Godot headless tests, test scene authoring, test coverage gaps |
| **UI/UX Expert** | Claude Sonnet 4.6 | Quality | HUD, menus, pause screen, touch controls, visual layout |
| **DevOps Expert** | Claude Haiku 4.5 | Fast | GitHub Pages deploy, web export pipeline, CI workflow edits |
| **Performance Expert** | Claude Sonnet 4.6 | Quality | Frame rate, draw calls, physics optimization, GDScript profiling |
| **Security Expert** | Claude Sonnet 4.6 | Quality | API key handling, .env, input validation, web export security |
| **Data Expert** | Claude Haiku 4.5 | Fast | PixelLab batch sprite generation, tileset pipelines, asset scripts |
| **Documentation Writer** | Claude Haiku 4.5 | Economy | Design specs, plan documents, GAME_CONTEXT.md updates |
| **Architect** | Claude Opus 4.8 | Highest | Architecture decisions, autoload signal design, system redesign |
| **Reviewer** | Claude Haiku 4.5 | Economy | Mandatory fast review after every delegation |
| **Researcher** | Claude Sonnet 4.6 | Quality | Full-repo codebase exploration, pattern discovery, context gathering |
| **Team Lead (OpenCastle)** | Claude Sonnet 4.6 | Quality | Task orchestration, delegation, decomposition |

## Deepen-Plan Scope Examples

When running the Deepen-Plan protocol, split research by domain:

```
Researcher A: "Research game mechanics / character scripts for [feature]"
  Scope: characters/, stages/stage_scene.gd, autoloads/

Researcher B: "Research UI / HUD aspects of [feature]"
  Scope: ui/, effects/

Researcher C: "Research stage / level design aspects of [feature]"
  Scope: stages/, docs/stage_00/, docs/corredor_template.md

Researcher D: "Research sprite / asset pipeline for [feature]"
  Scope: characters/*/*, docs/art_brief.md, .claude/skills/pixellab.md
```
