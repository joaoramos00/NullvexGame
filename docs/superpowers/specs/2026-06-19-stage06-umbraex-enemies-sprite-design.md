# Stage 06 Umbraex Enemies Sprite Design

**Data:** 2026-06-19
**Escopo:** 9 sprites de inimigos comuns para `stage_06` e 4 sprites separados de projeteis/FX
**Base visual:** inimigos de plataforma 2D inspirados em Mega Man X, com identidade propria do projeto
**Tema de dominio:** sombra, eclipse, penumbra, teleporte curto, emboscada e tecnologia que apaga luz

## Objetivo

Definir a linguagem visual dos inimigos comuns da `stage_06` antes de gerar a arte. A meta e criar um roster com leitura imediata em gameplay, forte identidade de sombra, e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Umbraex e o boss de sombra da fase 06. O sprite atual le como um reploid sombrio com corpo escuro, chifres ou orelhas altas, detalhes roxos, presenca de morcego/demonio mecanico e ataques baseados em teleporte atras do player mais projeteis roxos em leque. Os inimigos comuns devem parecer parte desse dominio sem virar copias menores do boss. A conexao deve aparecer em silhuetas noturnas, asas ou orelhas de morcego mecanicas, visores roxos, cores preto/roxo/cinza, halos de eclipse, fumaca compacta de sombra e efeitos de faseamento.

O Stage 06 deve diferir do Stage 04 por trocar gravidade, massa e orbitais pesados por furtividade, ocultacao, teleporte, armadilhas de penumbra e tiros sombrios. Tambem deve preparar contraste com o Stage 07, que sera luz: aqui a tecnologia deve absorver ou apagar luz, nao emitir brilho solar. A distribuicao final sera:

- 3 melee/chao
- 4 fly/suspensos ou hazards de sombra
- 2 static/ranged

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica compacta
- leitura clara mesmo com paleta escura
- formas de morcego, sombra viva, assassino mecanico ou maquina de eclipse
- placas preto, roxo escuro, violeta, cinza frio e pequenos highlights magenta/lilas
- brilho de sombra em core, visor, lamina ou emissor
- efeitos compactos de fumaca, faseamento e eclipse
- identidade de reploid, drone, sentinela ou infraestrutura sombria

O visual deve evitar:

- gravidade roxa pesada/orbital do Stage 04
- raios amarelos/azuis do Stage 03
- vento verde/teal do Stage 05
- luz dourada/branca que antecipe o Stage 07
- todos os inimigos parecerem morcegos pequenos
- efeitos largos dentro da body sheet quando deveriam ser projeteis/FX separados
- fumaca solta que reduza ou corte o corpo na celula fixa

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Assassinos de penumbra:** tropas de chao com postura baixa, garras, laminas curtas, teleportes ou emboscadas.
- **B - Drones e sombras suspensas:** unidades voadoras/suspensas com linguagem de morcego, core sombrio, faseamento e armadilhas.
- **C - Maquinas de eclipse:** turrets, lanternas negras, minas e emissores que apagam luz ou disparam projeteis de sombra.

As tres familias compartilham a linguagem de Umbraex:

- A deve parecer a guarda de emboscada do dominio.
- B deve trazer a heranca de morcego/chifres/sombra do boss sem copiar seu corpo.
- C deve parecer infraestrutura da fase que controla penumbra e projeteis escuros.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Fumaca, teleporte, slashes e halos devem ser compactos e presos ao corpo quando fizerem parte da body sheet.
- Projectiles, ondas largas, tether de aprisionamento e efeitos de area devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.
- A paleta escura deve ter contraste suficiente para nao virar mancha preta em gameplay.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para teleporte, captura por sombra, faseamento, mergulho ou pulso de eclipse.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao
2. Fly/suspensos e hazards de sombra
3. Static/ranged
4. Projectiles separados: `shadow_bolt`, `void_shard`, `snare_pulse`, `phase_slash`

