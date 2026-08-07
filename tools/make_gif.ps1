# tools/make_gif.ps1 — build a simple GIF preview from N ordered PNG frames.
# Usage: make_gif.ps1 -InputPattern "frames/f*.png" -Output "preview.gif" [-DelayMs 100]

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$InputPattern,
    [Parameter(Mandatory=$true)] [string]$Output,
    [int]$DelayMs = 100
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Drawing.Imaging

$frames = Get-ChildItem -Path $InputPattern | Sort-Object Name
if ($frames.Count -eq 0) { Write-Error "No frames matched $InputPattern"; exit 1 }

# Load first as encoder source
$first = [System.Drawing.Bitmap]::FromFile($frames[0].FullName)
$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatID -eq [System.Drawing.Imaging.ImageFormat]::Gif.Guid } | Select-Object -First 1

# Setup encoder params for multi-frame gif
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter (
    [System.Drawing.Imaging.Encoder]::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::MultiFrame
)

$outStream = [System.IO.File]::Create($Output)
try {
    $first.Save($outStream, $encoder, $encParams)

    # Add remaining frames
    $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter (
        [System.Drawing.Imaging.Encoder]::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::FrameDimensionTime
    )
    for ($i = 1; $i -lt $frames.Count; $i++) {
        $bmp = [System.Drawing.Bitmap]::FromFile($frames[$i].FullName)
        $first.SaveAdd($bmp, $encParams)
        $bmp.Dispose()
    }

    # Finish
    $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter (
        [System.Drawing.Imaging.Encoder]::SaveFlag, [long][System.Drawing.Imaging.EncoderValue]::Flush
    )
    $first.SaveAdd($encParams)
} finally {
    $outStream.Close()
    $first.Dispose()
}

Write-Host "gif -> $Output  $((Get-Item $Output).Length) bytes  $($frames.Count) frames"
