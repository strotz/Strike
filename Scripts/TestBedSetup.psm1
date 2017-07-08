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