# Skill: run-tests

Use quando o usuário quiser rodar os testes do projeto.

## Comportamento

**Sem argumento** — roda todos os testes listados abaixo em sequência.
**Com argumento** (ex: `run-tests enemy_base`) — roda só `tests/test_<argumento>.tscn`.

## Comando Base

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn 2>&1
```

## Lista Completa de Testes

```
test_game_manager
test_stage_manager
test_character_base
test_zael
test_zara
test_enemy_base
test_boss_base
test_boss_ai
test_wall_jump
test_checkpoint_door
test_collectible
test_hud
test_pause_menu
test_stage_complete
test_intro_boss
test_touch_controls
test_img_debug
```

## Interpretação da Saída

- `ALL TESTS PASSED` na saída → ✅ PASS
- Exit code ≠ 0 → ❌ FAIL
- Linha contendo `assert` ou `ERROR` → ❌ FAIL com detalhe

## Formato de Reporte

Após rodar todos (ou o selecionado), reportar:

```
Resultados dos Testes:
✅ test_game_manager
✅ test_stage_manager
❌ test_zael — assert falhou: linha 23
...
Total: X/Y passando
```

## Procedimento

1. Para cada teste (ou o informado), rodar o comando acima
2. Capturar saída completa
3. Verificar se contém "ALL TESTS PASSED"
4. Reportar tabela de resultados
5. Se algum falhou: mostrar a saída relevante do teste com falha
