Function CreateUpdate-TestRunUser {
   param(
      $login,
      $password
   )

   $computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
   $localUsers = $computer.Children | where {$_.SchemaClassName -eq 'user'}  | % {$_.name[0].ToString()} 

   if($localUsers -NotContains $login)
   { 
      Write-Host "Create User"	
      $user = $computer.Create("User", $login)
   }
   else
   {
      Write-Host "Update User"	
      $user = [ADSI]"WinNT://$Env:COMPUTERNAME/$login,User"
   }
   $user.setpassword($password)
   $user.SetInfo()
   $user.FullName = "User that run Jenkins slave"
   $user.SetInfo()
   $user.description = "CMM Test user"
   $user.SetInfo()
   $user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
   $user.SetInfo()
   return $user
}

Function Make-Administrator {
   param (
      $login
   )

   $group = [ADSI]"WinNT://$Env:COMPUTERNAME/Administrators,Group"
   $members= @($group.psbase.Invoke("Members")) | foreach{([ADSI]$_).InvokeGet("Name")}
   
   if($members -NotContains $login)
   { 
       $User = "WinNT://$Env:COMPUTERNAME/$login,User"
       $group.Add($User)
   }
   else
   {
      Write-Host "User is already administator"
   }
}

Function Enable-AutoLogin {
   param (
      $login,
      $password
   )

   $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
   
   $name = "AutoAdminLogon"
   $value = "1"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

   $name = "DefaultUserName"
   $value = $login
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null

   $name = "DefaultPassword"
   $value = $password
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null

   # "DefaultDomainName"="domain"
}


Function Enable-SlaveAutoRun {
   param (
      $cmd
   )

   $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
   
   $name = "StartSlave"
   $value = $cmd
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null
}

Function Disable-UAC {

   $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
   
   $name = "ConsentPromptBehaviorAdmin"
   $value = "0"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

   $name = "EnableLUA"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

   $name = "EnableInstallerDetection"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

   $name = "PromptOnSecureDesktop"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null

   $name = "ValidateAdminCodeSignatures"
   New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}