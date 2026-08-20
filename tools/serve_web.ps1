# Servidor HTTP mínimo pra Godot Web em PowerShell puro.
# COOP/COEP headers são obrigatórios pro SharedArrayBuffer que o Godot 4 usa.
# Uso: powershell -ExecutionPolicy Bypass -File tools/serve_web.ps1 [-Port 8080]
param(
    [int]$Port = 8080,
    [string]$Root = ""
)

if ([string]::IsNullOrEmpty($Root)) {
    $Root = Join-Path (Split-Path -Parent $PSScriptRoot) "export\web"
}
$Root = [IO.Path]::GetFullPath($Root)

if (-not (Test-Path $Root)) {
    Write-Error "Root nao existe: $Root"
    exit 1
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".ico"  = "image/x-icon"
    ".json" = "application/json"
    ".css"  = "text/css"
    ".svg"  = "image/svg+xml"
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Error "Falhou start em $prefix : $_"
    exit 1
}

Write-Host "Servindo $Root em $prefix (Ctrl+C encerra)"

try {
    while ($listener.IsListening) {
        try {
            $ctx = $listener.GetContext()
        } catch {
            Write-Host "GetContext error: $_"
            continue
        }
        $req = $ctx.Request
        $res = $ctx.Response

        try {
            # Root path -> index.html
            $rel = $req.Url.AbsolutePath.TrimStart('/')
            if ([string]::IsNullOrEmpty($rel)) { $rel = "index.html" }
            $file = Join-Path $Root $rel
            $file = [IO.Path]::GetFullPath($file)

            # Traversal guard
            if (-not $file.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
                $res.StatusCode = 403
                $res.Close()
                continue
            }

            # Headers obrigatórios pro Godot Web
            $res.SendChunked = $false
            $res.Headers.Add("Cross-Origin-Opener-Policy", "same-origin")
            $res.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp")

            if (Test-Path $file -PathType Leaf) {
                $ext = [IO.Path]::GetExtension($file).ToLower()
                $mime = $mimeTypes[$ext]
                if (-not $mime) { $mime = "application/octet-stream" }
                $res.ContentType = $mime

                # Stream em chunks pra evitar OutOfMemory em .pck grande (79MB+)
                $stream = [IO.File]::OpenRead($file)
                try {
                    $res.ContentLength64 = $stream.Length
                    $buf = New-Object byte[] 65536
                    while (($read = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
                        $res.OutputStream.Write($buf, 0, $read)
                    }
                } finally {
                    $stream.Close()
                }
                Write-Host ("GET /{0} 200" -f $rel)
            } else {
                $res.StatusCode = 404
                $msg = [Text.Encoding]::UTF8.GetBytes("Not Found: $rel")
                $res.ContentLength64 = $msg.Length
                $res.OutputStream.Write($msg, 0, $msg.Length)
                Write-Host ("GET /{0} 404" -f $rel)
            }
        } catch {
            Write-Host ("ERROR /{0} : {1}" -f $rel, $_.Exception.Message)
            try { $res.StatusCode = 500 } catch {}
        } finally {
            try { $res.OutputStream.Close() } catch {}
            try { $res.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
