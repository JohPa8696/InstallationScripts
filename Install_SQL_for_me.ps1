# This powershell script automate some parts in the installation of SQL Server 2016
# Name: install_sql_for_me
# Date: 8/8/2018
# Author: John Pham

# Requires: $MinimumVersion of Powershell

Param ([string]$sqlserver = ".",
        [string]$SQLInstallerAbsolutePath = "C:\shares\en_sql_server_2017_standard_x64_dvd_11294407.iso",
        [switch]$CreateMSA =$True,
        [string]$ScriptPath = "C:\Users\Administrator\Desktop\SQLInstallationScripts\Config_Scripts"
        )

# [parameter(Mandatory=$True)]
Set-StrictMode -Version 5
Import-Module ServerManager;

# Open firewall port
netsh advfirewall firewall add rule name="SQL Instances" dir=in action=allow protocol=tcp localport=1433;



function GetDotNetFramework()
{
    $WindowsVersion = [environment]::OSVersion.Version 
    
    If (($WindowsVersion.Major -eq 6) -And ($WindowsVersion.Minor -lt 2)) {
    Add-WindowsFeature AS-Net-Framework;
    }
    ElseIf (($WindowsVersion.Major -eq 6) -And ($WindowsVersion.Minor -ge 2)) {
        Add-WindowsFeature Net-Framework-Core;
    }
    ElseIf ($WindowsVersion.Major -eq 10){
        Add-WindowsFeature Net-Framework-45-Core;
    }
}



function CreateTempDirectory([string] $path)
{
    If(!(test-path $path))
    {
          New-Item -ItemType Directory -Force -Path $path
    }
}



function CopyInstallers()
{
    $TempFolder = "C:\Temp"

    CreateTempDirectory($TempFolder)

    Copy-Item -Path $SQLInstallerAbsolutePath -Destination $TempFolder
    $InstallerPath = $TempFolder+ "\" + (Split-Path $SQLInstallerAbsolutePath -leaf)
    if (!(Test-Path $InstallerPath)){
        Write-Host "Copy installer failed!"
    } 
    return $InstallerPath
}



function MountInstaller([string]$InstallerPath)
{
    $MountResult = Mount-DiskImage -ImagePath $InstallerPath -PassThru
    $MountExePath = ($MountResult | Get-Volume).DriveLetter +":\setup.exe"

    return $MountExePath
}



function DisMountInstaller([string]$InstallerPath)
{
   $MountResult = DisMount-DiskImage -ImagePath $InstallerPath
}



function InstallSQLServer([string] $SQLInstallerPath)
{
    $install = 'Start-Process -verb runas -FilePath "' + $SQLInstallerPath + '" -ArgumentList /ConfigurationFile="' + $ScriptPath + '\ConfigurationFile.ini" -Wait';

    Invoke-Expression $Install;
}


# New-Item -ItemType directory -Path D:\SQL_Data
# New-Item -ItemType directory -Path C:\SQL_Logs
# New-Item -ItemType directory -Path C:\SQLAgentLogs
# New-Item -ItemType directory -Path C:\Temp_DB

# Copy installers from fileshares to temp folder

$InstallerPath = CopyInstallers
Write-Host $InstallerPath -verbose

$MountExePath = MountInstaller($InstallerPath)
Write-Host $MountExePath -verbose

# Install dependencies
GetDotNetFramework

# Install
InstallSQLServer ($MountExePath)

# Dismount the installer

DisMountInstaller($InstallerPath)

# Clear

Write-Host "SQL Server 2017 installation complete..." -ForegroundColor Green