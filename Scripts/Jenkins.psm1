function Register-Slave 
{
param(
    $slaveName,
    $slaveDescription,
    $slaveLabel
)

if (!$slaveName) {
    Write-Host -fore red "Slave name must be specified" 
}

Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force

#
# Confirm install location
#

$location = $global:config.InstallLocation
if (!$location)
{
    $defaultInstallLocation = "C:\automation"
    $location = if (($result = Read-Host "What is install location is [$defaultInstallLocation]") -eq '') {$defaultInstallLocation} else {$result}
}

$jenkinsCliLocation = "$location\jenkins\"
$jenkinsCli = "$($jenkinsCliLocation)jenkins-cli.jar"

if (-not (Test-Path $jenkinsCliLocation)) 
{ 
    $_ = New-Item -ItemType Directory -Force -Path $jenkinsCliLocation
}

$jenkins = $global:config.JenkinsServerUrl
Write-Host "Now let's connect to Jenkins server ($jenkins) and register slave" 
$wc = New-Object System.Net.WebClient

if (-not (Test-Path $jenkinsCli)) 
{ 
    $jenkinsCliUrl = "$($jenkins)jnlpJars/jenkins-cli.jar"
    Write-Host "Downloading Jenkins client from $jenkinsCliUrl to $jenkinsCli"
    $start_time = Get-Date
    $wc.DownloadFile($jenkinsCliUrl, $jenkinsCli)
    Write-Host "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

#
# TODO: current assumption that java binary located at $($global:config.InstallLocation)\jre\bin\java.exe 
#

$java = "$($global:config.InstallLocation)\jre\bin\java.exe"

$jenkinsLogin = $global:config.JenkinsLogin
$jenkinsPassword = $global:config.JenkinsPassword

$jenkinsHome = $global:config.JenkinsLocation

$run = Start-Process $java  -ArgumentList '-jar',$jenkinsCli,'-s',$jenkins,'login','--username',$jenkinsLogin,'--password',$jenkinsPassword -NoNewWindow -PassThru
$run.WaitForExit()

$xml = "<slave>"
$xml += "<name>$slaveName</name>"
$xml += "<description>$slaveDescription</description>"
$xml += "<remoteFS>$jenkinsHome</remoteFS>"
$xml += "<numExecutors>1</numExecutors>"

if (!$slaveLavel) {
    $xml += "<mode>EXCLUSIVE</mode>"
    $xml += "<label>$slaveLabel</label>"
}

$xml += "<retentionStrategy class=`"hudson.slaves.RetentionStrategy`$Always`"/>"
$xml += "<launcher class=`"hudson.slaves.JNLPLauncher`"/>"
$xml += "<userId>$jenkinsLogin</userId>"
$xml +="</slave>" 

#Write-Host $xml
$arguments = "-jar",$jenkinsCli,"-s",$jenkins,"create-node",$slaveName
$xml | & $java $arguments 
}

export-modulemember -function Register-Slave
