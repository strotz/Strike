if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Import-Module $PSScriptRoot\ConfigLoad.psm1 -Force

Import-Module $PSScriptRoot\VMTools.psm1

$server = Resolve-VMWareServer
Write-Host "We need to connect to VMVare server:" $server
$name = Resolve-VMWareLogin
$plain = Resolve-VMWarePassword
$dataCenterName = Resolve-VMWareDataCenterName

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

$dataCenter = Get-View -ViewType Datacenter -Property Name,VmFolder -Filter @{"Name" = $dataCenterName }
$allVms = Get-View -ViewType VirtualMachine -SearchRoot $dataCenter.VmFolder

Foreach($vm in $allVms) 
{ 
    $macs = Foreach($networkCard in ($vm.config.hardware.device | ?{$_ -is [Vmware.vim.virtualethernetCard]})) {$networkCard.macaddress}
    $macString = $macs -Join ';' 
    Write-Host ("{0},{1},{2},{3}" -f $vm.Name,$macString,$vm.Guest.HostName,$vm.Guest.GuestFullName)
}