Cada sheet processada deve manter artefatos em `assets/generated/stage06_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_06/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 3 inimigos de chao devem reforcar emboscada e combate proximo. Eles nao devem parecer pesados; o Stage 06 deve parecer furtivo e perigoso por posicionamento.

1. `enemy_shadow_stalker`
   - familia visual A: soldado baixo de emboscada
   - anda em postura agachada e ataca com garra curta
   - armadura preto/roxo, visor lilas, ombros angulares e pequenos detalhes de fumaca
   - deve parecer tropa de chao, nao morcego completo e nao heavy unit

2. `enemy_eclipse_duelist`
   - familia visual A: duelista de lamina escura
   - inimigo de contato com lamina curta ou tonfa de eclipse
   - postura elegante e agressiva, peito com core roxo e halo pequeno
   - deve parecer assassino mecanico, nao cavaleiro de luz e nao Voltrix

3. `enemy_night_pouncer`
   - familia visual A/B: saltador de emboscada
   - corpo compacto com pernas fortes, orelhas/chifres curtos e pequenas asas dobradas
   - faz pulo curto ou bote, com fumaca de sombra compacta
   - deve sugerir fauna robotica noturna sem virar animal natural

### Fly/Suspensos E Hazards De Sombra

Os 4 suspensos/hazards devem ocupar espaco vertical, criar pressao de timing e dialogar com o teleporte de Umbraex.

4. `enemy_umbra_bat`
   - familia visual B: drone morcego de patrulha
   - silhueta de morcego mecanico com asas angulares, core roxo e visor pequeno
   - patrulha e mergulha em ataque curto
   - deve parecer servo aereo de Umbraex, nao copia miniatura do boss

5. `enemy_void_orbiter`
   - familia visual B/C: core sombrio flutuante
   - esfera ou olho mecanico escuro com fragmentos orbitais compactos
   - carrega e atira `shadow_bolt`
   - deve parecer maquina de sombra, nao mina de gravidade do Stage 04

6. `enemy_shadow_snare`
   - familia visual B/C: armadilha suspensa de aprisionamento
   - nucleo de penumbra com garras/fitas curtas de sombra
   - comunica prender ou retardar o player com pulso compacto
   - body sheet deve mostrar nucleo armando, fitas abrindo e pose de captura; nao deve mostrar o player

7. `enemy_phase_mine`
   - familia visual C/B: mina de faseamento
   - pequena mina escura que aparece/desaparece antes de pulsar
   - halo de eclipse curto, segmentos pretos e core lilas
   - deve parecer armadilha de sombra temporizada, nao mina gravitacional pesada

### Static/Ranged

Os 2 static/ranged devem reforcar a infraestrutura sombria do Stage 06.

8. `enemy_dark_lantern`
   - familia visual C: lanterna negra fixa
   - torre baixa ou pedestal que emite pulso escuro
   - parece sugar luz ao redor, com chama roxa ou core invertido
   - usa `snare_pulse` ou pulso de area pequeno

9. `enemy_eclipse_turret`
   - familia visual C: canhao baixo de sombra
   - turret instalado em plataforma com emissor roxo e placas negras
   - dispara `shadow_bolt` em linha
   - deve ler como arma instalada, nao como soldado

## Projectiles E FX Separados

Projectiles devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `shadow_bolt`
   - disparo horizontal compacto de sombra roxa
   - usado por `enemy_void_orbiter` e `enemy_eclipse_turret`
   - centro violeta, borda preta/roxa, rastro curto

2. `void_shard`
   - fragmento fisico/energetico escuro
   - usado por `enemy_umbra_bat` ou `enemy_phase_mine`
   - deve parecer estilhaco de sombra, nao pedra de gravidade

3. `snare_pulse`
   - pulso circular de aprisionamento
   - usado por `enemy_shadow_snare` e `enemy_dark_lantern`
   - deve parecer anel de sombra ou corrente compacta, nao explosao grande

4. `phase_slash`
   - arco curto de sombra para melee/teleporte
   - usado por `enemy_shadow_stalker`, `enemy_eclipse_duelist` ou `enemy_night_pouncer`
   - deve parecer corte escuro, nao vento e nao eletricidade

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 06 de Umbraex
- o tema de sombra/penumbra/teleporte e mais forte que gravidade, eletricidade, vento ou luz
- os inimigos usam linguagem de morcego/chifres/sombra sem repetir o boss em miniatura
- cada funcao tem leitura imediata em gameplay: stalker, duelista, pouncer, bat, orbiter, snare, mine, lantern ou turret
- a paleta preto/roxo/violeta/cinza domina com contraste suficiente
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- `enemy_shadow_snare` comunica aprisionamento/retardo sem precisar mostrar o player na sprite sheet
- `enemy_phase_mine` comunica faseamento sem parecer uma mina gravitacional do Stage 04
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Umbraex
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
