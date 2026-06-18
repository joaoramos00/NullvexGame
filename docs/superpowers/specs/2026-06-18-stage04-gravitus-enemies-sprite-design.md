# Stage 04 Gravitus Enemies Sprite Design

**Data:** 2026-06-18
**Escopo:** 9 sprites de inimigos comuns para `stage_04` e 4 sprites separados de projeteis/FX
**Base visual:** inimigos de Mega Man X como referencia de linguagem, com identidade propria do projeto
**Tema de dominio:** estacao espacial e antigravidade comandada por Gravitus, um boss urso gravitacional

## Objetivo

Definir a linguagem visual dos inimigos comuns da `stage_04` antes de gerar a arte. A meta e criar um roster com leitura imediata em gameplay, aparencia de reploid/maquina gravitacional, e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Gravitus e um boss de gravidade com base de urso gravitacional: corpo pesado, lento, poderoso, com materia densa, olhos como buracos negros, halo de debris e efeitos de distorcao espacial. Os inimigos comuns devem parecer parte do dominio dele sem virar copias menores do boss. A conexao deve aparecer em ombros largos, patas magneticas, nucleos brancos gravitacionais, aneis orbitais, debris preso ao corpo, placas densas e silhuetas de peso/pressao.

O Stage 04 deve diferir do Stage 03 por trocar pressao aerea eletrica por peso, atracao, esmagamento, orbitas e controle de timing. A distribuicao final sera:

- 3 melee/chao
- 3 fly/aereos ou hazards suspensos
- 3 static/ranged

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica e compacta
- corpo pesado, denso ou orbital
- nucleo branco/roxo de gravidade como ponto focal
- placas roxo escuro, bordo, preto e cinza-metal
- brilho gravitacional branco-lavanda em visor, nucleo, emissor ou anel orbital
- leitura limpa em escala pequena
- identidade de reploid, drone, maquina espacial ou fauna robotica pesada

O visual deve evitar:

- raios amarelos/azuis do Stage 03
- fogo, gelo, sombra organica ou cristal como linguagem principal
- todos os inimigos parecerem ursos menores
- excesso de particulas soltas que reduzam o corpo na celula fixa
- efeitos largos dentro da body sheet quando deveriam ser projeteis/FX separados

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Guardas orbitais pesados:** soldados e unidades de seguranca da estacao, com armadura densa, nucleos gravitacionais, ombros largos e visores roxos/brancos.
- **B - Fauna robotica gravitacional:** inimigos inspirados em urso ou massa animal pesada, sempre mecanicos e comuns, nao boss-scale.
- **C - Maquinas de anomalia espacial:** turrets, geradores, minas, pylons, debris e equipamentos que manipulam gravidade.

As tres familias compartilham a linguagem de Gravitus:

- A deve parecer a tropa militar/operacional da estacao antigravidade.
- B deve trazer a heranca do urso gravitacional sem copiar o boss.
- C deve parecer infraestrutura espacial que virou defesa ativa.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Orbitas, debris, pulsos e distorcoes devem ser compactos e presos ao corpo quando fizerem parte da body sheet.
- Projectiles, ondas largas e efeitos de area devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para investidas pesadas, ciclos de orbita, geradores carregando ou efeitos de compressao.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao
2. Fly/aereos e hazards suspensos
3. Static/ranged
4. Projectiles separados: `gravity_bolt`, `mass_pulse`, `orbit_shard`, `crush_wave`

