# Stage 00 — Redesign Spec

## Objetivo

Reformular o Stage 00 (fase introdutória obrigatória) para ser uma fase completa com inimigos, mecânicas novas, checkpoints estilo Mega Man X e boss room fechada, mantendo a função de introduzir o jogador ao jogo.

---

## Visão Geral

| Atributo | Valor |
|---|---|
| Tamanho | Variável (sem teto fixo — o layout define o comprimento) |
| Referência base | ~9000px, expande conforme necessário |
| Câmera | Segue o jogador, sem limite rígido à direita |
| Checkpoints | 2 (estilo MMX — corredor com porta) |
| Zonas de combate | 3 |
| Total de inimigos | 22 (15 Grunts + 7 Flyers) |
| Boss | Intro Boss (único, novo personagem, mais simples que os 8 elementais) |

---

## Fluxo da Fase

```
Spawn → Zona 1 → CP1 (corredor MMX) → Pilar Wall Jump → Zona 2 → Zona 3 → CP2 (corredor MMX → porta boss) → Boss Room
```

---

## Zonas de Combate

Cada zona é delimitada por um **trigger Area2D**. Ao sair da zona e voltar, todos os inimigos daquela zona reaparecem (respawn por zona). Checkpoints **não** revertem o respawn.

### Zona 1 (antes do CP1)
- **Inimigos:** 6 Grunts + 2 Flyers
- **Plataformas:** variadas — gaps com plataformas flutuantes, bloco sólido alto (2–3 tiles de altura), seção de chão contínuo
- **Altura:** nível do chão (y baixo)

### Zona 2 (após o pilar, nível elevado)
- **Inimigos:** 5 Grunts + 3 Flyers
- **Plataformas:** chão elevado, plataformas escalonadas, bloco sólido alto, gap com plataforma intermediária
- **Altura:** nível alto (o jogador subiu pelo pilar)
- A zona desce de volta ao nível do chão ao final

### Zona 3 (antes do CP2)
- **Inimigos:** 4 Grunts + 2 Flyers
- **Plataformas:** chão contínuo com gap e plataforma intermediária
- **Altura:** nível do chão

---

## Mecânica Nova: Wall Jump (estilo Mega Man X)

### Comportamento
- Ao pressionar contra uma parede no ar, o personagem **desliza para baixo lentamente** (wall slide)
- Ao pressionar `jump` durante o wall slide, o personagem **salta diagonalmente** para longe da parede
- O jogador pode voltar à mesma parede e repetir — subindo o pilar pela mesma face (mesmo lado, estilo MMX)
- Funciona em qualquer parede detectada por `is_on_wall()` — sem tag especial necessária

### Implementação em CharacterBase
- Adicionar estado `WALL_SLIDE` ao loop de física
- Detectar `is_on_wall()` enquanto no ar
- Reduzir `velocity.y` a um máximo de `WALL_SLIDE_SPEED` (ex: 60 px/s) ao deslizar
- Ao pressionar `jump` no estado `WALL_SLIDE`: aplicar `WALL_JUMP_VELOCITY` com componente horizontal oposta à parede
- Constantes sugeridas:
  - `WALL_SLIDE_SPEED := 60.0`
  - `WALL_JUMP_H := 280.0` (horizontal, para longe)
  - `WALL_JUMP_V := -420.0` (vertical, para cima)

### Pilar de introdução
- Posicionado entre CP1 e Zona 2
- Parede única à esquerda, alta o suficiente para exigir 3–4 wall jumps consecutivos
- Plataforma no topo como recompensa/saída
- Chão à direita do pilar permite tentativas repetidas sem punição de morte

---

## Checkpoints — Estilo Mega Man X

Ambos os checkpoints seguem o mesmo padrão de corredor com duas portas (shutters).

### Estrutura de um checkpoint
1. **Porta de entrada** (shutter) — AnimatedSprite2D ou StaticBody2D com animação de descida; abre ao jogador encostar
2. **Corredor safe** (~300px) — sem inimigos, sem buracos, chão plano
   - Ao entrar: `StageManager.set_checkpoint()` salva a posição de saída do corredor
   - Ao entrar: recupera HP totalmente (refill total — stage introdutório)
3. **Porta de saída** (shutter) — abre ao chegar no fim do corredor

### CP1
- Saída do corredor dá acesso ao pilar de wall jump
- Spawn após morte: saída do corredor CP1

