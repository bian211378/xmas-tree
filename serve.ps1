param([switch]$NoBrowser)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$rootPrefix = $root.TrimEnd('\') + '\'
$listener = $null
$port = 8791

foreach ($candidate in 8791..8805) {
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $candidate)
        $listener.Start()
        $port = $candidate
        break
    } catch {
        $listener = $null
    }
}

if ($null -eq $listener) {
    Write-Host 'No free local port found (8791-8805).' -ForegroundColor Red
    Read-Host 'Press Enter to close'
    exit 1
}

$url = "http://127.0.0.1:$port/index.html"
$mimeMap = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'text/javascript; charset=utf-8'
    '.mjs'  = 'text/javascript; charset=utf-8'
    '.wasm' = 'application/wasm'
    '.task' = 'application/octet-stream'
    '.json' = 'application/json; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.css'  = 'text/css; charset=utf-8'
}

Write-Host ''
Write-Host '  Christmas Tree - gesture mode' -ForegroundColor Yellow
Write-Host "  Serving: $root"
Write-Host "  Open:    $url"
Write-Host ''
Write-Host '  Keep this window open while using the camera.' -ForegroundColor DarkGray
Write-Host '  Close the window to stop the local server.' -ForegroundColor DarkGray
Write-Host ''

if (-not $NoBrowser) {
    Start-Process $url
}

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
        $requestLine = $reader.ReadLine()
        if ([string]::IsNullOrWhiteSpace($requestLine)) { continue }

        while ($true) {
            $line = $reader.ReadLine()
            if ($null -eq $line -or $line -eq '') { break }
        }

        $parts = $requestLine.Split(' ')
        $method = $parts[0]
        $target = $parts[1]
        $urlPath = ($target -split '\?')[0]
        $urlPath = [System.Uri]::UnescapeDataString($urlPath)
        if ($urlPath -eq '/') { $urlPath = '/index.html' }

        $relative = $urlPath.TrimStart('/').Replace('/', '\')
        $fullPath = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
        $isInside = $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
        $exists = $isInside -and [System.IO.File]::Exists($fullPath)

        if (-not $exists) {
            $body = [System.Text.Encoding]::UTF8.GetBytes('Not found')
            $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            if ($method -ne 'HEAD') { $stream.Write($body, 0, $body.Length) }
        } else {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
            $contentType = $mimeMap[$extension]
            if ([string]::IsNullOrWhiteSpace($contentType)) { $contentType = 'application/octet-stream' }
            $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            if ($method -ne 'HEAD') { $stream.Write($bytes, 0, $bytes.Length) }
        }
        $stream.Flush()
    } catch {
        # Ignore a dropped connection and keep serving.
    } finally {
        $client.Close()
    }
}
