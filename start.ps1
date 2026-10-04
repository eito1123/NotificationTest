$ErrorActionPreference = 'Stop'

# index.html を読み込む
$html = [System.IO.File]::ReadAllBytes(
    (Join-Path $PSScriptRoot 'index.html')
)

# ポート番号 0 を指定すると、OSが空いているポートを自動で割り当てる
$listener = [System.Net.Sockets.TcpListener]::new(
    [System.Net.IPAddress]::Loopback,
    0
)

try {
    $listener.Start()

    # 実際に割り当てられたポート番号を取得
    $port = $listener.LocalEndpoint.Port
    $url = "http://localhost:$port/"

    Write-Host "Open $url  (Ctrl+C to stop)"

    # ブラウザを開く
    try {
        Start-Process $url
    } catch {
        Write-Host "Browser did not open automatically."
        Write-Host "Enter $url in the address bar."
    }

    while ($true) {
        $client = $listener.AcceptTcpClient()

        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new(
                $stream,
                [System.Text.Encoding]::ASCII
            )

            $requestLine = $reader.ReadLine()

            # HTTPヘッダーを読み飛ばす
            while ($true) {
                $line = $reader.ReadLine()
                if ($null -eq $line -or $line.Length -eq 0) {
                    break
                }
            }

            # / または /index.html へのGETリクエスト
            if ($requestLine -match '^GET (?:/|/index\.html)(?:\?| )') {
                $body = $html

                $header = (
                    "HTTP/1.1 200 OK`r`n" +
                    "Content-Type: text/html; charset=utf-8`r`n" +
                    "Cache-Control: no-store`r`n" +
                    "Content-Length: $($body.Length)`r`n" +
                    "Connection: close`r`n" +
                    "`r`n"
                )
            } else {
                $body = [System.Text.Encoding]::UTF8.GetBytes('Not found')

                $header = (
                    "HTTP/1.1 404 Not Found`r`n" +
                    "Content-Type: text/plain; charset=utf-8`r`n" +
                    "Content-Length: $($body.Length)`r`n" +
                    "Connection: close`r`n" +
                    "`r`n"
                )
            }

            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)

            $stream.Write(
                $headerBytes,
                0,
                $headerBytes.Length
            )

            $stream.Write(
                $body,
                0,
                $body.Length
            )
        }
        finally {
            $client.Close()
        }
    }
}
catch {
    Write-Host "Failed to start local server."
    Write-Host $_.Exception.ToString()
    Read-Host "Press Enter to exit"
}
finally {
    $listener.Stop()
}