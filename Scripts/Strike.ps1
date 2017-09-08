#
# Strike.ps1
#

#
# PowerShell 2.0 compatibility
#
if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force
Import-Module $PSScriptRoot\World.psm1

Assert-Administrator
Assert-V2

Write-Host "Validating computer and VM names..."

$computerName = Get-VComputerName

#
# Ensure that current PC is VMWare 
#
$WMISplat = @{}
$WMISplat.ComputerName = $computerName
$wmibios = Get-WmiObject Win32_BIOS @WMISplat -ErrorAction Stop | Select-Object version, serialnumber
$underVMWare = if ($wmibios.SerialNumber -like "*VMware*") { $true } else { $false }
if (!$underVMWare) {
    Write-Host -NoNewLine "Not running on VM"
    Stop-WithWait
}

Import-Module $PSScriptRoot\VMTools.psm1

$server = Resolve-VMWareServer
Write-Host "We need to connect to VMVare server:" $server
$name = Resolve-VMWareLogin
$plain = Resolve-VMWarePassword

try {
    # Allow the use of self-signed SSL certificates.
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

    $viServer = Connect-VIServer -Server $server -Protocol https -User $name -Password $plain
    if (!$viServer) {
        Write-Host -fore red 'Cannot connect to VIServer'
        Stop-WithWait
    }
}
catch {
    Write-Host -fore red 'Cannot connect to VIServer'
    Stop-WithWait
}

$vmName = (Get-View -ViewType VirtualMachine -Property Name -Filter @{"Guest.HostName" = "^$($computerName)$"}).Name
if ($computerName -ne $vmName) {
    Write-Host -fore red "WARNING: VM ($vmName) and Guest OS host name ($computerName) are different"
    $slaveName = if (($result = Read-Host "Verify slave name [$vmName]") -eq '') {$vmName} else {$result}
}
else {
    Write-Host -fore green "Use $vmName for slave registration"
    $slaveName = $vmName
}

$nodeLabel = Resolve-JenkinsNodeLabel

Import-Module $PSScriptRoot\Jenkins.psm1
Register-Slave -SlaveName $slaveName -SlaveDescription "Test automation slave" -SlaveLabel $nodeLabel

Import-Module $PSScriptRoot\TestBedSetup.psm1

Write-Host "Setting jenkins user account..."
$windowsUser = Resolve-AutomationUserLogin
$windowsPassword = Resolve-AutomationUserPassword
$user = CreateUpdate-TestRunUser -Login $windowsUser -Password $windowsPassword

Write-Host "Adding administrative permissions..."
Make-Administrator -Login $windowsUser

Write-Host "Enabling auto logon..."
Enable-AutoLogin -Login $windowsUser -Password $windowsPassword

Write-Host "Enabling jenkins slave auto run..."
$location = Resolve-InstallLocation
$jenkinsSlaveCmd = "$location\jenkins\start_slave.cmd"
Enable-SlaveAutoRun -Cmd $jenkinsSlaveCmd

Write-Host "Disabling UAC..."
Disable-UAC

Write-Host -fore green "Slave setup is complete. PC need to be rebooted"

Write-Host "Press 'R' to REBOOT or any other key to exit..."
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
if ($key.Character -eq "R") {
    Write-Host "rebooting"
    Restart-Computer -Force
}
