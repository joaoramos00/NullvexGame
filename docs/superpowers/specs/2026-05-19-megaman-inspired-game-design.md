# Game Design Document — Projeto Megaman-Inspired
**Data:** 2026-05-19  
**Engine:** Godot 4 (GDScript)  
**Estilo Visual:** HD Pixel Art · 1920×1080

---

## 1. Visão Geral

Jogo de plataforma e ação 2D com estética e mecânicas inspiradas em Mega Man X4. IP original com universo e personagens próprios. Dois personagens jogáveis com estilos completamente distintos, sistema de upgrades por coleta, bosses com fraquezas encadeadas e progressão não-linear pelas fases.

---

## 2. Arquitetura e Estrutura do Projeto

### Estrutura de Pastas
```
res://
├── autoloads/
│   ├── GameManager     # Estado global, save/load, personagem selecionado
│   ├── StageManager    # Fase atual, checkpoint, transições
│   └── AudioManager    # Música e SFX
├── characters/
│   ├── base/           # CharacterBase (movimento, HP, morte)
│   ├── ranged/         # Zael + tipos de tiro + habilidades
│   └── melee/          # Zara + armas + habilidades
├── enemies/            # Inimigos genéricos e bosses
├── stages/             # stage_00 a stage_11
├── collectibles/       # Heart, SubTank, ArmorPiece, BossAbility
├── ui/                 # HUD, menus, stage select
├── shaders/            # Efeitos visuais
└── resources/          # .tres: definições de habilidades, armaduras, fases
```

### Autoloads (Singletons)
- **GameManager** — personagem ativo, HP, habilidades desbloqueadas, armaduras, sub-tanks, save/load
- **StageManager** — carrega/descarrega fases, controla transições
- **AudioManager** — BGM e SFX com fade

**Comunicação:** exclusivamente via sinais do Godot. Nenhum sistema chama outro diretamente.

---

## 3. Personagens

### CharacterBase (herdado por ambos)
- Movimento: correr, pular, pulo duplo, dash (chão e ar)
- HP com máximo expansível via corações
- Invencibilidade temporária após dano
- Morte e respawn no último checkpoint ativo
- Slot de habilidade ativa (troca com L1/R1)

---

### Zael — Personagem Ranged
Ataque à distância com 5 tipos de tiro selecionáveis antes de cada fase.

#### Tipos de Tiro

| # | Tipo   | Sem Armadura de Braço                              | Com Armadura de Braço                                        |
|---|--------|----------------------------------------------------|--------------------------------------------------------------|
| 1 | Single | 3 níveis de carga — dano e tamanho crescem         | 4º nível — leque de 3 projéteis, dano massivo                |
| 2 | Spread | Sem carga — atira frente e trás simultaneamente    | Carregável — versão carregada amplia o leque                 |
| 3 | Rapid  | Cadência alta, disparo frontal, menor dano         | Dispara em 8 direções simultaneamente                        |
| 4 | Laser  | Sem carga — feixe contínuo, perfura 1 inimigo      | Carregável — feixe carregado perfura múltiplos inimigos      |
| 5 | Cannon | Carregável (1 nível) — alto dano, curto alcance    | 2º nível de carga — projétil maior, dano máximo              |

- Single e Cannon são desbloqueados durante a run (Cannon na fase correspondente)
- Spread, Rapid e Laser encontrados em fases específicas (ver Seção 5)

#### Armaduras de Zael

| Peça     | Bônus Passivo                                           |
|----------|---------------------------------------------------------|
| Capacete | Detecta itens escondidos no mapa                        |
| Torso    | Reduz dano recebido em 50%                              |
| Braços   | Adiciona 1 nível de carga a Single, Spread, Laser e Cannon · Rapid muda para 8 direções |
| Pernas   | Andar no ar por um breve momento após sair de plataforma |

**Armadura completa:** Nova Buster — tiro carregado nível máximo atravessa todos os inimigos na linha.

---

### Zara — Personagem Melee
Combate corpo a corpo com 5 armas selecionáveis no stage select.

#### Sistema de Combo
Combo fixo: **2 golpes + finisher**. Apertar ataque em sequência executa automaticamente.

#### Armas de Zara

| Arma        | Golpe 1        | Golpe 2          | Finisher                            | Característica                          |
|-------------|----------------|------------------|-------------------------------------|-----------------------------------------|
| Espada      | Corte horiz.   | Corte vertical   | Onda de energia                     | Equilibrada, alcance médio              |
| Dual Blades | Slash rápido   | Slash rápido     | Explosão dupla                      | Veloz, menor dano por hit               |
| Glaive      | Golpe amplo    | Slam no chão     | Shockwave em área                   | Lento, alto dano e área                 |
| Garras      | Jab            | Jab              | Arremesso do inimigo                | Corpo a corpo puro, move inimigos       |
| Machado     | Golpe pesado   | —                | Crava no chão com shockwave         | 1 golpe + finisher, máximo dano e risco |