Cada sheet processada deve manter artefatos em `assets/generated/stage04_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_04/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 3 inimigos de chao devem criar sensacao de peso e pressao fisica. Eles ancoram o stage no piso enquanto os hazards orbitais e gravitacionais controlam o espaco.

1. `enemy_grav_guard`
   - familia visual A: guarda orbital pesado
   - soldado reploid compacto da seguranca da estacao de Gravitus
   - armadura roxo/preto, placas bordo, visor branco-lavanda e nucleo gravitacional no peito
   - ombros largos, pes pesados e punhos densos
   - ataca com soco curto ou postura de impacto gravitacional
   - deve parecer tropa de chao, nao urso e nao turret

2. `enemy_mass_brute`
   - familia visual B: fauna robotica gravitacional
   - robo quadrupede baixo inspirado em urso, comum e menor que Gravitus
   - patas magneticas, ombros grandes, nucleo escuro/roxo, placas densas
   - movimento de investida curta e pesada
   - deve ler como brute de contato, nao como mini-boss

3. `enemy_orbit_mauler`
   - familia visual A/C: guarda pesado com anomalia orbital
   - unidade de chao com dois pesos/debris orbitando perto do corpo
   - corpo lento, nucleo gravitacional central e bracos curtos
   - ataca quando os pesos orbitais giram para frente
   - deve comunicar orbita e timing sem depender de efeito largo

### Fly/Aereos E Hazards Suspensos

Os 3 aereos/hazards devem ocupar espaco vertical sem repetir o Stage 03. Aqui o voo deve parecer suspensao por gravidade, nao agilidade eletrica.

4. `enemy_void_drone`
   - familia visual A/C: drone de patrulha orbital
   - drone flutuante circular ou triangular, com nucleo branco e placas roxo/preto
   - pequenos fragmentos orbitais presos proximo ao corpo
   - dispara `gravity_bolt` como projectile separado
   - deve parecer maquina de seguranca espacial, nao nave generica

5. `enemy_gravity_mine`
   - familia visual C: mina gravitacional suspensa
   - hazard flutuante que pulsa e cria ameaca de area
   - casca escura segmentada, nucleo branco/roxo, aneis curtos orbitando
   - pode armar, expandir glow compacto e recuperar
   - deve ler como mina/armadilha, nao como drone com arma

6. `enemy_debris_orbiter`
   - familia visual C: anomalia de debris mecanico
   - fragmentos mecanicos orbitando um nucleo instavel
   - movimento circular/rotacional e pulsos de gravidade
   - contrasta com drones militares por parecer equipamento quebrado preso em campo gravitacional
   - pode usar `orbit_shard` como projectile/FX separado se necessario

### Static/Ranged

Os 3 static/ranged devem reforcar a estacao espacial e o controle de area. Eles devem ter carga visual clara e funcionar como equipamentos defensivos ativos.

7. `enemy_singularity_turret`
   - familia visual C/A: turret de singularidade
   - canhao baixo instalado em piso ou parede da estacao
   - carrega um ponto branco/roxo e dispara `gravity_bolt`
   - corpo angular, placas roxo/preto, capacitores bordo e emissor circular
   - deve ler como arma instalada, nao como soldado

8. `enemy_grav_well`
   - familia visual C: gerador fixo de poco gravitacional
   - base industrial, nucleo escuro no centro, aneis orbitais curtos
   - visualmente comunica puxao/controle de area
   - carrega e emite `mass_pulse`
   - deve parecer maquina de campo gravitacional, nao turret direcional

9. `enemy_crush_pylon`
   - familia visual C: pilar de compressao gravitacional
   - pylon fixo de teto/chao ou torre curta da estacao
   - carrega energia em segmentos e libera `crush_wave`
   - placas densas, nucleo vertical branco-lavanda, marcas bordo
   - deve parecer infraestrutura/hazard, nao inimigo vivo

## Projectiles E FX Separados

Projectiles devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `gravity_bolt`
   - disparo compacto horizontal roxo/branco
   - usado por `enemy_void_drone` e `enemy_singularity_turret`
   - leitura rapida, com centro branco e borda roxa

2. `mass_pulse`
   - pulso radial curto de massa/atracao
   - usado por `enemy_grav_well` e possivelmente `enemy_gravity_mine`
   - deve parecer onda compacta, nao explosao elemental

3. `orbit_shard`
   - fragmento/debris girando com trilha gravitacional curta
   - usado por `enemy_orbit_mauler` ou `enemy_debris_orbiter`
   - deve parecer objeto fisico sendo arremessado por gravidade

4. `crush_wave`
   - onda curta de compressao gravitacional
   - usada por `enemy_crush_pylon` e possivelmente `enemy_mass_brute`
   - deve ser mais plana/densa que `mass_pulse`

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 04 de Gravitus
- o tema de gravidade/antigravidade e mais forte que velocidade eletrica ou voo livre
- os inimigos usam linguagem de urso gravitacional sem repetir o boss em miniatura
- cada funcao tem leitura imediata em gameplay: chao pesado, suspenso, turret, gerador ou pylon
- a paleta roxo/preto/bordo/branco domina sem virar sombra do Stage 06
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Gravitus
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
