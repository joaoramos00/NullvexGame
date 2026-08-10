# Copia _raw/animations/kawa_{name}/east/{i}.png -> anims/{name}/f{ii}.png
# Idempotente. Rode a partir da raiz do projeto.
$ErrorActionPreference = "Stop"
$root = "characters/ranged/kawagael"
$anims = @(
  "idle", "run_start", "run", "run_stop", "jump",
  "shoot_1", "shoot_2", "shoot_3", "dash", "wall_slide",
  "hurt", "death", "run_shoot", "jump_shoot", "dash_shoot"
)

$totalFrames = 0
foreach ($anim in $anims) {
    $srcDir = "$root/_raw/animations/kawa_$anim/east"
    $dstDir = "$root/anims/$anim"
    if (-not (Test-Path $srcDir)) {
        Write-Warning "  missing source: $srcDir (skip)"
        continue
    }
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null

    # Limpa PNGs antigos no destino (não .gitkeep)
    Get-ChildItem "$dstDir/*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

    # Ordena por número (0.png, 1.png, ..., 10.png)
    $files = Get-ChildItem "$srcDir/*.png" | Sort-Object {
        [int]([IO.Path]::GetFileNameWithoutExtension($_.Name))
    }
    for ($i = 0; $i -lt $files.Count; $i++) {
        $dst = "$dstDir/f{0:D2}.png" -f $i
        Copy-Item -Force $files[$i].FullName $dst
    }
    $totalFrames += $files.Count
    "  $anim -> $($files.Count) frames"
}
""
"Total frames curated: $totalFrames"
