Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force

$jenkins = $global:config.JenkinsServerUrl
Write-Host "Now let's connect to Jenkins server ($jenkins) and register slave" 

$wc = New-Object System.Net.WebClient

$jenkinsCli = "$PSScriptRoot\jenkins-cli.jar"

if (-not (Test-Path $jenkinsCli)) 
{ 
    $jenkinsCliUrl = "$($jenkins)jnlpJars/jenkins-cli.jar"
    Write-Host "Downloading Jenkins client from $jenkinsCliUrl to $jenkinsCli"
    $start_time = Get-Date
    $wc.DownloadFile($jenkinsCliUrl, $jenkinsCli)
    Write-Host "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}