### CP2
- **A porta de saída do corredor CP2 é a porta de entrada da Boss Room**
- Saída do corredor dá acesso direto à arena do boss
- Spawn após morte no boss: saída do corredor CP2

### Implementação de cada porta (shutter)
- `StaticBody2D` com `CollisionShape2D` (bloqueio físico enquanto fechada)
- `AnimatedSprite2D` com animação "open" (desce) e "close" (sobe)
- `Area2D` trigger na frente: ao player entrar → toca animação open → após animação, desabilita collider
- Porta de entrada: após o jogador cruzá-la completamente (body_exited do trigger), toca animação close e reabilita collider — impede retorno ao trecho anterior

---

## Boss Room — Estilo Mega Man X

### Estrutura
- Sala **completamente fechada**: teto sólido, paredes laterais, chão plano
- Dimensões: ~800px de largura × ~600px de altura
- Sem plataformas ou obstáculos no interior
- **Decoração de chão**: linhas horizontais alternadas (estilo MMX)
- Background separado do resto da fase (tons vermelhos/escuros)

### Entrada na arena
1. Jogador passa pela porta do CP2
2. A parede/porta **fecha atrás** do jogador (StaticBody2D spawna ou anima fechando)
3. Boss **entra caminhando** pelo lado oposto (direita) após breve pausa
4. Barras de HP aparecem no topo da tela (jogador à esquerda, boss à direita)

### Boss — Intro Boss
- Personagem novo, único no jogo (não é um dos 8 elementais)
- Nome a definir (ex: "Enforcer", "Warden", algo neutro/genérico)
- Design mais simples que os elementais — serve como tutorial de boss fight
- **2–3 padrões de ataque:**
  1. Avanço (dash horizontal em direção ao jogador)
  2. Projetil (dispara 1–2 projéteis em linha reta)
  3. (Opcional fase 2) Combinação dos dois em velocidade maior
- Sem fraqueza elemental — dano padrão de todos os ataques do jogador
- HP e dano balanceados para ser derrotável na primeira tentativa por um jogador atento

---

## Background — Cidade Destruída

### Composição
- **Camada de fundo (parallax lento):** silhuetas de prédios em tons escuros (#0e0e1d)
- **Detalhes dos prédios:** topos irregulares/destruídos, janelas laranja (#f84) simulando incêndios
- **Névoa na base:** gradiente escuro separando BG do terreno de jogo
- **Zona do boss:** prédios em tons avermelhados (#1a0808), mais janelas vermelhas (#f44)

### Implementação
- `ParallaxBackground` com 1–2 camadas no Godot
- Sprites de prédios desenhados em código (`_draw()`) ou sprites estáticos
- A fase da cidade destruída comunica o contexto narrativo: o mundo já está em colapso quando Stage 00 começa

---

## Respawn de Inimigos por Zona

### Lógica
- Cada zona tem uma `Area2D` abrangendo toda a extensão da zona (trigger invisível)
- Quando o jogador **sai** da area e **entra novamente**, os inimigos da zona são reinstanciados
- Implementado em `stage_00_scene.gd`:
  - `_zone_1_entered()`, `_zone_2_entered()`, etc.
  - Array de referências de inimigos por zona; ao respawn, `queue_free()` nos vivos e `instantiate()` novamente

---

## Arquivos Afetados / Criados

| Arquivo | Ação |
|---|---|
| `characters/base/character_base.gd` | Modificar — adicionar wall slide + wall jump |
| `stages/stage_00/stage_00_scene.gd` | Modificar — novo layout, zonas, respawn, checkpoints MMX |
| `stages/stage_00/stage_00.tscn` | Modificar — reposicionar plataformas, pilar, corrredores, boss room |
| `characters/bosses/intro_boss.gd` | Criar — AI do boss introdutório |
| `characters/bosses/intro_boss.tscn` | Criar — cena do boss |
| `ui/checkpoint_door.gd` | Criar — lógica do shutter (abre/fecha) |
| `ui/checkpoint_door.tscn` | Criar — cena reutilizável da porta |

---

## Fora do Escopo

- Sprites/animações reais (fase usa tiles e formas geométricas existentes)
- Som e música (já tratados no Plan 15)
- Alterações no sistema de save além do que já existe em `StageManager`
- Mudanças em outros stages
