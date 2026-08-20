# Copia _raw/animations/kawa_{name}/east/{i}.png -> anims/{name}/f{ii}.png
# Idempotente. Rode a partir da raiz do projeto.
$ErrorActionPreference = "Stop"
$root = "characters/ranged/kawagael"
$anims = @(
  "idle", "run_start", "run", "run_stop", "jump",
  "shoot_1", "shoot_2", "shoot_3", "dash", "wall_slide",
  "hurt", "death", "run_shoot", "jump_shoot", "dash_shoot"
)

# Anims que têm uma continuação "_b" no _raw (concatenadas no anims/ final).
# Ex: run + run_b -> anims/run/f00.png .. fNN.png (contínuos)
$continuations = @{
    "run" = "run_b"
}

$totalFrames = 0
foreach ($anim in $anims) {
    $srcDir = "$root/_raw/animations/kawa_$anim/east"
    $dstDir = "$root/anims/$anim"
    if (-not (Test-Path $srcDir)) {
        Write-Warning "  missing source: $srcDir (skip)"
        continue
    }
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null

    # Limpa PNGs + .import antigos no destino (não .gitkeep)
    Get-ChildItem "$dstDir/*.png" -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem "$dstDir/*.png.import" -ErrorAction SilentlyContinue | Remove-Item -Force

    # Fase 1: copia frames principais
    $files = Get-ChildItem "$srcDir/*.png" | Sort-Object {
        [int]([IO.Path]::GetFileNameWithoutExtension($_.Name))
    }
    $frameIdx = 0
    foreach ($f in $files) {
        Copy-Item -Force $f.FullName ("$dstDir/f{0:D2}.png" -f $frameIdx)
        $frameIdx++
    }

    # Fase 2: se houver continuação, anexa em sequência
    if ($continuations.ContainsKey($anim)) {
        $contName = $continuations[$anim]
        $contDir  = "$root/_raw/animations/kawa_$contName/east"
        if (Test-Path $contDir) {
            $contFiles = Get-ChildItem "$contDir/*.png" | Sort-Object {
                [int]([IO.Path]::GetFileNameWithoutExtension($_.Name))
            }
            foreach ($f in $contFiles) {
                Copy-Item -Force $f.FullName ("$dstDir/f{0:D2}.png" -f $frameIdx)
                $frameIdx++
            }
            "  $anim -> $frameIdx frames (base $($files.Count) + $contName $($contFiles.Count))"
        } else {
            "  $anim -> $frameIdx frames (WARN: expected continuation $contName not found)"
        }
    } else {
        "  $anim -> $frameIdx frames"
    }
    $totalFrames += $frameIdx
}
""
"Total frames curated: $totalFrames"
