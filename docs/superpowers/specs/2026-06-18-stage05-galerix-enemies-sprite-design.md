# Stage 05 Galerix Enemies Sprite Design

**Data:** 2026-06-18
**Escopo:** 9 sprites de inimigos comuns para `stage_05` e 4 sprites separados de projeteis/FX
**Base visual:** inimigos de plataforma 2D inspirados em Mega Man X, com identidade propria do projeto
**Tema de dominio:** plataformas aereas, vento, correntes de ar e tecnologia de turbinas comandadas por Galerix

## Objetivo

Definir a linguagem visual dos inimigos comuns da `stage_05` antes de gerar a arte. A meta e criar um roster com leitura imediata em gameplay, forte identidade de vento, e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Galerix e o boss de vento da fase 05. O sprite atual le como um reploid aviario/raptor de vento: corpo leve, crista ou penas metalicas, laminas aerodinamicas, tons verde/teal/branco e espirais de ar ao redor do corpo. Os inimigos comuns devem parecer parte desse dominio sem virar copias menores do boss. A conexao deve aparecer em penas metalicas, turbinas, asas curtas, bicos/visores aerodinamicos, rotores, correntes de ar compactas e silhuetas leves.

O Stage 05 deve diferir do Stage 03 por trocar eletricidade e velocidade por vento, lift, empurrao, queda, turbulencia e controle de buracos/plataformas aereas. A distribuicao final sera:

- 3 melee/chao leves
- 4 fly/aereos ou hazards suspensos
- 2 static/ranged

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica e compacta
- formas leves, aerodinamicas ou suspensas
- elementos de vento em verde claro, teal, branco e ciano
- placas cinza-metal, preto e detalhes verde-lima
- brilho de vento em core, visor, turbina ou borda de lamina
- leitura limpa em escala pequena
- identidade de reploid, drone, maquina de vento ou fauna robotica aviaria

O visual deve evitar:

- raios amarelos/azuis do Stage 03
- fogo, gelo, sombra, gravidade roxa ou terra como linguagem principal
- todos os inimigos parecerem aves pequenas
- efeitos largos dentro da body sheet quando deveriam ser projeteis/FX separados
- rajadas soltas que reduzam ou cortem o corpo na celula fixa

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Guardas aerodinamicos:** soldados leves de solo com armadura de vento, garras, asas curtas e visores verdes.
- **B - Drones aviarios e turbinas:** inimigos suspensos com rotores, asas mecanicas, penas metalicas e comportamento de patrulha aerea.
- **C - Maquinas de corrente de ar:** turrets, fans e hazards que manipulam vento, lift e empurrao.

As tres familias compartilham a linguagem de Galerix:

- A deve parecer a tropa leve que protege plataformas e passagens.
- B deve trazer a heranca aviaria/raptor do boss sem copiar seu corpo.
- C deve parecer infraestrutura da fase que controla correntes de ar.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Rajadas, penas, slashes, correntes e turbulencias devem ser compactas e presas ao corpo quando fizerem parte da body sheet.
- Projectiles, ondas largas e efeitos de area devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para mergulhos, captura do player, turbinas carregando ou ciclos de penas orbitais.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao leves
2. Fly/aereos e hazards suspensos
3. Static/ranged
4. Projectiles separados: `gale_bolt`, `wind_slash`, `feather_dart`, `updraft_pulse`

