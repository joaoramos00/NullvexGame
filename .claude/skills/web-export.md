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

### 3. NÃO commitar `export/web/`

Desde 2026-07-17 (commit `28154305`) o export web **não é mais versionado
no git** — `export/` está inteiro no `.gitignore`, sem exceção. O
`.github/workflows/deploy.yml` baixa o Godot headless + export templates e
roda o export release direto no runner a cada push na `master`, publicando
no GitHub Pages. Isso existe porque commitar o `.pck` via Git LFS estourava
a cota da conta a cada reexportação (622 versões históricas já tinham
estourado — ver `reference_git_lfs_budget_exceeded` na memória). O export
local do passo 1 serve só pra testar localmente (passo 4); dar merge/push do
código na `master` já é suficiente para o Pages atualizar sozinho via CI.

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
- `export/` está inteiro no `.gitignore` (sem exceção) — nunca commitar `export/web/`, é build artifact local/CI
- Usar sempre `--export-release` (não `--export-debug`)
- O export leva 30–60 s; normal
- O servidor usa COOP/COEP headers (necessário para SharedArrayBuffer do Godot web)
- Publicação real (GitHub Pages) acontece via `.github/workflows/deploy.yml` a cada push na `master` — não depende deste passo local
