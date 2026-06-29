# Universal Pickup Sprites Design

**Data:** 2026-06-19
**Escopo:** 7 sprites universais de pickups e upgrade para uso em todas as fases
**Base visual:** itens de plataforma 2D inspirados em Mega Man X, com identidade propria do projeto
**Tema de dominio:** tecnologia neutra, leitura imediata em gameplay, cores funcionais e animacao curta

## Objetivo

Criar um pacote inicial de sprites universais para itens de fase que nao dependem de um stage especifico. A meta e substituir ou preparar substituicao futura dos coletaveis desenhados por `_draw()` em `stages/collectible.gd`, sem amarrar os sprites a fogo, gelo, raio, gravidade, vento, sombra, luz ou terra.

O pacote cobre vida pequena/grande, energia pequena/grande, bateria de aumento de vida, 1UP e capsula de upgrade. Esses sprites devem ser legiveis em movimento, funcionar sobre qualquer tileset e manter uma linguagem tecnica consistente com Zara/Zael sem usar silhueta especifica de personagem.

## Contexto Atual

O projeto tem `stages/collectible.tscn` e `stages/collectible.gd` como coletavel generico. Hoje o visual e um circulo desenhado via `_draw()`, com cor por tipo:

- `HEART`: vermelho
- `SUBTANK`: ciano
- `ARMOR_ZAEL`: dourado
- `ARMOR_ZARA`: laranja
- `SHOT_ZAEL`: verde
- `WEAPON_ZARA`: roxo

Este pacote e de arte. A integracao com `Collectible` deve ser planejada separadamente na implementacao para evitar misturar geracao de sprites com mudanca de comportamento de coleta.

## Direcao Visual

Todos os sprites devem ser universais:

- nao usar paleta ou forma de um stage especifico
- leitura clara em fundo claro ou escuro
- contorno mecanico forte
- brilho funcional, sem excesso de particulas
- fundo raw `#FF00FF` para processamento
- sprite final transparente
- escala coerente entre itens equivalentes

O visual deve evitar:

- parecer inimigo, boss ou drone
- parecer pickup organico demais
- usar texto pequeno que fique ilegivel
- depender de letras para entendimento, exceto `pickup_1up` se a silhueta continuar clara
- repetir exatamente a mesma silhueta para vida e energia, exceto por familia visual controlada
- usar cores de stage como identidade principal

## Estrutura Esperada

Cada item deve ser gerado em sheet propria:

- pickups pequenos/grandes: `2x2`, 4 frames, idle/pulse
- bateria de aumento de vida: `3x3`, 9 frames, pulse/shine
- 1UP: `2x2`, 4 frames, idle/shine
- capsula de upgrade: `4x4`, 16 frames, brilho, abertura e pulso final

Os assets finais devem ficar em:

- `assets/generated/pickups_<asset>/<action>/`
- `characters/pickups/<asset>.png`

## Roster

### 1. `pickup_health_small`

Pickup pequeno de vida.

- capsula ou celula curta
- vermelho/verde medico com branco pequeno de highlight
- deve ler como recuperacao de HP
- animacao: brilho leve, pulso interno, retorno idle
- sheet: `2x2`

### 2. `pickup_health_large`

Pickup grande de vida.

- mesma familia visual do pequeno
- corpo maior, mais robusto e mais luminoso
- deve parecer claramente mais valioso que `pickup_health_small`
- animacao: pulso mais forte, brilho de borda, retorno idle
- sheet: `2x2`

### 3. `pickup_energy_small`

Pickup pequeno de energia de arma.

- capsula ou cartucho curto
- azul/ciano com nucleo branco ou azul claro
- deve ler como energia, nao vida
- animacao: pulso eletrico compacto sem raio longo
- sheet: `2x2`

### 4. `pickup_energy_large`

Pickup grande de energia de arma.

- mesma familia visual do pequeno
- corpo maior e nucleo mais intenso
- deve parecer claramente mais valioso que `pickup_energy_small`
- animacao: brilho azul/ciano, pequeno flicker interno, retorno idle
- sheet: `2x2`

### 5. `pickup_life_upgrade`

Item permanente de aumento de vida em forma de bateria robotica.

- bateria vertical ou celula vital mecanica
- circuitos visiveis, nucleo vermelho/verde ou magenta controlado
- deve comunicar upgrade permanente, nao simples cura
- nao deve parecer `SubTank`
- animacao: carga subindo, brilho central, shine curto
- sheet: `3x3`

### 6. `pickup_1up`

Vida extra universal.

- emblema ou nucleo robotico de vida extra
- pode usar um simbolo `1UP` grande se ficar legivel, mas a silhueta deve funcionar mesmo sem ler texto
- usar verde/azul/branco ou verde/dourado para diferenciar de HP comum
- animacao: shine curto e pulso de valor raro
- sheet: `2x2`

### 7. `upgrade_capsule`

Capsula universal de upgrade.

- capsula tecnologica vertical com base e vidro/energia
- neutra, sem pertencer a stage especifico
- deve parecer objeto especial, maior que pickups comuns
- animacao em `4x4`: idle fechado, brilho interno, abertura parcial, abertura completa, pulso final
- nao usar `5x5` neste pacote; uma versao cinematica pode ser criada depois se necessario

## Regras De Sprite

- O primeiro frame deve comunicar o estado idle do item.
- O item deve ficar centralizado em todas as celulas.
- A escala deve permanecer estavel entre frames.
- Nenhuma parte importante pode tocar a borda da celula.
- Brilhos e particulas devem ficar dentro da area segura.
- Os sprites pequenos nao devem ficar visualmente maiores que os grandes.
- `pickup_life_upgrade` deve parecer bateria permanente, nao coracao.
- `upgrade_capsule` deve ter corpo maior e leitura de capsula mesmo no primeiro frame.
- O fundo raw deve ser `#FF00FF`; output final deve ser transparente.

## Criterios De Aceitacao

Uma geracao passa quando:

- os 7 sprites parecem parte de uma mesma linguagem universal
- vida e energia sao distinguiveis imediatamente
- pequeno e grande sao distinguiveis por tamanho/silhueta, nao so por cor
- `pickup_life_upgrade` le como bateria robotica permanente
- `pickup_1up` le como vida extra rara
- `upgrade_capsule` le como capsula de upgrade em 4x4
- todos os outputs finais estao sem magenta residual visivel
- todos os `pipeline-meta.json` ficam sem `edge_touch_frames`
- os PNGs runtime podem ser usados por `Sprite2D` em Godot

## Fora De Escopo

- miniboss ou boss
- hazards de fase
- obstaculos mecanicos
- props destrutiveis
- FX de ambiente
- plataformas especiais
- mudancas de balanceamento
- mudar logica de coleta ou persistencia
- substituir imediatamente todos os nodes `Collectible` nas fases
