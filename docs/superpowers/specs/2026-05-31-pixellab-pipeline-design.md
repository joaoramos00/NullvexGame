# PixelLab Asset Pipeline — Design Spec

**Data:** 2026-05-31  
**Projeto:** NullvexGame  
**Objetivo:** Integrar o PixelLab MCP ao Claude Code e criar um pipeline estruturado para geração de sprites de inimigos/bosses e tiles de fase, com download automático nas pastas corretas do projeto.

---

## Contexto

O projeto já usa a PixelLab REST API via scripts Python ad hoc. Este pipeline formaliza o workflow:

- MCP do PixelLab configurado no Claude Code para uso direto em sessões
- Script `tools/pixellab_download.py` para download, conversão e placement automático
- Skill `.claude/skills/pixellab.md` que guia Claude no uso correto das ferramentas

**Assets prioritários:**
- Inimigos: grunt (ground), flyer
- Bosses: 8 elementais (Ignarath, Cryovex, Voltrix, Gravitus, Galerix, Umbraex, Luxar, Terragor)
- Stage 00: assets existentes reorganizados para nova estrutura de pastas (sem regeneração)

---

## Componentes

| Componente | Arquivo | Papel |
|-----------|---------|-------|
| MCP Config | `.claude/settings.json` | Registra servidor PixelLab no Claude Code |
| Download script | `tools/pixellab_download.py` | Download + conversão rgba_bytes→PNG via Pillow |
| Skill | `.claude/skills/pixellab.md` | Workflow completo, parâmetros canônicos, folder map |

---

## Tamanhos e Endpoints por Tipo de Asset

| Asset | Canvas | Endpoint | Direções |
|-------|--------|----------|----------|
| Tiles de fase | 32×32 | `POST /v2/tilesets-sidescroller` (via MCP) | — |
| Inimigos (grunt, flyer) | 64×64 | `POST /v2/create-character-with-4-directions` | 4 (side) |
| Bosses elementais | 128×128 | `POST /v2/create-character-with-4-directions` | 4 (side) |

**Nota:** `create-character-with-4-directions` suporta `view: "side"` — confirmado em teste. O canvas real retornado pode ser ligeiramente maior que o solicitado (ex: 64 → 92px) por ajuste interno do template.

---

## Folder Mapping

Assets gerados são depositados diretamente nas pastas do projeto:

```
characters/enemies/grunt/          → sprites + animações do grunt
characters/enemies/flyer/          → sprites + animações do flyer
characters/enemies/ignarath/       → boss Ignarath (128×128)
characters/enemies/cryovex/
characters/enemies/voltrix/
characters/enemies/gravitus/
characters/enemies/galerix/
characters/enemies/umbraex/
characters/enemies/luxar/
characters/enemies/terragor/
stages/stage_00/tileset/           → tileset do Stage 00 (se necessário)
```

Assets existentes do Stage 00 são **movidos** para as pastas acima — sem regeneração (Stage 00 está completo exceto final boss).

**Convenção de nome de arquivo:**
- Sprites estáticos: `<nome>_<direcao>.png` (ex: `grunt_west.png`)
- Frames de animação: `<nome>_<acao>_<direcao>_f<nn>.png` (ex: `grunt_walk_west_f00.png`)
- GIF de preview: `<nome>_<acao>_<direcao>.gif`

---

## Workflow Canônico

```
1. Checar créditos
   GET /v2/balance

2. Criar personagem
   POST /v2/create-character-with-4-directions
   {
     "description": "<descrição do personagem, estilo Mega Man X pixel art>",
     "image_size": {"width": 64, "height": 64},   // ou 128x128 para bosses
     "view": "side",
     "proportions": {"type": "preset", "name": "heroic"},
     "outline": "single color outline",
     "shading": "basic shading",
     "detail": "medium detail"
   }
   → retorna character_id (job assíncrono)

3. Aguardar sprites base
   GET /v2/characters/{character_id}
   Poll a cada 15s até rotation_urls estar preenchido (não nulo)

4. Baixar sprites
   GET /v2/characters/{character_id}/zip  (com Bearer token)
   → extrair para pasta destino

5. Animar (por ação: walk, idle, attack, death, hit)
   POST /v2/animate-character
   {
     "character_id": "<id>",
     "action_description": "<descrição da animação>",
     "directions": ["west", "east"],
     "frame_count": 8,
     "mode": "v3"
   }
   → retorna background_job_ids (um por direção)

6. Aguardar animação
   GET /v2/background-jobs/{job_id}
   Poll a cada 15s até status == "completed"

7. Salvar frames
   last_response.images → lista de {type:"rgba_bytes", width:N, base64:"..."}
   Converter via Pillow: Image.frombytes("RGBA", (w, h), raw_bytes)
   Salvar PNG individual por frame + GIF agregado para preview

8. Tileset (quando necessário)
   Via MCP: create_sidescroller_tileset
   {
     "lower_description": "<material da plataforma>",
     "transition_description": "<decoração do topo>",
     "transition_size": 0.25,
     "tile_size": {"width": 32, "height": 32},
     "outline": "single color outline",
     "shading": "basic shading",
     "detail": "medium detail"
   }
   Poll: get_sidescroller_tileset até status == "completed"
```

---

## `tools/pixellab_download.py` — Interface CLI

```bash
# Sprites base de personagem (ZIP → PNG)
python tools/pixellab_download.py character <character_id> <pasta_destino>

# Frames de animação (rgba_bytes → PNG + GIF)
python tools/pixellab_download.py animation <job_id> <pasta_destino> --direction <west|east|south|north> --action <walk|idle|attack|death|hit>

# Tileset
python tools/pixellab_download.py tileset <tileset_id> <pasta_destino>
```

Dependências: `Pillow` (já disponível no ambiente — v12.2.0 confirmado).  
Autenticação: lida do arquivo `.env` (`PIXELLAB_API_KEY=...`).

---

## MCP Config (`.claude/settings.json`)

```json
{
  "mcpServers": {
    "pixellab": {
      "url": "https://api.pixellab.ai/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer <PIXELLAB_API_KEY do .env>"
      }
    }
  }
}
```

**Nota:** O token não deve ser hardcoded. A skill documenta como ler do `.env` antes de configurar.

---

## Detalhes Técnicos Aprendidos em Teste

| Ponto | Detalhe |
|-------|---------|
| `create-character-with-4-directions` | Assíncrono — retorna `character_id`, não imagens imediatas |
| Download de sprites | `GET /v2/characters/{id}/zip` + Bearer token (URLs Backblaze retornam 403 sem auth) |
| Formato de frames de animação | `rgba_bytes` — base64 de bytes RGBA brutos, não PNG |
| Conversão de frame | `Image.frombytes("RGBA", (w, h), base64.b64decode(img["base64"]))` |
| `frame_count: 8` | Produz 9 frames (1 frame extra de fechamento do ciclo) |
| Tempo de animação v3 | ~2–3 min por direção |
| Tempo de sprite base | ~2–5 min |

---

## Fora de Escopo

- Geração de sprites de Zael/Zara (feitos manualmente com `generate_zael_sprites.py`)
- Organização interna dos tilesets no Godot (TileSet resource, atlas) — feita manualmente após import
- Animações de boss (movimentos específicos de ataque) — descritas por fase quando necessário
