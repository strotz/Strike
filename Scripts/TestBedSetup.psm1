Function Create-TestRunUser {
   param(
      $login,
      $password
   )

   # Create new user for script purposes
   $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"

   $user = $Computer.Create("User", $login)
   $user.SetPassword($password)
   $user.SetInfo()
   $user.FullName = "User that run Jenkins slave"
   $user.SetInfo()
   $user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
   $user.SetInfo()
}

Function Make-Administrator {
   param (
      $login
   )

   $Administrators = [ADSI]"WinNT://$Env:COMPUTERNAME/Administrators,Group"
   $User = "WinNT://$Env:COMPUTERNAME/$login,User"
   $Administrators.Add($User)
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