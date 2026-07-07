$ports = @(8930, 8137, 8641, 9317, 8880)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = $null
$port = 0
foreach ($p in $ports) {
  $l = New-Object System.Net.HttpListener
  $l.Prefixes.Add("http://localhost:$p/")
  try { $l.Start(); $listener = $l; $port = $p; break } catch { }
}
if (-not $listener) {
  Write-Host "Could not start the server (all ports busy). Maybe it is already running?"
  Start-Process "http://localhost:$($ports[0])/"
  exit
}
Write-Host ""
Write-Host "  Mirror trainer is running: http://localhost:$port/"
Write-Host "  Do NOT close this window while training."
Write-Host "  To stop the app - just close this window."
Write-Host ""
Start-Process "http://localhost:$port/"
$mime = @{ ".html"="text/html; charset=utf-8"; ".js"="text/javascript"; ".css"="text/css";
           ".png"="image/png"; ".jpg"="image/jpeg"; ".svg"="image/svg+xml"; ".mp4"="video/mp4" }
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.LocalPath.TrimStart("/")
    if ($path -eq "") { $path = "index.html" }
    $file = Join-Path $root $path
    if ((Test-Path $file) -and (Resolve-Path $file).Path.StartsWith($root)) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  } catch { }
}
