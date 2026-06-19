# Stage 08 Terragor Enemies Sprite Design

**Data:** 2026-06-19
**Escopo:** 9 sprites de inimigos comuns para `stage_08` e 4 sprites separados de projeteis/FX
**Base visual:** inimigos de plataforma 2D inspirados em Mega Man X, com identidade propria do projeto
**Tema de dominio:** terra, pedra, caverna, musgo, raizes, fosseis, veios minerais e maquinas subterraneas

## Objetivo

Definir a linguagem visual dos inimigos comuns da `stage_08` antes de gerar a arte. A meta e criar um roster com leitura imediata em gameplay, identidade forte de terra/caverna e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Terragor e o boss de terra da fase 08. A direcao ja estabelecida o define como um gorila de pedra: corpo pesado, punhos grandes, placas rochosas, espinhos de pedra e postura de impacto no chao. Os inimigos comuns devem parecer subordinados ao mesmo dominio sem virar copias menores do boss. A conexao deve aparecer em placas de rocha, metal oxidado, musgo, raizes mecanicas, fosseis, cristais de rocha ambar e ataques de impacto terrestre.

O Stage 08 deve diferir do Stage 04 por nao usar gravidade, energia roxa, orbitais cosmicos ou distorcao espacial como linguagem principal. Tambem deve diferir do Stage 02 por evitar gelo, branco/ciano e cristais frios; os minerais do Stage 08 devem parecer rocha profunda, ambar, quartzo terroso ou veios de caverna. A distribuicao final sera:

- 3 melee/chao
- 3 fly/suspensos
- 3 static/ranged/armadilhas

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica compacta
- leitura clara mesmo com materiais terrosos
- placas de pedra, metal enterrado, musgo, raizes e minerais ambar
- paleta marrom terra, cinza pedra, verde musgo e pequenos highlights minerais
- ataques fisicos, impacto no chao, brocas, arremesso de pedra e aprisionamento por raiz
- identidade de reploid subterraneo, drone de caverna, torre talhada ou armadilha organica mecanica

O visual deve evitar:

- gravidade roxa/orbital do Stage 04
- gelo azul, branco e cristal frio do Stage 02
- fogo/lava do Stage 01 como linguagem principal
- vento/teal do Stage 05
- luz dourada/branca do Stage 07
- todos os inimigos parecerem golems ou gorilas menores
- efeitos largos dentro da body sheet quando deveriam ser projeteis/FX separados
- sprites cortados por pedras, raizes, asas ou ondas passando da borda da celula

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Tropas de pedra e escavacao:** unidades de chao com armadura rochosa, metal oxidado, brocas e impacto fisico.
- **B - Fauna mineral suspensa:** drones ou criaturas mecanicas de caverna com asas minerais, corpo fossilizado ou nucleo de minerio.
- **C - Ruinas organicas e artilharia terrestre:** armadilhas fixas, raizes mecanicas, totens e torres que controlam solo, pedras e pulsos de musgo.

As tres familias compartilham a linguagem de Terragor:

- A deve parecer a guarda terrestre e pesada do dominio.
- B deve preencher o espaco vertical sem parecer gravidade ou gelo.
- C deve parecer infraestrutura antiga/subterranea da fase.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Pedras, raizes, poeira, cristais e ondas devem ficar compactos quando fizerem parte da body sheet.
- Projeteis, ondas sismicas largas, raizes de aprisionamento e efeitos de area devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.
- A paleta terrosa deve ter contraste suficiente para nao virar mancha marrom em gameplay.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para broca saindo do chao, raiz prendendo, planador batendo asas, pulso de totem ou impacto sismico.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao
2. Fly/suspensos
3. Static/ranged/armadilhas
4. Projectiles separados: `stone_shot`, `ore_shard`, `root_bind`, `quake_wave`

