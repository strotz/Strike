#
# Strike.ps1
#

#
# Functions
# TODO: move to modules

Function Get-VComputerName {[system.environment]::MachineName}

Function ExitWithWait {
    Write-Host -NoNewLine "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
{
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
}
else
{
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
}


#
# PowerShell 2.0 compatibility
#
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

#
# Checking for powershell version and call upgrade
#
if (!$PSVersionTable) { $PVersion = 1 } Else { $PVersion = $PSVersionTable.PSVersion.Major }
if ($PVersion -le 3) {
    Write-Host "Version of PowerShell:" $PVersion  
    Write-Host "Need upgrade PowerShell, reboot is required"
    $continue = if (($result = Read-Host "Continue with update [Y]") -eq '') {"Y"} else {"N"}
    if ($continue -eq "Y") {
        Invoke-expression -Command $PSScriptRoot\Upgrade.ps1
    }
    exit
}

Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force

Write-Host "Validating computer and VM names..."

$computerName = Get-VComputerName

#
# Ensure that current PC is VMWare 
#
$WMISplat = @{}
$WMISplat.ComputerName = $computerName
$wmibios = Get-WmiObject Win32_BIOS @WMISplat -ErrorAction Stop | Select-Object version,serialnumber
$underVMWare = if ($wmibios.SerialNumber -like "*VMware*") { $true } else { $false }
if (!$underVMWare) {
    Write-Host -NoNewLine "Not running on VM"
    ExitWithWait
}

Import-Module $PSScriptRoot\VMTools.psm1

Write-Host "We need to connect to VMVare server:" $global:config.VMWareServer

$name = if (!$global:config.VMWareLogin) { Read-Host 'What is your username?' } Else { $global:config.VMWareLogin }
if (!$global:config.VMWarePassword) 
{ 
    $pass = Read-Host 'What is your password?' -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
}
Else
{
    $plain = $global:config.VMWarePassword
}


try
{
    $viServer = Connect-VIServer -Server $global:config.VMWareServer -Protocol https -User $name -Password $plain
    if (!$viServer) {
       Write-Host 'Cannot connect to VIServer'
       ExitWithWait
    }
}
catch 
{
    Write-Host 'Cannot connect to VIServer'
    ExitWithWait
}

$vmName = (Get-View -ViewType VirtualMachine -Property Name -Filter @{"Guest.HostName" = "^$($computerName)$"}).Name
if ($computerName -ne $vmName) 
{
    Write-Host -fore red "WARNING: VM ($vmName) and Guest OS host name ($computerName) are different"
}
else
{
    Write-Host -fore green "Use $computerName for slave registration"
}

# $computerName = if (($result = Read-Host "Verify VM name [$computerName]") -eq '') {$computerName} else {$result}

ExitWithWait
