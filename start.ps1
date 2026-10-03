$ErrorActionPreference = 'Stop'
$html = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'index.html'))
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8000)
$listener.Start()
Write-Host 'Open http://localhost:8000/  (Ctrl+C to stop)'
try {
    Start-Process 'http://localhost:8000/'
} catch {
    Write-Host 'Browser did not open automatically. Enter http://localhost:8000/ in the address bar.'
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII)
            $requestLine = $reader.ReadLine()
            while ($true) {
                $line = $reader.ReadLine()
                if ($null -eq $line -or $line.Length -eq 0) { break }
            }

            if ($requestLine -match '^GET (?:/|/index\.html)(?:\?| )') {
                $body = $html
                $header = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nCache-Control: no-store`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
            } else {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Not found')
                $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
            }

            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($body, 0, $body.Length)
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
