#
# Functions
#
Function Get-VComputerName {
    return [system.environment]::MachineName
}

Function Stop-WithWait {
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Function Assert-Administrator {
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole)) {
        # We are running "as Administrator" - so change the title and background color to indicate this
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
        $Host.UI.RawUI.BackgroundColor = "DarkBlue"
        clear-host
    }
    else {
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
}

#
# Checking for powershell version and call upgrade
#
Function Assert-V2 {
    if (!$PSVersionTable) { $PVersion = 1 } Else { $PVersion = $PSVersionTable.PSVersion.Major }
    if ($PVersion -le 3) {
        Write-Host "Version of PowerShell:" $PVersion  
        Write-Host "Need upgrade PowerShell, reboot is required"
        $continue = if (($result = Read-Host "Continue with update [Y]") -eq '') {"Y"} else {"N"}
        if ($continue -eq "Y") {
            Write-Host "Start PowerShell upgrade sequence" 
            Start-Process PowerShell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSScriptRoot\Upgrade.ps1, '-Verb', 'RunAs'
        }
        exit
    }
}

Function Invoke-Command ($commandTitle, $commandPath, $commandArguments) {
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
        stdout       = $p.StandardOutput.ReadToEnd()
        stderr       = $p.StandardError.ReadToEnd()
        ExitCode     = $p.ExitCode  
    }
}

Export-ModuleMember -function Get-VComputerName, Stop-WithWait, Assert-Administrator, Assert-V2, Invoke-Command