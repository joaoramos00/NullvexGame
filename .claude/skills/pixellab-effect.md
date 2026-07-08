# Skill: pixellab-effect

Use quando o usuário pedir pra gerar o efeito visual de um **poder/habilidade**
(ability_id de boss — ignarath, galerix, etc.) ou outro efeito avulso —
burst, projétil, impacto — via PixelLab, com etapa de **escolha manual entre
candidatos** antes de animar.

Para personagens/inimigos/bosses com múltiplas direções (grunt, boss
completo) ou tilesets de fase, usar a skill `pixellab` (fluxo de
`create-character-with-4-directions`), não esta.

## Por que `create-1-direction-object` (não Pixflux puro)

Decisão do projeto: pra poderes, a escolha entre vários candidatos gerados
importa mais do que economizar uma chamada — `create_1_direction_object`
entra em status `review` com várias opções de estilo consistente, e só
promovemos (`select_object_frames`) a que bater com o que o usuário tem em
mente. Uma chamada de Pixflux só devolve UMA imagem, sem essa escolha.

**Trade-off aceito:** custa mais (Pro Tools, 20-40 gerações por chamada) e
sai como frames separados (URLs), não uma sprite sheet única — precisa de
um passo de download+empacotamento próprio (ver seção final).

## Fluxo completo (tools MCP `mcp__pixellab__*`)

### 1. Criar candidatos

```
create_1_direction_object({
  "description": "<ver template abaixo>",
  "size": 64,          # 64px ≤85 → 16 candidatos em status "review"
  "view": "sidescroller"
})
```
Retorna `object_id` imediatamente (job em background, ~30-90s).

### 2. Revisar candidatos

```
get_object({"object_id": "<id>"})
```
Com o objeto em `review`, isso mostra os frames candidatos inline (imagens
na conversa). Escolher visualmente os que batem com o poder pensado.

### 3. Selecionar (ou descartar tudo)

```
select_object_frames({"object_id": "<id>", "indices": [<escolhidos>]})
```
Cada índice escolhido vira um **object_id próprio**, já completo — não
precisa esperar geração de novo. Se nenhum candidato serve:
`dismiss_review({"object_id": "<id>"})` e gerar de novo com a description
ajustada.

### 4. Animar o escolhido

```
animate_object({
  "object_id": "<object_id do candidato escolhido>",
  "animation_description": "<progressão do efeito — ver template abaixo>",
  "mode": "v3"
})
```
Objeto 1-direção anima a direção `"unknown"` automaticamente — **não** passar
`directions`.

### 5. Buscar os frames finais

```
get_object({"object_id": "<mesmo object_id>"})
```
Objeto completo retorna `animations[].directions[].storage_urls.frames` —
uma **lista de URLs**, uma imagem PNG por frame (não uma sheet única).

## Depois: baixar + montar o GIF

`tools/pixellab_download.py` hoje só cobre o fluxo de `character` (v2
`create-character-with-4-directions`, ZIP + `background-jobs` com frames em
base64 inline) — **não serve pra objects**, cujo formato final é uma lista
de URLs públicas por direção (`storage_urls.frames`), obtida via
`get_object`, não por polling de `background-jobs`.

Precisa de um subcomando novo (`object-animation` ou similar) que:
1. Recebe o `object_id` já animado.
2. Chama `get_object` (ou usa o resultado já retornado na sessão).
3. Baixa cada URL de `storage_urls.frames` (`urllib.request`, sem precisar
   de Bearer token — são URLs públicas do Backblaze, como no tileset).
4. Salva `<nome>_f00.png` … `<nome>_fNN.png` e monta o GIF com Pillow
   (mesmo padrão de `cmd_animation`: `save_all=True, loop=0, duration=100`).

Isso ainda não foi escrito — fazer quando chegarmos nessa etapa.

## Template de description (objeto base)

```
{efeito}, {tema visual — paleta, formas-chave}, compact and centered, side view pixel art game asset
```

Exemplo (Galerix, rajada de vento do Zael):
```
compact swirling wind gust orb, teal-green and white spiraling energy, small dust particles caught in the swirl, compact and centered, side view pixel art game asset
```

## Template de animation_description

Descrever a progressão em uma frase, do jeito que o modelo v3 interpreta bem
transições (não listar frame a frame como no Pixflux — aqui é uma
descrição de movimento contínuo):

```
gust bursting outward and dispersing into wisps
```

## Pastas de destino

Mesmo padrão dos bosses: `characters/bosses/<boss>/fx_<nome>_f00.png` …
`_fNN.png` + `fx_<nome>.gif` (ex.: `characters/bosses/galerix/fx_wind_burst_f00.png`).
