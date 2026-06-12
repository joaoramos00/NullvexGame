# Deployment Configuration

Project-specific deployment details for NullvexGame.

## Platform: GitHub Pages

The game is deployed as a static web export via GitHub Pages.

| Setting | Value |
|---------|-------|
| Platform | GitHub Pages |
| Branch trigger | `master` (push or workflow_dispatch) |
| Artifact path | `export/web/` |
| Production URL | https://joaoramos00.github.io/NullvexGame/ |
| CI config | `.github/workflows/deploy.yml` |

## CI/CD Workflow

**File:** `.github/workflows/deploy.yml`

Steps:
1. Checkout repo
2. Configure GitHub Pages (`actions/configure-pages@v5`)
3. Upload artifact from `export/web/` (`actions/upload-pages-artifact@v3`)
4. Deploy to GitHub Pages (`actions/deploy-pages@v4`)

**Trigger:** Push to `master` or manual `workflow_dispatch`.

The web export artifact must be committed at `export/web/` before the CI pipeline runs. The `web-export` skill handles the Godot export step and commits the artifact.

## Local Development Server

```bash
# Start (after web export)
python -m http.server 8080 --directory export/web

# Kill
Get-Process python | Stop-Process
```

## Web Export Procedure

See `.claude/skills/web-export.md` for the full procedure. Key steps:
1. Export via Godot Editor → Web export preset → `export/web/`
2. Verify PCK file exists at `export/web/index.pck`
3. Start local server and validate in browser
4. Commit `export/web/` and push to `master` (CI auto-deploys)

## Environment Variables

| Variable | Used By | Notes |
|----------|---------|-------|
| `PIXELLAB_API_KEY` | Local sprite generation only | Never committed, not needed for deploy |

No runtime environment variables are needed for the deployed web build — all game state is in-memory (no backend).

## Known Deploy Requirements

- Web export requires the Godot Web export template to be installed in the editor
- `export/web/index.html` must reference `index.pck` — verify after export
- `GDScript` `sign()`/`clamp()`/`abs()` return `Variant` in web export: always use explicit `: float` typing in code that targets web