- Espada desbloqueada de início
- Dual Blades, Glaive, Garras e Machado encontrados em fases específicas (ver Seção 5)

#### Armaduras de Zara

| Peça     | Bônus Passivo                                                               |
|----------|-----------------------------------------------------------------------------|
| Capacete | Parry — pressionar dash no momento certo teletransporta atrás do inimigo    |
| Torso    | Reduz dano recebido em 50%                                                  |
| Braços   | Segurar ataque carrega um golpe em área que atinge todos ao redor           |
| Pernas   | Dash no chão mais longo + dash na diagonal para cima                        |

**Armadura completa:** Fúria Limitless — modo de fúria permanente com dano aumentado enquanto a armadura estiver equipada.

---

## 4. Estrutura de Fases

### Mapa de Progressão
```
Fase 00 — Intro Stage (obrigatória)
    ↓
Stage Select — 8 fases em qualquer ordem
    ↓
Fases 09, 10, 11 — Estágios Finais (desbloqueados após completar as 8)
    ↓
Fim do jogo
```

### Estrutura Interna de Cada Fase
- Início → seções de plataforma/combate → **Checkpoint 1** → seções finais → **Checkpoint 2** → Boss Arena
- Checkpoint 1: meio da fase
- Checkpoint 2: imediatamente antes do boss
- Ao morrer com vidas: respawn no último checkpoint ativo
- Ao perder todas as vidas: retorna ao início da fase (checkpoints resetados)

### Sistema de Vidas
- Inicia com 3 vidas
- Vidas extras escondidas em fases

---

## 5. Colectáveis e Distribuição

### Tabela de Distribuição — 8 Fases Principais

| Fase | Boss      | Armadura Zael    | Armadura Zara    | Item Extra Zael         | Item Extra Zara         | Coração | Sub-Tank |
|------|-----------|------------------|------------------|-------------------------|-------------------------|---------|----------|
| 01   | Ignarath  | Capacete         | —                | —                       | Dual Blades             | ✓       | —        |
| 02   | Cryovex   | —                | Capacete         | Spread (Tiro 2)         | —                       | ✓       | ✓        |
| 03   | Voltrix   | Torso            | —                | —                       | Glaive                  | ✓       | —        |
| 04   | Gravitus  | —                | Torso            | Rapid (Tiro 3)          | —                       | ✓       | ✓        |
| 05   | Galerix   | Braços           | —                | —                       | Garras                  | ✓       | —        |
| 06   | Umbraex   | —                | Braços           | Laser (Tiro 4)          | —                       | ✓       | ✓        |
| 07   | Luxar     | Pernas           | —                | —                       | Machado                 | ✓       | —        |
| 08   | Terragor  | —                | Pernas           | Cannon (Tiro 5)         | —                       | ✓       | ✓        |

### Colectáveis
- **Corações:** 8 total (1 por fase principal, escondido fora do caminho principal). Aumentam HP máximo de ambos os personagens.
- **Sub-tanks:** 4 total (fases 02, 04, 06, 08). Reservas de HP usadas pelo jogador, recargáveis com drops de inimigos.
- **Armaduras:** 4 peças por personagem. Cada fase principal tem armadura para um personagem apenas.
- **Armas/Tiros:** desbloqueados automaticamente ao encontrar o item escondido na fase correspondente.

---

## 6. Bosses e Sistema de Fraquezas

> **Estágios Finais:**
> - **Fase 09 — Gauntlet:** todos os 8 bosses em sequência (Ignarath → Cryovex → Voltrix → Gravitus → Galerix → Umbraex → Luxar → Terragor). HP e sub-tanks não regeneram entre fights.
> - **Fase 10 — Nullvex, Forma Humanoide:** figura humanoide com fragmentos dos 8 elementos no corpo. Ataca com todos os elementos de forma imprevisível. Sem fraqueza fixa — fica vulnerável a habilidades específicas em momentos pontuais do combate (indicado visualmente).
> - **Fase 11 — Nullvex, Forma Verdadeira:** entidade massiva de energia pura. Mais rápida e agressiva. Duas sub-fases: padrão normal e fase final (último terço do HP) com ataques intensificados.

### Os 8 Bosses

