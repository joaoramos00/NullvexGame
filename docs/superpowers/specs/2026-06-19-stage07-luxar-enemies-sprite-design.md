# Stage 07 Luxar Enemies Sprite Design

**Data:** 2026-06-19
**Escopo:** 9 sprites de inimigos comuns para `stage_07` e 4 sprites separados de projeteis/FX
**Base visual:** inimigos de plataforma 2D inspirados em Mega Man X, com identidade propria do projeto
**Tema de dominio:** luz, reflexo, templo de cristal, clareira celestial, feixes horizontais e tecnologia solar

## Objetivo

Definir a linguagem visual dos inimigos comuns da `stage_07` antes de gerar a arte. A meta e criar um roster com leitura imediata em gameplay, forte identidade de luz/reflexo, e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Luxar e o boss de luz da fase 07. O sprite atual le como um leao solar reploid, com juba branca, raios dourados, armadura azul/dourada, postura nobre e silhueta pesada de felino mecanico. No script, Luxar flutua acima do player, se reposiciona lentamente e dispara feixes horizontais de luz em 2 linhas na fase 1 e 3 linhas na fase 2. Os inimigos comuns devem parecer parte desse dominio sem virar copias menores do boss. A conexao deve aparecer em placas brancas e douradas, lentes azuis, prismas, vitrais, espelhos, raios solares compactos, halos fragmentados e tecnologia de templo.

O Stage 07 deve diferir do Stage 03 por trocar energia eletrica industrial, amarelo de aviso, bobinas e raios por luz cerimonial, optica, refraxao e cristal sagrado. Tambem deve diferir do Stage 02 por usar cristal branco/dourado de templo, nao gelo azul, frio ou neve. A distribuicao final sera:

- 3 melee/chao
- 4 fly/suspensos ou hazards de luz
- 2 static/ranged

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica compacta e legivel
- paleta branco, dourado, azul claro, cinza claro e pequenos acentos laranja solar
- detalhes de lente, prisma, vitral, espelho ou halo solar
- brilho de luz em core, visor, lamina, chifre ou emissor
- formas de guarda de templo, fauna solar mecanica e infraestrutura optica
- efeitos compactos de brilho, reflexo, feixe e flash
- identidade de reploid, drone, sentinela, pilar ou armadilha luminosa

O visual deve evitar:

- raios eletricos, cabos, bobinas, hazard stripes e amarelo industrial do Stage 03
- gelo, neve, cristal frio e azul dominante do Stage 02
- sombra roxa/preta do Stage 06, exceto quando usada apenas como contraste minimo de outline
- todos os inimigos parecerem leoes pequenos
- efeitos largos dentro da body sheet quando deveriam ser projeteis/FX separados
- brilho branco que estoure a silhueta e apague a leitura do corpo
- reflexos ou halos que encostem nas bordas das celulas

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Guarda solar de templo:** tropas de chao com armadura branca/dourada, escudos-lente, chifres solares, escamas de vidro ou placas cerimoniais.
- **B - Optica suspensa:** drones, insetos e armadilhas com asas de vitral, prismas orbitais, espelhos e flashes compactos.
- **C - Infraestrutura radiante:** pilares, turrets e emissores fixos que disparam feixes, pulsos ou fragmentos de luz.

As tres familias compartilham a linguagem de Luxar:

- A deve parecer a guarda terrestre do dominio solar.
- B deve ocupar o espaco vertical da fase com reflexos e controle de timing.
- C deve parecer parte do templo, como mecanismos construidos para canalizar luz.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Brilhos, flashes, halos e slashes devem ser compactos e presos ao corpo quando fizerem parte da body sheet.
- Projectiles, feixes largos, ondas de flash e efeitos de area devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.
- A paleta clara deve manter outline e contraste suficientes para nao sumir em fundos claros.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para investida pesada, pulo felino, mergulho, flash ou captura luminosa.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao
2. Fly/suspensos e hazards de luz
3. Static/ranged
4. Projectiles separados: `light_bolt`, `prism_shard`, `flash_pulse`, `solar_slash`

