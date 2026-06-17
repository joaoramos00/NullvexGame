# Stage 01 Fire Enemies Sprite Design

**Data:** 2026-06-17  
**Escopo:** 9 sprites de inimigos comuns para `stage_01`  
**Base visual:** inimigos de Mega Man X como referência de linguagem, com identidade própria do projeto

## Objetivo

Definir a linguagem visual dos 9 sprites novos do roster de fogo da `stage_01` antes de gerar a arte. A meta é criar inimigos com leitura imediata em gameplay, aparência de reploid/robô animal, e consistência suficiente para uso direto em Godot com `Sprite2D`.

Os 9 sprites se dividem em:

- 3 melee
- 3 ranged
- 3 fly

Um dos ranged obrigatoriamente será uma criatura que sobe do poço de lava e cospe fogo.

## Direção Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecânica e compacta
- corpo com placas, juntas, pistões, parafusos ou segmentos artificiais
- olhos, núcleo ou visor com brilho forte
- leitura limpa em escala pequena
- identidade de reploid ou robô animal, não de fantasia orgânica

O visual deve evitar:

- roupas, mantos, tecidos ou ornamentos de fantasia
- anatomia orgânica macia
- excesso de detalhes finos que se perdem em jogo
- ilustração “painterly” ou aparência de concept art
- silhuetas grandes demais para um inimigo comum

### Famílias Visuais

O roster deve usar três famílias visuais para evitar que os 9 inimigos pareçam variações do mesmo corpo:

- **A — Tropas reploids blindadas:** inimigos compactos, militares, com placas de armadura, visores e núcleos de calor.
- **B — Criaturas robóticas de fogo:** silhuetas mais animais ou elementais, mas sempre com carcaça mecânica, juntas e segmentos artificiais.
- **C — Máquinas industriais de lava:** corpos mais funcionais e pesados, com pistões, vents, fornalhas, turbinas ou bocas de canhão.

