# Stage 03 Voltrix Enemies Sprite Design

**Data:** 2026-06-17
**Escopo:** 9 sprites de inimigos comuns para `stage_03`
**Base visual:** inimigos de Mega Man X como referencia de linguagem, com identidade propria do projeto
**Tema de dominio:** central eletrica e tempestade comandada por Voltrix, um boss falcao trovao

## Objetivo

Definir a linguagem visual dos 9 sprites novos do roster eletrico da `stage_03` antes de gerar a arte. A meta e criar inimigos com leitura imediata em gameplay, aparencia de reploid/maquina eletrica, e consistencia suficiente para uso direto em Godot com `Sprite2D`.

Voltrix e um boss falcao trovao: uma ave de rapina mecanica, carregada de eletricidade, com penas metalicas, garras e bico energizados, asas meio abertas e movimento rapido. Os inimigos comuns devem parecer parte do dominio dele sem virar copias menores do boss. A conexao deve aparecer em antenas, bobinas, placas serrilhadas, garras condutoras, asas mecanicas, bicos abstratos, olhos/visores eletricos e descargas entre juntas.

O Stage 03 deve diferir do Stage 01 e Stage 02 por ter mais pressao vertical, aerea e estatica. A distribuicao final sera:

- 2 melee/chao
- 4 fly/aereos
- 3 static/ranged

## Direcao Visual

Os sprites devem parecer inimigos de plataforma 2D inspirados em Mega Man X:

- silhueta mecanica e compacta
- corpo com placas metalicas, juntas, cabos, bobinas, antenas ou capacitores
- brilho eletrico forte em visor, nucleo, garra, bico ou emissor
- leitura limpa em escala pequena
- identidade de reploid, drone, ave mecanica ou maquina eletrica, nao criatura organica

O visual deve evitar:

- chamas, gelo, sombra ou cristal como linguagem principal
- penas organicas macias sem construcao mecanica
- todos os inimigos parecerem falcoes menores
- silhuetas grandes demais para inimigos comuns
- excesso de raios soltos que reduzam o corpo na celula fixa

### Familias Visuais

O roster deve usar tres familias visuais:

- **A - Guardas reploids eletricos:** inimigos militares, compactos, com placas amarelo/preto, visores, antenas e condutores nas articulacoes.
- **B - Fauna robotica de tempestade:** drones e criaturas mecanicas inspiradas em falcao, ave de rapina ou predador eletrico, sempre com bico/garras/penas metalicas abstratas.
- **C - Maquinas de central eletrica:** torres, bobinas, transformadores, relays, trilhos e equipamentos industriais energizados.

As tres familias compartilham a linguagem de Voltrix:

- A deve parecer tropa de manutencao/seguranca da central do boss.
- B deve trazer a heranca do falcao trovao sem copiar sua escala ou pose de boss.
- C deve parecer infraestrutura eletrica que tambem funciona como defesa.

## Regras Gerais De Sprite

- O primeiro frame de cada sprite deve comunicar o estado inicial do inimigo.
- Cada sprite deve manter escala estavel entre frames.
- O corpo deve permanecer centrado e legivel em cada celula.
- Nenhuma parte importante pode tocar a borda da celula.
- Raios, sparks e muzzle flashes devem ser compactos e presos ao corpo quando fizerem parte da body sheet.
- Projectiles, beams longos e efeitos largos devem ser sprites separados.
- Cada inimigo deve ser gerado em uma raw sheet propria.

## Estrutura Esperada Das Sheets

Usar a menor grade que comunique bem a funcao do inimigo:

- 4 frames: `2x2`
- 6 frames: `2x3`
- 8 frames: `2x4`
- 9 frames: `3x3`
- 16 frames: `4x4`

`3x3` e `4x4` sao permitidos quando melhorarem a leitura real da animacao, especialmente para mergulho aereo, bobina carregando, relay pulsando ou um ciclo de movimento mais rico. Nao usar grades maiores so por estetica.

## Ordem De Producao

Gerar e validar os sprites por funcao:

1. Melee/chao
2. Fly/aereos
3. Static/ranged
4. Projectiles separados: `arc_bolt`, `thunder_shot`, `tesla_pulse`, `storm_spark`

Cada sheet processada deve manter artefatos em `assets/generated/stage03_<enemy>/<action>/` e a textura final de uso em jogo deve ser copiada para `characters/enemies/stage_03/<enemy>.png`.

## Roster E Direcao Por Tipo

### Melee/Chao

Os 2 inimigos de chao devem criar pressao de contato sem dominar o tema. Eles existem para ancorar o Stage 03 no piso enquanto a maior ameaca vem de cima e das maquinas fixas.

1. `enemy_volt_guard`
   - familia visual A: guarda reploid eletrico
   - soldado compacto de seguranca da central eletrica de Voltrix
   - armadura cinza-metal com placas amarelo/preto e visor azul eletrico
   - usa bastao curto, garra condutora ou punho eletrificado
   - antenas pequenas no capacete para conectar com a linguagem do boss
   - postura agressiva de patrulha, pronto para choque de contato
   - deve parecer tropa de chao, nao ave e nao turret

2. `enemy_rail_runner`
   - familia visual C: maquina de central eletrica
   - robo baixo que corre sobre trilho energizado ou patins magneticos
   - corpo achatado, rodas/roletes, cabos expostos e nucleo eletrico frontal
   - movimento de arrancada curta no piso, como um carrinho de manutencao armado
   - pode ter frente em forma de cunha ou bico mecanico abstrato
   - deve ler como hazard movel de chao, nao como soldado