Cada sheet processada deve manter artefatos em `assets/generated/stage05_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_05/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 3 inimigos de chao devem ser leves e rapidos. Eles ancoram a fase no piso sem quebrar o tema aereo.

1. `enemy_gale_runner`
   - familia visual A: guarda aerodinamico de solo
   - soldado leve que corre e da dash curto com rajada
   - armadura verde/teal, visor branco-ciano, tornozeleiras ou caneleiras de turbina
   - deve parecer tropa de chao, nao ave completa e nao heavy unit

2. `enemy_claw_glider`
   - familia visual A/B: unidade baixa com garras e asas curtas
   - inimigo de contato que abre winglets e golpeia com garras
   - conecta visualmente com a recompensa `Garras` da Zara sem virar item ou player weapon
   - deve parecer predador mecanico leve, nao mini boss

3. `enemy_airfoil_lancer`
   - familia visual A: lanceiro/guarda leve de vento
   - soldado com lamina ou lanca aerodinamica curta, avanca em linha curta
   - placas como asas de aviao, core verde e postura inclinada pelo vento
   - deve substituir qualquer inimigo pesado de chao; leitura precisa ser leve e rapido

### Fly/Aereos E Hazards Suspensos

Os 4 aereos/hazards devem ocupar espaco vertical e explorar plataformas e buracos. Aqui o voo deve parecer sustentacao por vento, nao eletricidade.

4. `enemy_sky_harrier`
   - familia visual B: drone raptor de patrulha
   - silhueta de ave mecanica/harrier, asas curtas, bico ou visor pontudo
   - mergulha em ataque curto e retorna
   - deve parecer patrulha aerea de Galerix, nao nave generica

5. `enemy_turbine_wisp`
   - familia visual B/C: core flutuante com helices orbitais
   - pequeno inimigo suspenso que atira `gale_bolt`
   - core branco-ciano, rotor verde, casca preta/cinza
   - deve parecer maquina de vento compacta, nao drone eletrico

6. `enemy_feather_swarm`
   - familia visual B: hazard de penas metalicas
   - conjunto compacto de penas ou laminas metalicas orbitando um core
   - movimento circular e pressao de area pequena
   - pode usar `feather_dart` como projectile separado se necessario

7. `enemy_gale_grappler`
   - familia visual B/C: capturador suspenso de vento
   - core de tornado pequeno com duas garras/ancoras aerodinamicas
   - fica pairando perto de buracos ou rotas aereas
   - comunica captura/arrasto: segura o player com corrente de vento e joga em direcao ao buraco
   - a body sheet deve mostrar garra abrindo, core carregando e pose de agarrar; o tether/onda larga deve ser FX separado se for necessario no futuro

### Static/Ranged

Os 2 static/ranged devem reforcar a infraestrutura da fase e o controle de ar.

8. `enemy_gale_turret`
   - familia visual C/A: turret de rajada horizontal
   - canhao baixo instalado em plataforma, com emissor de vento verde/ciano
   - carrega e dispara `gale_bolt`
   - deve ler como arma instalada, nao como soldado

9. `enemy_updraft_fan`
   - familia visual C: ventilador vertical de corrente ascendente
   - fan fixo que cria lift/empurrao
   - corpo industrial leve, helices internas, grelha e core verde
   - emite `updraft_pulse` como efeito separado
   - deve parecer infraestrutura/hazard, nao turret direcional

## Projectiles E FX Separados

Projectiles devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `gale_bolt`
   - disparo compacto horizontal de vento verde/branco
   - usado por `enemy_turbine_wisp` e `enemy_gale_turret`
   - leitura rapida, centro branco e borda teal

2. `wind_slash`
   - lamina curta de ar
   - usada por `enemy_claw_glider` ou `enemy_airfoil_lancer`
   - deve parecer corte de vento, nao raio eletrico

3. `feather_dart`
   - pena metalica fisica com rastro curto
   - usada por `enemy_sky_harrier` ou `enemy_feather_swarm`
   - deve parecer objeto fisico leve arremessado por vento

4. `updraft_pulse`
   - pulso circular/vertical de corrente de ar
   - usado por `enemy_updraft_fan` e possivelmente `enemy_gale_grappler`
   - deve parecer lift/turbulencia compacta, nao explosao elemental

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 05 de Galerix
- o tema de vento/plataformas aereas e mais forte que eletricidade ou gravidade
- os inimigos usam linguagem aviaria/raptor sem repetir o boss em miniatura
- cada funcao tem leitura imediata em gameplay: runner, glider, lancer, drone, wisp, swarm, grappler, turret ou fan
- a paleta verde/teal/branco/cinza domina sem virar Stage 03 eletrico
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- o `enemy_gale_grappler` comunica captura/arrasto sem precisar mostrar o player na sprite sheet
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Galerix
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