Cada grupo de função deve conter exatamente um inimigo de cada família A/B/C.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve ser o estado inicial claro do inimigo.
- Para a maioria dos inimigos, esse estado inicial é `idle`.
- A serpente de lava é a exceção: ela não precisa começar em `idle`; pode começar em `submerge`, `emerge` ou outro estado equivalente do ciclo.
- Cada sprite deve manter escala estável entre frames.
- O corpo deve permanecer centrado e legível em cada célula.
- Nenhuma parte importante pode tocar a borda da célula.
- O objetivo é uma sheet compacta e controlada, mas a grade pode ser maior que `3x3` se isso for necessário para uma leitura melhor.
- Não limitar artificialmente a produção a grades pequenas quando a animação precisar de mais espaço ou mais frames.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a função do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` são permitidos quando melhorarem a leitura real da animação, especialmente para silhuetas ricas, ataques com antecipação clara, ciclos aéreos expressivos ou a serpente de lava. Não usar grades maiores só por estética: o custo de QC e a chance de drift visual aumentam.

Cada inimigo deve ser gerado em uma raw sheet própria. Não misturar inimigos diferentes na mesma raw sheet.

## Ordem De Produção

Gerar e validar os sprites por trio de função:

1. Melee
2. Fly
3. Ranged
4. Projectiles separados: `fire_bolt`, `fire_glob`, `fire_spit`, `heat_mortar_shell`

Cada sheet processada deve manter os artefatos em `assets/generated/stage01_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_01/<enemy>.png` ou `characters/ranged/stage_01/<projectile>.png`.

## Roster E Direção Por Tipo

### Melee

Os 3 melee devem transmitir pressão corporal, avanço e contato físico.

1. `enemy_magma_grunt`
   - família visual A: tropa reploid blindada
   - soldado de magma compacto
   - armadura pesada, pernas curtas, punhos fortes
   - leitura de tropa de linha de frente
   - postura agressiva, simples e clara

2. `enemy_molten_ram`
   - família visual C: máquina industrial de lava
   - unidade de investida com peito ou cabeça reforçada como aríete
   - corpo baixo ou médio, pesado, com placas de fundição, pistões e núcleo quente
   - sensação de impacto frontal, aceleração curta e colisão forte
   - deve parecer uma máquina industrial adaptada para combate, não um soldado maior

3. `enemy_ash_hopper`
   - família visual B: criatura robótica de fogo
   - coelho robô de cinzas/brasa, pequeno e ágil
   - orelhas mecânicas curtas ou antenas em formato de orelha
   - foco em salto e mobilidade
   - pernas traseiras elásticas ou segmentadas, com molas/pistões e pés largos
   - núcleo quente visível no torso
   - silhueta menor, mais nervosa, mais dinâmica

### Fly

Os 3 fly devem parecer unidades aéreas ou levitantes de fogo, sempre com leitura mecânica.

4. `enemy_ember_orbiter`
   - família visual B: criatura robótica de fogo
   - pequeno drone orbital com núcleo de brasa
   - anel mecânico ou segmentos orbitando ao redor do núcleo
   - movimento de hover simples com leitura circular
   - também solta tiro de fogo próprio, separado do corpo como projectile

5. `enemy_flame_skimmer`
   - família visual C: máquina industrial de lava
   - flyer mais veloz e agressivo
   - corpo alongado, carenagem ou asas mecânicas
   - pode usar turbina, vent ou carenagem de máquina térmica
   - sensação de rasante e ataque de passagem

6. `enemy_cinder_flyer`
   - família visual A: tropa reploid blindada
   - drone ou criatura alada de metal
   - corpo mais utilitário e tático
   - leitura clara de inimigo de suporte aéreo

### Ranged

Os 3 ranged devem comunicar ataque à distância com foco em timing visual.

7. `enemy_heat_mortar`
   - família visual A: tropa reploid blindada
   - reploid compacto com morteiro ou canhão de ombro/costas
   - postura de preparar tiro em arco, diferente de um atirador horizontal
   - disparo parabólico para diferenciar do `enemy_ice_archer` da `stage_02`
   - leitura de unidade militar de apoio indireto

8. `enemy_magma_turret`
   - família visual C: máquina industrial de lava
   - unidade estacionária
   - corpo mais quadrado e defensivo
   - foco em canhão, boca de disparo ou núcleo frontal
   - pode parecer uma fornalha/turreta de fundição
   - pouco ou nenhum deslocamento corporal

9. `enemy_lava_serpent`
   - família visual B: criatura robótica de fogo
   - criatura mecânica de lava que emerge do poço
   - não precisa começar em `idle`
   - ciclo visual: submerge -> emerge -> estado visível -> cuspir fogo -> retornar
   - corpo de serpente ou enguia robótica, com segmentos rígidos e partes blindadas
   - a leitura deve deixar claro que ela nasce do lava pool, não do chão seco

## Regras Específicas Da Serpente De Lava

O inimigo ranged especial deve ser tratado como uma peça de espetáculo tático, mas ainda com linguagem de inimigo comum:

- surge de lava ou de um poço
- carcaça mecânica com segmentos ou placas
- núcleo de calor visível
- boca, chaminé ou lançador frontal de fogo
- o ciclo visual precisa comunicar a ideia de subir, expor-se, cuspir fogo e voltar a desaparecer

Essa criatura pode usar uma sheet mais longa do que as demais se o ciclo precisar. O importante é a clareza do ciclo, não a economia artificial de frames.

## Critérios De Aceitação

Uma geração passa quando:

- os 9 sprites têm leitura consistente entre si
- todos os sprites parecem parte do mesmo roster de fogo
- a estética fica próxima de Mega Man X, mas sem copiar personagens existentes
- a linguagem é mais mecânica do que orgânica
- a serpente de lava comunica emergência do poço e ataque de fogo
- `enemy_heat_mortar` não repete o arquétipo visual nem mecânico do `enemy_ice_archer` da `stage_02`
- `enemy_ember_orbiter` comunica drone orbital e tem projectile próprio
- `enemy_ash_hopper` lê como coelho robô saltador, não como soldado genérico
- o primeiro frame inicial está correto para cada inimigo, exceto a serpente, que pode começar em estado de submersão ou emergência
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- bosses
- sprites de cenário
- layout da stage
- comportamento de combate além do que for necessário para a leitura visual do sprite
