if ((gwmi win32_computersystem).partofdomain -eq $true) {
    Write-Host -fore red "Domain VM are not supported yet!"
}


