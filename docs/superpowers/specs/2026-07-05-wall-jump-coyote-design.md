# Coyote Time de Parede — Design

**Data:** 2026-07-05
**Status:** Aprovado
**Arquivos-alvo:** `characters/base/character_base.gd`, `characters/ranged/zael.gd`, `tests/test_wall_jump.gd`

## Problema

Na travessia parede→parede, o input natural é apertar **primeiro** a direção da
parede-alvo. Hoje isso encerra o wall slide na hora (o slide exige segurar pra
dentro da parede) e, como não existe pulo aéreo, o botão de pulo apertado em
seguida não faz nada — o jogador despenca. Sintoma confirmado pelo usuário:
"caio da parede sem pular".

A ordem inversa (pulo primeiro, direção depois) já funciona; o problema é só a
ordem direção-primeiro.

## Solução

Janela de tolerância ("coyote time de parede", estilo Celeste): ao soltar do
wall slide, o wall jump continua disponível por 0.15s usando a última normal
de parede guardada.

### Mecânica

- `WALL_COYOTE_TIME := 0.15` (9 frames a 60fps; tunável após teste em jogo).
- Novo timer `_wall_coyote_timer` em `character_base.gd`.
- **Arma** quando o slide termina no ramo "soltou a direção / perdeu contato /
  subiu rápido demais" de `_update_wall_slide` (o `else` final). NÃO arma nos
  ramos de dash/chão nem após um wall jump (que seta `_is_wall_sliding = false`
  fora de `_update_wall_slide`, portanto não passa pela transição armada).
- **Zera** em: `_apply_wall_jump()` (disparou), `is_on_floor()` (pousou),
  re-agarre de parede (slide ativo tem prioridade na decisão de pulo).
- `_wall_normal` já persiste após o fim do slide — o kick reutiliza sem estado
  novo. Kick sempre para longe da parede antiga = direção da travessia.

### Decisão de pulo

Helper testável em `character_base.gd`:

```gdscript
func _can_wall_jump() -> bool:
    return _is_wall_sliding or (_wall_coyote_timer > 0.0 and not is_on_floor())
```

`_handle_jump` usa `_can_wall_jump()` no lugar do check direto de
`_is_wall_sliding`, **mantendo a prioridade atual**: wall jump primeiro; pulo
de chão (chão ou coyote de chão) em seguida. Estando no chão o slide nunca está
ativo e o timer é zerado, então não há kick fantasma pós-pouso.

### Interações

- **Dash wall jump:** segurar dash + pulo dentro da janela → kick de 460
  (mesmo fluxo de `_apply_wall_jump`, sem código novo).
- **Agarre subindo** (`WALL_GRAB_MAX_RISE`): completa o ciclo no lado oposto.
- **Subir uma parede só:** inalterado — segurando pra dentro o slide continua
  ativo e o coyote não participa.

### Zael

`zael.gd::_handle_jump` tem o check `_is_wall_sliding` hardcoded na prioridade
do wall jump sobre o dash-jump → trocar por `_can_wall_jump()`. Zara herda da
base; nada a fazer.

## Testes (`tests/test_wall_jump.gd`)

1. `WALL_COYOTE_TIME == 0.15`.
2. `_can_wall_jump()` → true com `_wall_coyote_timer > 0` no ar; false com
   timer zerado e sem slide; true em slide.
3. `_apply_wall_jump()` zera `_wall_coyote_timer`.
4. Armação do timer via física real (soltar da parede de verdade) fica para
   validação manual no shaft Z4 do stage 01.

## Fora de escopo

- Travessia assistida (lock até agarrar) — só se o "puxão de volta" incomodar
  após teste em jogo.
- Pulo neutro da parede (sem segurar direção) — redundante com a janela.