Cada sheet processada deve manter artefatos em `assets/generated/stage08_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_08/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 3 inimigos de chao devem reforcar peso, escavacao e combate proximo. Eles devem dialogar com Terragor por materia e impacto, mas sem repetir a silhueta de gorila do boss.

1. `enemy_terra_grunt`
   - familia visual A: soldado basico de pedra e metal oxidado
   - anda no chao e ataca com braco pesado ou clava curta integrada
   - armadura marrom/cinza, visor pequeno verde-musgo e ombros rochosos
   - deve parecer tropa comum de caverna, nao mini Terragor e nao golem puro

2. `enemy_mossback_brute`
   - familia visual A/C: pesado caminhante coberto de musgo
   - corpo largo com placas de rocha, pernas mecanicas fortes e musgo nos ombros/costas
   - comunica ataque de impacto: bater os dois bracos no chao para soltar `quake_wave`
   - deve parecer um robo pesado que anda, nao uma torre fixa

3. `enemy_drill_mole`
   - familia visual A: robo-toupeira de escavacao
   - corpo baixo com broca frontal, garras curtas e placas de terra nas costas
   - comunica entrar/sair do chao e avancar em linha reta
   - deve sugerir fauna robotica subterranea sem virar animal natural

### Fly/Suspensos

Os 3 inimigos voadores/suspensos devem ocupar o espaco vertical com materia mineral e caverna. Eles devem evitar orbitas de gravidade e cristal frio.

4. `enemy_gem_wasp`
   - familia visual B: vespa mecanica de minerio
   - asas minerais finas, ferrão de cristal ambar e corpo pequeno metalico
   - patrulha em zigue-zague curto e dispara `ore_shard`
   - deve parecer inseto subterraneo mecanico, nao drone eletrico e nao gelo

5. `enemy_stone_glider`
   - familia visual B: planador de caverna
   - asas de pedra fina ou fossil, corpo mecanico achatado e cauda mineral curta
   - voa em linha horizontal ou diagonal lenta, com poucos frames de batida/planeio
   - deve parecer criatura de caverna adaptada ao vento interno, nao inimigo do Stage 05

6. `enemy_ore_orbiter`
   - familia visual B/C: nucleo flutuante de minerio
   - core mecanico ambar com pequenas pedras presas por hastes ou magnetos fisicos compactos
   - carrega e dispara `stone_shot`
   - deve parecer maquina mineral suspensa, nao anomalia gravitacional do Stage 04

### Static/Ranged/Armadilhas

Os 3 static/ranged devem reforcar controle de terreno, ruinas organicas e pressao de posicionamento.

7. `enemy_root_snare`
   - familia visual C: raiz mecanica semi-enterrada
   - base fixa no chao com segmentos de raiz/metal que se abrem para prender
   - comunica aprisionar ou retardar o player com `root_bind`
   - body sheet deve mostrar raiz armando e fechando; nao deve mostrar o player

8. `enemy_boulder_turret`
   - familia visual C: torre de pedra talhada e metal enterrado
   - base baixa instalada em plataforma, canhao de rocha e musgo nas juntas
   - dispara `stone_shot` em linha ou arco curto
   - deve ler como arma instalada da fase, nao como soldado

9. `enemy_fossil_totem`
   - familia visual C: totem de ruina organica com fosseis incrustados
   - coluna fixa de pedra antiga com ossos/fosseis, musgo e core verde escuro
   - pulsa energia pelo chao e pode usar `quake_wave` ou pulso curto de musgo
   - deve parecer antigo/organico, nao torre tecnologica limpa

## Projectiles E FX Separados

Projectiles e FX devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `stone_shot`
   - pedra compacta disparada horizontalmente ou em arco curto
   - usada por `enemy_ore_orbiter` e `enemy_boulder_turret`
   - rocha marrom/cinza com rastro curto de poeira

2. `ore_shard`
   - estilhaco mineral ambar
   - usado por `enemy_gem_wasp`
   - deve parecer minerio quente/terroso, nao cristal de gelo

3. `root_bind`
   - efeito de raiz prendendo ou fechando
   - usado por `enemy_root_snare`
   - deve parecer raiz mecanica verde-musgo/marrom, nao sombra e nao corrente eletrica

4. `quake_wave`
   - onda sismica baixa no chao
   - usada por `enemy_mossback_brute` e `enemy_fossil_totem`
   - deve ficar horizontal, baixa e legivel, sem parecer fogo ou vento

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 08 de Terragor
- o tema de terra/caverna/raiz/mineral e mais forte que gravidade, gelo, fogo, vento, sombra ou luz
- os inimigos dialogam com o gorila de pedra sem copiar a silhueta do boss
- cada funcao tem leitura imediata em gameplay: grunt, brute, mole, wasp, glider, orbiter, snare, turret ou totem
- a paleta marrom/cinza/verde-musgo/ambar domina com contraste suficiente
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- `enemy_ore_orbiter` comunica maquina mineral suspensa sem parecer orbiter gravitacional
- `enemy_root_snare` comunica aprisionamento sem mostrar o player na sprite sheet
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Terragor
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
