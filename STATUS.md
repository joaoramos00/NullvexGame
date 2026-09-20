# NullvexGame — Status do Projeto

> Gerado em 2026-09-20 a partir de inspeção do repositório (git log, `docs/superpowers/plans/`, árvore de arquivos). Ver `CLAUDE.md` para a visão geral e `GAME_CONTEXT.md` para convenções técnicas.

## 1. O que está pronto

### Fundação e arquitetura
- Autoloads (`GameManager`, `StageManager`, `AudioManager`, `AudioLibrary`) comunicando por sinais.
- `CharacterBase` com HP, dano, morte; `stage_scene.gd` compartilhado pelas 8 fases com desenho automático de terreno.
- Ferramentas de produção: painel **imgdebug** (modos plataforma/sala/piso+plataforma/piso+buraco/saliência/hitbox editor/projectile line), `CorridorSection` reutilizável, grupo `no_wall_grab`, foothold agarrável, wall-coyote.
- Câmera dedicada (`2026-06-28-camera-system.md`).

### Personagens jogáveis
- **Zael** (ranged): 5 tipos de tiro (Single/Spread/Rapid/Laser/Cannon), sistema de carga, animações run/jump/dash/hurt/death completas.
- **Zara** (melee): 5 armas, combo 2 golpes + finisher.
- **Kawagael** (3º personagem, atalho `K`): reskin completo via PixelLab (não é mais reskin do Zael — tem loader e FSM próprios). 15 animações geradas e integradas (`idle`, `run`/`run_start`/`run_stop`, `jump`, `jump_shoot`, `dash`, `dash_shoot`, `shoot_1/2/3`, `run_shoot`, `wall_slide`, `hurt`, `death`). Idle recriado v3/v4 (wide power-stance) e run recriado v3 (stride largo) já mergeados. Wiring em `stage_scene.gd` feito.
- Armaduras (4 peças cada, Zael e Zara) e habilidades de boss completas.

### Fases e conteúdo
- 12 fases (00 intro, 01–08 stage select, 09 gauntlet, 10–11 Nullvex) implementadas, incluindo redesigns pontuais das stages 05–08 (Galerix, Umbraex, Luxar, Terragor) e do stage 01 (shaft de wall-jump, ataques de fogo do Ignarath).
- 8 bosses elementais com IA de fase, projéteis e cadeia de fraquezas lógica; Nullvex com 2 formas (Humanoide + Verdadeira, 3 sub-fases).
- Inimigos por fase (grunts + flyers, sprites PixelLab dedicados por stage/tema) para as 8 fases temáticas.
- Colectáveis (corações, sub-tanks, armaduras, armas/tiros) distribuídos por fase.
- Rebalanceamento de HP/dano e rework do Voltrix (`2026-07-24`, `2026-07-25`).

### UI, áudio e save
- HUD, PauseMenu, GameOver, TitleScreen e **Stage Select redesenhado em grid 6×3** com portraits clicáveis e deeplink `?stage_select` (HP bar 3× maior).
- Save/Load compartilhado (fases, corações, sub-tanks, vidas) + separado (armaduras, habilidades, armas/tiros por personagem).
- Áudio via `AudioLibrary`/`AudioManager` (BGM + SFX, no-ops seguros com stream nulo).

### Pipeline / infra
- Geração de sprites/tilesets via PixelLab (skill `pixellab`), com scripts de curadoria de frames.
- Deploy automático: `.github/workflows/deploy.yml` builda o export Web no CI a cada push em `master` e publica no GitHub Pages — export **não deveria** ser commitado no repo (ver §2).
- Suite de testes headless Godot (`test_game_manager`, `test_stage_manager`, `test_character_base`, e os `test_kawagael*` do plano de swap).

## 2. Pendências conhecidas

- **Kawagael — Task 11 do plano (`docs/superpowers/plans/2026-08-10-kawagael-pixellab-swap.md`)**: verificação visual/smoke playthrough dentro do editor Godot (idle/run/jump/dash/hurt/shoot/wall_slide/death) ainda não foi feita nem registrada. Os checkboxes do próprio plano (Tasks 1–11) nunca foram marcados apesar do trabalho estar commitado — vale marcá-los `[x]` para o documento refletir a realidade.

## 3. Itens obsoletos / candidatos a limpeza

> **Atualização 2026-09-20:** itens 1–5 e 7 corrigidos no commit `chore: limpeza de itens obsoletos identificados no STATUS.md`. Item 6 (`.opencastle/`) ainda em aberto — aguardando decisão do usuário.

Achados concretos, do mais para o menos impactante:

### ✅ 1. Build web voltou a ser commitado no git (corrigido)
- `export/web/` está de volta ao tracking (**115 MB**, incluindo `index.pck` de ~82 MB) através dos commits `c37ca68`, `9ebe1a0` e `0f31218` ("chore: web export - ...").
- Isso é exatamente o problema que o commit `d69c2f5` ("remove built web export from tree") resolveu em 2026-08-20, citando estouro de cota de Git LFS em reexportações anteriores — e que `.claude/skills/web-export.md` documenta explicitamente: *"NÃO commitar `export/web/`"*, pois o CI (`deploy.yml`) já gera e publica o build a cada push.
- **Causa raiz encontrada:** `.claude/commands/web-export.md` (o slash-command) diverge da skill e instrui o oposto — passo 3 diz **"Commit e push"** em vez de "NÃO commitar". Alguém/algum agente seguiu o command desatualizado.
- **Ação recomendada:** `git rm -r --cached export/web/`, corrigir/alinhar `.claude/commands/web-export.md` com a skill (ou apagar o command duplicado e deixar só a skill), e reforçar que `export/` já está no `.gitignore` — só falta remover o que já foi commitado por engano de volta.