Cada sheet processada deve manter artefatos em `assets/generated/stage07_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_07/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 3 inimigos de chao devem reforcar guarda solar, presenca felina e timing de plataforma. O grupo precisa ter um inimigo pesado ambulante para variar a leitura e o ritmo da fase.

1. `enemy_solar_guard`
   - familia visual A: sentinela basica de templo
   - anda em postura firme e ataca com escudo-lente ou lanca curta
   - armadura branca/dourada, visor azul claro, escudo circular ou semi-circular no braco
   - deve parecer guarda comum de Luxar, nao cavaleiro eletrico e nao boss miniatura

2. `enemy_mirror_ram`
   - familia visual A: robo pesado quadrupede de ariete solar
   - corpo robusto, placas espelhadas, chifres/lentes frontais, pernas mecanicas pesadas
   - ataque principal: investida curta refletiva
   - animacao sugerida: idle pesado, abaixa a cabeca, chifres carregam luz, investida curta, impacto, recuo/cooldown
   - deve parecer previsivel e pesado, nao rapido como `enemy_lion_cub_runner`

3. `enemy_lion_cub_runner`
   - familia visual A/B: pequeno corredor felino solar
   - robo baixo inspirado em filhote de leao mecanico, com pequena juba de placas, patas com molas e core dourado
   - corre e faz bote curto
   - deve comunicar fauna robotica de Luxar sem copiar proporcao, juba ou nobreza do boss

### Fly/Suspensos E Hazards De Luz

Os 4 suspensos/hazards devem ocupar espaco vertical, criar pressao de timing e dialogar com reflexo, prismas e feixes.

4. `enemy_glasswing_drone`
   - familia visual B: drone voador de vitral
   - corpo pequeno com asas translucidas tipo cristal/vitral, core azul claro e bordas douradas
   - patrulha e mergulha em ataque curto
   - deve parecer drone de templo, nao ave eletrica de Voltrix

5. `enemy_prism_orbiter`
   - familia visual B/C: nucleo flutuante com prismas compactos
   - esfera/lente central com prismas orbitando perto do corpo
   - carrega e dispara `light_bolt`
   - deve parecer maquina de refraxao, nao wisp de gelo e nao orbiter eletrico

6. `enemy_mirror_moth`
   - familia visual B: inseto mecanico com asas espelhadas
   - paira e emite flash compacto ou pulso de desorientacao visual
   - asas devem parecer espelhos/vitral, com corpo pequeno dourado e visor azul
   - deve comunicar luz/flash sem virar borboleta natural ou flyer generico

7. `enemy_sun_grabber`
   - familia visual B/C: armadilha suspensa de captura luminosa
   - nucleo solar pequeno com garras-lente ou bracos curtos de luz solida
   - comunica prender, atrasar ou puxar o player por um pulso de luz
   - body sheet deve mostrar nucleo armando, lentes abrindo e pose de captura; nao deve mostrar o player

### Static/Ranged

Os 2 static/ranged devem reforcar a infraestrutura optica do Stage 07 e a relacao com os feixes horizontais de Luxar.

8. `enemy_radiant_pylon`
   - familia visual C: pilar fixo de templo
   - pedestal branco/dourado com cristal ou lente no topo
   - emite `flash_pulse` ou pulso vertical compacto
   - deve parecer mecanismo do cenario, nao criatura e nao cristal de gelo

9. `enemy_beam_turret`
   - familia visual C: torre baixa de lente solar
   - turret instalado em plataforma com lente frontal dourada/azul
   - dispara `light_bolt` ou feixe horizontal compacto
   - deve ler como arma instalada de luz, nao canhao eletrico com bobina

## Projectiles E FX Separados

Projectiles devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `light_bolt`
   - disparo horizontal compacto de luz branca/dourada
   - usado por `enemy_prism_orbiter` e `enemy_beam_turret`
   - centro branco quente, borda dourada/azul claro, rastro curto

2. `prism_shard`
   - fragmento fisico de cristal/luz
   - usado por `enemy_glasswing_drone`, `enemy_mirror_moth` ou `enemy_radiant_pylon`
   - deve parecer estilhaco de vidro sagrado, nao gelo e nao pedra

3. `flash_pulse`
   - pulso circular ou explosao compacta de luz
   - usado por `enemy_mirror_moth`, `enemy_sun_grabber` e `enemy_radiant_pylon`
   - deve parecer flash de lente, nao explosao eletrica e nao fogo

4. `solar_slash`
   - arco curto de luz para melee
   - usado por `enemy_solar_guard`, `enemy_mirror_ram` ou `enemy_lion_cub_runner`
   - deve parecer corte solar compacto, nao raio eletrico e nao vento

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 07 de Luxar
- o tema de luz/reflexo/templo cristalino e mais forte que eletricidade, gelo, sombra, vento ou gravidade
- os inimigos usam linguagem solar/felina/optica sem repetir o boss em miniatura
- cada funcao tem leitura imediata em gameplay: guard, ram, runner, drone, orbiter, moth, grabber, pylon ou turret
- a paleta branco/dourado/azul claro domina com outline suficiente para gameplay
- `enemy_mirror_ram` comunica peso, quadrupede e investida curta refletiva
- `enemy_lion_cub_runner` comunica rapidez e pulo curto sem parecer pesado
- `enemy_prism_orbiter` e `enemy_beam_turret` comunicam disparo de luz sem lembrar Voltrix
- `enemy_radiant_pylon` e `enemy_prism_orbiter` comunicam cristal/optica sem lembrar Cryovex
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Luxar
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
