# Stage 00 Pós-CorrMB: Pilares com Saliências — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir Step_Up1/2/3 + Pilar + Plat_PilarTop por 6 nós de colisão que formam 3 pilares estilo "construção com sacada", criando uma subida jogável de y=1088→y=512 em x=8222→9422.

**Architecture:** Edição direta do `.tscn` — remover 5 sub_resources + 5 nodes, adicionar 6 sub_resources + 6 nodes. Nenhuma alteração de código GDScript necessária; `_draw_platforms()` renderiza os novos nós automaticamente.

**Tech Stack:** Godot 4 `.tscn` (text scene format)

---

### Task 1: Remover sub_resources obsoletos e adicionar novos

**Files:**
- Modify: `stages/stage_00/stage_00.tscn` (seção `[sub_resource]`, linhas 43–46 e 106–113)

- [ ] **Passo 1: Remover as 5 shapes obsoletas**

Em `stage_00.tscn`, apagar os blocos:

```
[sub_resource type="RectangleShape2D" id="shape_Pilar"]
size = Vector2(64, 704)

[sub_resource type="RectangleShape2D" id="shape_PlatPilarTop"]
size = Vector2(384, 64)
```
```
[sub_resource type="RectangleShape2D" id="shape_StepUp1"]
size = Vector2(128, 64)

[sub_resource type="RectangleShape2D" id="shape_StepUp2"]
size = Vector2(128, 64)

[sub_resource type="RectangleShape2D" id="shape_StepUp3"]
size = Vector2(128, 64)
```

- [ ] **Passo 2: Adicionar 6 novas shapes** (inserir logo antes da linha `[node name="Stage00"`)

```
[sub_resource type="RectangleShape2D" id="shape_LedgeA"]
size = Vector2(128, 160)

[sub_resource type="RectangleShape2D" id="shape_PilarA"]
size = Vector2(192, 256)

[sub_resource type="RectangleShape2D" id="shape_LedgeB"]
size = Vector2(128, 352)

[sub_resource type="RectangleShape2D" id="shape_PilarB"]
size = Vector2(192, 448)

[sub_resource type="RectangleShape2D" id="shape_LedgeC"]
size = Vector2(128, 544)

[sub_resource type="RectangleShape2D" id="shape_PilarC"]
size = Vector2(192, 640)
```

---

### Task 2: Remover nodes obsoletos do .tscn

**Files:**
- Modify: `stages/stage_00/stage_00.tscn` (linhas 227–237 e 360–376)

- [ ] **Passo 1: Remover Pilar e Plat_PilarTop** (linhas ~227–237)

Apagar:
```
[node name="Pilar" type="StaticBody2D" parent="."]
position = Vector2(8394, 736)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Pilar"]
shape = SubResource("shape_Pilar")

[node name="Plat_PilarTop" type="StaticBody2D" parent="."]
position = Vector2(8554, 384)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat_PilarTop"]
shape = SubResource("shape_PlatPilarTop")
```

- [ ] **Passo 2: Remover Step_Up1, Step_Up2, Step_Up3** (linhas ~360–376)

Apagar:
```
[node name="Step_Up1" type="StaticBody2D" parent="."]
position = Vector2(8286, 896)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Up1"]
shape = SubResource("shape_StepUp1")

[node name="Step_Up2" type="StaticBody2D" parent="."]
position = Vector2(8286, 704)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Up2"]
shape = SubResource("shape_StepUp2")

[node name="Step_Up3" type="StaticBody2D" parent="."]
position = Vector2(8294, 512)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Up3"]
shape = SubResource("shape_StepUp3")
```

---

### Task 3: Adicionar 6 novos nodes ao .tscn

**Files:**
- Modify: `stages/stage_00/stage_00.tscn` (inserir antes de `[node name="LBoundary"`)

- [ ] **Passo 1: Inserir os 6 novos nós**

Inserir o bloco completo logo antes de `[node name="LBoundary"`:

```
[node name="Ledge_A" type="StaticBody2D" parent="."]
position = Vector2(8286, 1072)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ledge_A"]
shape = SubResource("shape_LedgeA")

[node name="Pilar_A" type="StaticBody2D" parent="."]
position = Vector2(8446, 1024)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Pilar_A"]
shape = SubResource("shape_PilarA")

[node name="Ledge_B" type="StaticBody2D" parent="."]
position = Vector2(8726, 976)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ledge_B"]
shape = SubResource("shape_LedgeB")

[node name="Pilar_B" type="StaticBody2D" parent="."]
position = Vector2(8886, 928)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Pilar_B"]
shape = SubResource("shape_PilarB")

[node name="Ledge_C" type="StaticBody2D" parent="."]
position = Vector2(9166, 880)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ledge_C"]
shape = SubResource("shape_LedgeC")

[node name="Pilar_C" type="StaticBody2D" parent="."]
position = Vector2(9326, 832)
collision_layer = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Pilar_C"]
shape = SubResource("shape_PilarC")
```

---

### Task 4: Verificar no img_debug e commitar

**Files:**
- Run: `ui/img_debug.gd` (ferramenta de visualização já existente)

- [ ] **Passo 1: Abrir o jogo no img_debug**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --path "C:/Users/Usuário/SnesGame" res://ui/img_debug.tscn
```

Navegar até x≈8222 e verificar visualmente:
- 3 pilares estilo "L" aparecendo ao longo de x=8222→9422
- Ledges menores saindo à esquerda de cada pilar
- Nenhum tile voando nem gap inesperado

- [ ] **Passo 2: Verificar geometria das top faces**

| Nó | Top face esperada |
|---|---|
| Ledge_A | y=992 |
| Pilar_A | y=896 |
| Ledge_B | y=800 |
| Pilar_B | y=704 |
| Ledge_C | y=608 |
| Pilar_C | y=512 |

- [ ] **Passo 3: Commitar**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "feat: pilares pós-CorrMB — 3 pilares com saliências, subida 96px/step"
```