### ✅ 2. Gitlink quebrado: `.claude/worktrees/FireCorrection`
- É uma entrada `160000` (submodule/gitlink) no commit `698626d`, sem `.gitmodules` correspondente — aponta para um commit (`f85daab0...`) que não existe na história principal. Provável `git add -A` acidental rodado a partir de um worktree de agente.
- Resultado prático: `git submodule update`/clones estritos podem falhar ou confundir ferramentas; a pasta está vazia no working tree atual.
- **Ação recomendada:** `git rm --cached .claude/worktrees/FireCorrection` e confirmar que `.claude/worktrees/` está no `.gitignore` (hoje só `.worktrees/` está, sem o `.claude/` — vale adicionar a exceção).

### ✅ 3. Referências ao nome antigo do projeto ("SnesGame")
- `CLAUDE.md` (seção "Como Rodar Testes"), `.claude/skills/web-export.md` e `.claude/commands/web-export.md` ainda usam caminhos `D:\SnesGame` — o projeto atual é `NullvexGame`. Comandos copiados literalmente desses arquivos vão falhar.
- (Vários `docs/superpowers/plans/*.md` datados também citam `SnesGame` — esses são registros históricos e não precisam ser corrigidos, só os documentos "vivos" citados acima.)
- **Ação recomendada:** atualizar os caminhos nos 3 arquivos ativos.

### ✅ 4. Plano do Kawagael "Iteração 1" superado
- `docs/superpowers/plans/2026-06-08-kawagael-reskin-run.md` (+ spec `2026-06-08-kawagael-reskin-run-design.md`) descreviam uma abordagem que **estende `Zael`** e cai de volta nas texturas do Zael para estados não gerados. Essa abordagem foi totalmente substituída pelo plano `2026-08-10-kawagael-pixellab-swap.md`, que criou loader/FSM próprios e as 15 animações completas, sem depender do Zael.
- **Ação recomendada:** marcar o plano/spec de 06-08 como "Superseded by 2026-08-10-kawagael-pixellab-swap" no topo do arquivo (ou mover para uma pasta `archive/`), para não confundir quem ler os planos em ordem.

### ✅ 5. Assets órfãos do Kawagael (pré-loader de frames)
- `characters/ranged/kawagael/KawagaelRun.png`, `KawagaelJump_v2.png` e `rotations/kawagael_east.png` (+ seus `.import`) não são referenciados por `kawagael.gd`/`kawagael.tscn` — o runtime atual carrega frames curados de `anims/<estado>/` via `_add_anim_from_frames`. São sobras de uma iteração anterior ao loader por frames individuais.
- `assets/generated/kawagael_jump_v2/` e `assets/generated/kawagael_run_v2/` (~4 MB) são saída bruta do PixelLab de uma geração v2 já substituída pelas v3/v4 (que foram commitadas direto em `anims/`, sem pasta própria em `assets/generated/`).
- **Ação recomendada:** confirmar que nada carrega esses arquivos e removê-los (ou movê-los para `_raw/`, que já está no `.gitignore` do diretório).

### 🟢 6. `.opencastle/` — scaffolding nunca preenchido
- Instalado em 2026-06-01 e commitado (`!.opencastle/` força inclusão no `.gitignore`), mas `roadmap.md`, `decisions.md`, `KNOWN-ISSUES.md`, `DISPUTES.md` continuam com o conteúdo-molde de exemplo — nenhum agente populou de fato em ~3,5 meses de trabalho subsequente.
- **Ação recomendada:** decidir entre adotar o framework de verdade (preencher os arquivos) ou remover o tracking (`git rm -r --cached .opencastle/`) já que hoje é peso morto no repo.

### ✅ 7. Scratch files na raiz do repositório
- `Tasks.txt` — checklist manual de 2026-05-26, com a esmagadora maioria dos itens já marcados ✅; redundante com a tabela "Planos Completos" do `CLAUDE.md`.
- `KaelNewJump.jpg` (+ `.import`) e `test_plat_debug.gd` (+ `.uid`) — não referenciados por nenhum `.gd`/`.tscn`/`.md` do projeto.
- `gen_stage01_tileset.py`, `generate_door_sprite.py` — scripts pontuais citados só dentro de planos datados antigos (histórico), não fazem parte de nenhuma skill/workflow atual.
- **Ação recomendada:** arquivar `Tasks.txt` (ex.: mover para `docs/superpowers/plans/` com data, ou apagar já que está superado) e remover os arquivos não referenciados da raiz, se confirmado que não são usados manualmente pelo usuário.

## 4. Resumo de ações sugeridas (em ordem de impacto)

1. Remover `export/web/` do tracking e corrigir `.claude/commands/web-export.md` (maior risco: já causou estouro de LFS uma vez).
2. Remover o gitlink quebrado `.claude/worktrees/FireCorrection`.
3. Corrigir caminhos `SnesGame` → `NullvexGame` em `CLAUDE.md` e nos dois arquivos de web-export.
4. Marcar o plano de reskin (06-08) como superado.
5. Limpar assets órfãos do Kawagael e a pasta raiz.
6. Decidir o destino do `.opencastle/`.

Nenhuma dessas ações foi executada ainda — este documento é só o levantamento. Posso aplicar qualquer uma (ou todas) a partir daqui, mediante confirmação, já que envolvem remoção de arquivos e histórico de binários grandes.
