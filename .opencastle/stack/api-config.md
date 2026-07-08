# API Configuration

External API integrations for NullvexGame.

## PixelLab AI — Sprite & Tileset Generation

Used to generate pixel art characters, boss sprites, and stage tilesets.

| Setting | Value |
|---------|-------|
| Auth env var | `PIXELLAB_API_KEY` |
| Auth file | `.env` (gitignored) |
| MCP server | `mcp__pixellab__*` tools available in Claude Code |

### Load API Key

```bash
# PowerShell
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]

# Bash
export PIXELLAB_API_KEY=$(grep PIXELLAB_API_KEY .env | cut -d= -f2)
```

### Endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST https://api.pixellab.ai/v2/tilesets-sidescroller` | Generate sidescroller tilesets (floors, walls, backgrounds) |
| `POST https://api.pixellab.ai/v1/generate-image-pixflux` | Generate a single one-off image from a text description (no candidate review) |
| `POST https://api.pixellab.ai/v2/create-1-direction-object` | Generate a power/ability effect object with candidate review — see `.claude/skills/pixellab-effect.md` |

### MCP Tools (preferred over direct HTTP)

Use the `mcp__pixellab__*` MCP tools when available — they handle polling, error handling, and binary download automatically.

| Tool | Purpose |
|------|---------|
| `mcp__pixellab__create_character` | Generate character sprite (idle, walk, jump, etc.) |
| `mcp__pixellab__create_character_state` | Generate a specific animation state for existing character |
| `mcp__pixellab__animate_character` | Animate a character |
| `mcp__pixellab__create_sidescroller_tileset` | Generate a full sidescroller tileset |
| `mcp__pixellab__get_sidescroller_tileset` | Poll tileset generation status |
| `mcp__pixellab__list_characters` | List generated characters |
| `mcp__pixellab__get_balance` | Check remaining PixelLab credits |

### Local Skill

See `.claude/skills/pixellab.md` for the full workflow and conventions used in this project.

### Output Locations

| Asset Type | Output Directory |
|-----------|-----------------|
| Character sprites (Zael, Zara) | `characters/ranged/`, `characters/melee/` |
| Boss sprites | `characters/bosses/<boss_name>/` |
| Enemy sprites | `characters/enemies/` |
| Stage tilesets | `stages/tilesets/` or `stages/stage_XX/tileset/` |
