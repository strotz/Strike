Function Execute-Command ($commandTitle, $commandPath, $commandArguments)
{
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    [pscustomobject]@{
        commandTitle = $commandTitle
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode  
    }
}

Function Resolve-InstallLocation {

   if (!$global:InstallLocation) 
   {
      $location = $global:config.InstallLocation
      if (!$location)
      {
         $defaultInstallLocation = "C:\automation"
         $location = if (($result = Read-Host "What is install location is [$defaultInstallLocation]") -eq '') {$defaultInstallLocation} else {$result}
      }
      $global:InstallLocation = $location
   }
   return $global:InstallLocation
}

Function Generate-NodeFile ($slaveName, $slaveDescription, $slaveLabel, $jenkinsLogin, $properties) {

   # TODO: ask?
   Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force
   $jenkinsHome = $global:config.JenkinsLocation


   $xml = "<slave>`n"
   $xml += "<name>$slaveName</name>`n"
   $xml += "<description>$slaveDescription</description>`n"
   $xml += "<remoteFS>$jenkinsHome</remoteFS>`n"
   $xml += "<numExecutors>1</numExecutors>`n"

   if ($slaveLabel) {
      $xml += "<mode>EXCLUSIVE</mode>`n"
      $xml += "<label>$slaveLabel</label>`n"
   }
   else
   {
      Write-Host "Skipping slave label" 		
   }

   if ($properties) {
      $xml += "<nodeProperties>`n"
      $xml += "<hudson.slaves.EnvironmentVariablesNodeProperty>`n"
      $xml += "<envVars serialization=`"custom`">`n"
      $xml += "<unserializable-parents/>`n"
      $xml += "<tree-map>`n"
      $xml += "<default><comparator class=`"hudson.util.CaseInsensitiveComparator`"/></default>`n"

      $xml += "<int>$($properties.count)</int>`n"
      foreach ($key in $properties.Keys) {
         $xml += "<string>$($key)</string>`n"
         $xml += "<string>$($properties.$key)</string>`n" 
      }

      $xml += "</tree-map>`n"
      $xml += "</envVars>`n"
      $xml += "</hudson.slaves.EnvironmentVariablesNodeProperty>`n"
      $xml += "</nodeProperties>`n"
   }
   else
   { 
      Write-Host "Skipping properties" 		
   }

   $xml += "<retentionStrategy class=`"hudson.slaves.RetentionStrategy`$Always`"/>`n"
   $xml += "<launcher class=`"hudson.slaves.JNLPLauncher`"/>`n"
   $xml += "<userId>$jenkinsLogin</userId>`n"
   $xml += "</slave>`n" 
   return $xml
}

Function Register-Slave 
{
param(
    $slaveName,
    $slaveDescription,
    $slaveLabel
)

Write-Host "Registering as jenkins slave..."

if (!$slaveName) {
    Write-Host -fore red "Slave name must be specified" 
}

Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force

#
# Confirm install location
#

$location = Resolve-InstallLocation
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

# TODO: unify to use Execute-Command
$run = Start-Process $java -ArgumentList '-jar',$jenkinsCli,'-s',$jenkins,'login','--username',$jenkinsLogin,'--password',$jenkinsPassword -NoNewWindow -PassThru
$run.WaitForExit()

$xml = Generate-NodeFile -SlaveName $slaveName -SlaveDescription $slaveDescription -SlaveLabel $slaveLabel -JenkinsLogin $jenkinsLogin 

# TODO: unify to use Execute-Command
$arguments = "-jar",$jenkinsCli,"-s",$jenkins,"create-node",$slaveName
$xml | & $java $arguments 

$groovyScript = "$PSScriptRoot\readslave.groovy"
$arguments = '-jar',$jenkinsCli,'-s',$jenkins,'groovy',$groovyScript,$slaveName
$result = Execute-Command -CommandTitle  'readslave' -CommandPath  $java  -CommandArguments $arguments
$secret = $result.stdout.TrimEnd()

# TODO: download slave.jar to $jenkinsCliLocation C:\automation\jenkins

#
# Create start_slave.cmd
#
$startCmd = ""
$startCmd += "set NAME=$slaveName`r`n"
$startCmd += "set JSERVER=$jenkins`r`n"
$startCmd += "set SECRET=$secret`r`n"
$startCmd += "set ThisDir=%~dp0`r`n"
$startCmd += "%ThisDir%\..\jre\bin\java.exe -jar %ThisDir%\slave.jar -jnlpUrl %JSERVER%/computer/%NAME%/slave-agent.jnlp -secret %SECRET%`r`n"
$startCmd | Set-Content "$($jenkinsCliLocation)start_slave.cmd"

}

export-modulemember -function Register-Slave, Resolve-InstallLocation, Generate-NodeFile
