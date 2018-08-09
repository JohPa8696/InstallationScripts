Param
(
    [string]$SSMSInstallerPath="C:\shares\SSMS-Setup-ENU.exe"
)

# [parameter(Mandatory=$True)]

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

    Copy-Item -Path $SSMSInstallerPath -Destination $TempFolder
    $InstallerPath = $TempFolder+ "\" + (Split-Path $SSMSInstallerPath -leaf)
    if (!(Test-Path $InstallerPath)){
        Write-Host "Copy installer failed!"
    } 
    return $InstallerPath
}



$InstallerPath = CopyInstallers

Write-Host "Beginning SSMS 2017 install..."

$Params = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Params.Split(" ")
& "$InstallerPath" $Prms | Out-Null

Write-Host "SSMS 2017 installation complete..." -ForegroundColor Green