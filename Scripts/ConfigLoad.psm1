. $PSScriptRoot\..\Config.ps1

Function Resolve-InstallLocation {
    if (!$global:InstallLocation) {
        $location = $global:config.InstallLocation
        if (!$location) {
            $defaultLocation = "C:\automation"
            $location = if (($result = Read-Host "What is install location [$defaultLocation]") -eq '') {$defaultLocation} else {$result}
        }
        $global:InstallLocation = $location
    }
    return $global:InstallLocation
}
 
Function Resolve-JenkinsJobLocation {
    if (!$global:JenkinsJobLocation) {
        $location = $global:config.JenkinsLocation
        if (!$location) {
            $defaultLocation = "C:\jenkins"
            $location = if (($result = Read-Host "What is jenkins job location [$defaultLocation]") -eq '') {$defaultLocation} else {$result}
        }
        $global:JenkinsJobLocation = $location
    }
    return $global:JenkinsJobLocation
}
 
Function Resolve-VMWareServer {
    return $global:config.VMWareServer
}

Function Resolve-VMWareLogin {
    if (!$global:VMWareLogin) {
        $name = $global:config.VMWareLogin
        if (!$name) { 
            $name = Read-Host 'What is your username?'
        }
        $global:VMWareLogin = $name
    }
    return $global:VMWareLogin
}

Function Resolve-VMWarePassword {
    if (!$global:VMWarePassword) {
        $password = $global:config.VMWarePassword
        if (!$password) { 
            $pass = Read-Host 'What is your password?' -AsSecureString
            $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
        }
        $global:VMWarePassword = $password
    }
    return $global:VMWarePassword
}

Function Resolve-JenkinsLogin {
    if (!$global:JenkinsLogin) {
        $jenkinsLogin = $global:config.JenkinsLogin
        if (!$jenkinsLogin) {
            $jenkinsLogin = Read-Host "What is your Jenkins login?"
        }
        $global:JenkinsLogin = $jenkinsLogin
    }
    return $global:JenkinsLogin
} 

Function Resolve-JenkinsPassword {
    if (!$global:JenkinsPassword) {
        $jenkinsPassword = $global:config.JenkinsPassword
        if (!$jenkinsPassword) {
            $pass = Read-Host 'What is your Jenkins password?' -AsSecureString
            $jenkinsPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))

        }
        $global:JenkinsPassword = $jenkinsPassword
    }
    return $global:JenkinsPassword
}

Function Resolve-JenkinsNodeLabel {
    $global:config.NodeLabel
}

Export-ModuleMember -function Resolve-InstallLocation, Resolve-JenkinsJobLocation, 
    Resolve-VMWareServer, Resolve-VMWareLogin, Resolve-VMWarePassword, Resolve-JenkinsLogin,
    Resolve-JenkinsPassword, Resolve-JenkinsNodeLabel