| # | Boss      | Tema             | Habilidade — Zael                                      | Habilidade — Zara                                        |
|---|-----------|------------------|--------------------------------------------------------|----------------------------------------------------------|
| 1 | Ignarath  | Fogo/Lava        | Bola de fogo carregável que explode em área            | Lâmina envolta em chamas — golpes causam queimadura      |
| 2 | Cryovex   | Gelo/Frio        | Projétil de gelo que congela brevemente                | Slash de gelo que cria barreira de cristal               |
| 3 | Voltrix   | Raio/Energia     | Raio em cadeia que salta entre inimigos próximos       | Dash com descarga elétrica — atinge tudo no caminho      |
| 4 | Gravitus  | Gravidade        | Esfera gravitacional que puxa inimigos e projéteis     | Salto de impacto que cria poço gravitacional no chão     |
| 5 | Galerix   | Vento/Tempestade | Rajada de vento que empurra inimigos e projéteis       | Tornado giratório que aspira inimigos próximos           |
| 6 | Umbraex   | Sombra/Escuridão | Dispara clone de sombra que distrai inimigos           | Teleporte de sombra — teletransporta atrás do alvo       |
| 7 | Luxar     | Luz/Reflexo      | Feixe refletido em paredes e superfícies               | Dash de velocidade da luz — atravessa inimigos           |
| 8 | Terragor  | Terra/Rocha      | Estalactites de pedra que caem do teto                 | Soco no chão que cria ondas sísmicas laterais            |

### Cadeia de Fraquezas (ciclo fechado com lógica elemental)
```
Gravitus  → vence Galerix   (gravidade prende o ar, anula vento)
Galerix   → vence Ignarath  (vento apaga chamas)
Ignarath  → vence Cryovex   (fogo derrete gelo)
Cryovex   → vence Terragor  (frio racha pedra — erosão por gelo)
Terragor  → vence Voltrix   (terra aterra eletricidade)
Voltrix   → vence Umbraex   (raio ilumina e dispersa sombras)
Umbraex   → vence Luxar     (escuridão apaga a luz)
Luxar     → vence Gravitus  (luz escapa da gravidade)
```
O jogo não indica as fraquezas explicitamente — o jogador descobre por tentativa e erro.

---

## 7. Estética Visual

- **Resolução:** 1920×1080 nativo
- **Estilo:** HD Pixel Art — sprites em alta resolução com animações fluidas (8-16 frames por animação)
- **Tamanhos de sprite:** personagens ~64×64px, inimigos ~32×48px, bosses ~96×128px, tiles 16×16px
- **Parallax:** 3-4 camadas de profundidade por fase
- **Paleta:** cada fase tem 16-32 cores dominantes com tema próprio
- **Iluminação:** light masks 2D do Godot 4, pontual em bosses e cutscenes
- **Efeitos:** hit-flash branco, screen shake em explosões, hit-stop de 3 frames no golpe final de boss
- **Transições:** fade preto clássico entre fases

---

## 8. HUD e Menus

### HUD (durante gameplay — minimalista)
- Barra de HP do personagem (estilo MMX — ícone + barra vertical)
- Barra de energia da habilidade ativa
- Nada mais — HUD limpo

### Menu de Pausa (Start)
- HP atual / máximo
- Vidas restantes
- Sub-tanks (quantidade e carga)
- Habilidades desbloqueadas com descrição
- Armaduras equipadas e bônus ativos
- Ações: Continuar · Reiniciar fase · Voltar ao Stage Select · Sair

---

## 9. Game Flow e Progressão

### Fluxo Principal
```
Tela de Título
    ↓
Seleção de Personagem (Zael / Zara)
    ↓ Zara → Seleção de Arma Inicial
    ↓ Zael → Seleção de Tipo de Tiro Inicial
    ↓
Stage Select
    ↓ (pode trocar personagem aqui a qualquer momento)
    ↓
Fase → Boss → Habilidade desbloqueada para ambos
    ↓
Retorno ao Stage Select
    ↓
Após 8 fases → Estágios Finais 09, 10, 11
    ↓
Créditos
```

### Save/Load
- **Auto-save:** ao completar uma fase (derrotar boss) ou ao sair pelo menu de pausa → "Voltar ao Stage Select"
- **Um save único** compartilhado entre Zael e Zara
- **Compartilhado:** fases completas, corações, sub-tanks, vidas, HP máximo
- **Separado por personagem:** armaduras, habilidades de boss, armas (Zara), tipos de tiro (Zael)
- Derrotar um boss uma única vez concede a habilidade correspondente para ambos os personagens
