# Skill: web-export

Use quando o usuário quiser exportar o build web, publicar no GitHub Pages e testar localmente.

## Passos em Ordem

### 1. Export Godot (headless)

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:\SnesGame" --export-release "Web" "D:\SnesGame\export\web\index.html" 2>&1
```

### 2. Verificar PCK atualizado

```powershell
powershell -Command "Get-Item 'D:\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```

`LastWriteTime` deve ser recente. Se não mudou → erro no export, parar.

### 3. Commit e push

```bash
# export/web/ está no .gitignore mas com exceção — usar -f para garantir
git add -f export/web/ <outros arquivos modificados>
git commit -m "chore: web export — <descrição da mudança>"
git push
```

### 4. Reiniciar servidor local (port 8080)

```powershell
powershell -Command "
  \$pids = (netstat -ano | findstr ':8080' | ForEach-Object { (\$_ -split '\s+')[-1] } | Sort-Object -Unique);
  foreach (\$p in \$pids) { Stop-Process -Id \$p -Force -ErrorAction SilentlyContinue };
  Start-Process python -ArgumentList 'D:\SnesGame\serve_web.py' -WindowStyle Hidden;
  Start-Sleep 2;
  (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
"
```

Deve retornar `200`. Se não → checar se `serve_web.py` existe.

### 5. Reportar

- URL local: `http://localhost:8080`
- URL GitHub Pages: `https://joaoramos00.github.io/NullvexGame/`

## Observações

- Export preset "Web" já configurado em `export_presets.cfg`
- `export/` está no `.gitignore` mas `!export/web/` está excluído — `git add -f` é necessário
- Usar sempre `--export-release` (não `--export-debug`)
- O export leva 30–60 s; normal
- O servidor usa COOP/COEP headers (necessário para SharedArrayBuffer do Godot web)