### Fly/Aereos

Os 4 aereos sao o centro do roster. Eles devem fazer o jogador olhar para cima, respeitar o espaco vertical e associar imediatamente a fase ao falcao trovao.

3. `enemy_thunder_hawklet`
   - familia visual B: fauna robotica de tempestade
   - pequeno drone-falcao de rapina, com bico metalico curto e asas mecanicas dobraveis
   - placas amarelo/preto, penas rigidas de metal e garras energizadas
   - movimento de hover curto seguido de mergulho ou pose de rasante
   - deve parecer descendente mecanico do dominio de Voltrix, mas muito menor e comum

4. `enemy_storm_kite`
   - familia visual B: fauna robotica de tempestade
   - planador eletrico alto, com formato de pipa/asa delta e cabeca de ave abstrata
   - voa mais leve que o `thunder_hawklet`, com asas largas e corpo fino
   - solta pequenas descargas para baixo ou em diagonal
   - leitura de patrulha aerea que ocupa espaco vertical
   - deve evitar parecer nave generica; usar bico/penas metalicas sutis

5. `enemy_arc_orbiter`
   - familia visual C: maquina de central eletrica
   - esfera eletrica flutuante com anel de bobinas ou segmentos orbitais
   - nucleo azul/amarelo carregado, com pequenos arcos entre partes do anel
   - dispara `arc_bolt` como projectile separado
   - silhueta circular para contrastar com os flyers de asas
   - deve parecer equipamento de alta tensao que escapou da central

6. `enemy_static_interceptor`
   - familia visual A: guarda reploid eletrico
   - drone militar angular, mais utilitario que animal
   - corpo com visor, pequenas asas/estabilizadores, antenas e emissor frontal
   - dispara `thunder_shot` como projectile separado
   - leitura de drone de seguranca de Voltrix, mais tatico e menos organico
   - deve complementar o `thunder_hawklet` sem repetir a silhueta de falcao

### Static/Ranged

Os 3 static/ranged devem reforcar a central eletrica. Eles devem controlar timing e espaco com carga visual clara, mas sem virar bosses ou props de cenario passivas.

7. `enemy_tesla_coil`
   - familia visual C: maquina de central eletrica
   - torre fixa de bobina Tesla, base industrial e topo condutor
   - carrega em etapas ate soltar `tesla_pulse`
   - pode emitir raio vertical curto, pulso lateral ou arco eletrico compacto
   - deve ter animacao de carga muito clara: nucleo apagado -> bobina acende -> descarga
   - leitura de turret eletrica classica, mas com acabamento do dominio de Voltrix

8. `enemy_arc_turret`
   - familia visual A/C: canhao defensivo eletrico
   - turret de parede ou chao com carenagem militar e emissor frontal
   - dispara `arc_bolt` em linha, diferente do pulso da bobina Tesla
   - corpo mais baixo e angular, com placas amarelo/preto e visor/emissor azul
   - pode ter frente que sugere bico mecanico ou garra condutora sem virar ave
   - deve ler como arma instalada da central

9. `enemy_storm_relay`
   - familia visual C: relay/condutor de tempestade
   - unidade estatica que cria pulso eletrico em area
   - corpo com isoladores, para-raios, cabos e pequenos sparks orbitando
   - funciona visualmente como hazard ativo: carrega, pulsa, descarrega, resfria
   - dispara ou emite `storm_spark` como efeito/projetil separado se necessario
   - deve parecer infraestrutura energizada, nao um soldado e nao uma torre comum

## Projectiles E FX Separados

Projectiles devem ser separados para evitar encolher os corpos nas sheets fixas.

1. `arc_bolt`
   - raio curto/energia compacta horizontal
   - usado por `enemy_arc_orbiter` e `enemy_arc_turret`
   - leitura rapida, amarelo com nucleo azul

2. `thunder_shot`
   - disparo eletrico mais militar e concentrado
   - usado por `enemy_static_interceptor`
   - deve parecer tiro de drone, nao raio natural

3. `tesla_pulse`
   - descarga compacta de bobina Tesla
   - usado por `enemy_tesla_coil`
   - pode ser pulso circular/vertical curto, sem ocupar uma celula exagerada

4. `storm_spark`
   - spark irregular de tempestade
   - usado por `enemy_storm_relay` e possivelmente `enemy_storm_kite`
   - visual mais caotico que `arc_bolt`, mas ainda compacto

## Criterios De Aceitacao

Uma geracao passa quando:

- os 9 sprites parecem pertencer ao Stage 03 de Voltrix
- a presenca aerea e estatica e mais forte que nos rosters dos Stages 01 e 02
- os inimigos usam linguagem de falcao trovao sem repetir o boss em miniatura
- cada funcao tem leitura imediata em gameplay: chao, flyer, turret ou relay
- a paleta eletrica amarelo/azul/cinza domina sem virar tema de luz do Stage 07
- os projectiles separados sao visualmente distintos entre si
- nenhum sprite depende de efeitos grandes dentro da body sheet para ser entendido
- nenhuma sheet exige improviso posterior para entender o tipo do inimigo

## Fora De Escopo

- miniboss
- boss Voltrix
- layout da stage
- scripts de comportamento
- sprites de cenario ou tileset
- balanceamento de combate alem do que for necessario para leitura visual do sprite
