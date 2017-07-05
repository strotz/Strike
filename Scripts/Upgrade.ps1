Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$z = $env:ProgramData
$z = Join-Path $z \chocolatey\bin\cinst.exe
Start-Process $z -ArgumentList 'powershell -y'
exit

