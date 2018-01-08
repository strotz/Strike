$global:config = @{   
    InstallLocation = "C:\automation"
    JenkinsLocation = "C:\jenkins"

    VMWareServer = "server IP or name"
    VMWareLogin = "login for  VServer"    
    VMWarePassword = "password for VServer"
    VMWareDataCenterName = ""

    JenkinsServerUrl = "http://jenkins/"
    JenkinsLogin = "login for Jenkins server"
    JenkinsPassword = "password for Jenkins server"

    NodeLabel = "jenkins_group"

    JenkinsWindowsUser = "jenkins"
    JenkinsWindowsPassword = "Captain00"

    NodeProperties = @{
        user = "user"
    }
}