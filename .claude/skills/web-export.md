# Skill: web-export

Use quando o usuário quiser exportar e publicar o build web no GitHub Pages.

## Passos em Ordem

1. **Rodar export Godot:**
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html 2>&1
```

2. **Verificar arquivo exportado:**
```bash
dir export/web/index.html
```
Se não existir → reportar erro e parar.

3. **Commitar o export:**
```bash
git add export/web/
git commit -m "chore: web export"
```
Se o usuário fornecer descrição do que mudou, usar: `"chore: web export — <descrição>"`

4. **Push:**
```bash
git push
```

## Observações

- O export preset "Web" já está configurado em `export_presets.cfg`
- O caminho `export/web/` é servido pelo GitHub Pages automaticamente
- Sempre usar `--export-release` (não `--export-debug`) para builds de produção
- O export pode levar 30–60 segundos; é normal
