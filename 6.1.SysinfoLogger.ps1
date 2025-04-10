Write-Host "`nOperating System ↓" -ForegroundColor magenta

get-ciminstance CIM_OperatingSystem | format-list Version, BuildNumber, Caption, CSName

Write-Host "Installed programs ↓" -ForegroundColor Magenta

Get-CimInstance CIM_Product | Format-List Name

$osName = (Get-CimInstance CIM_OperatingSystem).Caption
$osVersion = (get-ciminstance CIM_OperatingSystem).Version
$osBuild = (get-ciminstance CIM_OperatingSystem).BuildNumber
$hostName = (get-ciminstance CIM_OperatingSystem).CSName
$programs = (Get-CimInstance CIM_Product).Name
$date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

$logTab = "╔══════════════════════════════════════════════════════════════════════════════════╗
║                                  SYSINFO LOGGER                                  ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║ Log date : " + $date + "                                                   ║
╚══════════════════════════════════════════════════════════════════════════════════╝"


$logTab + "`n`n┌  OPERATING SYSTEM `n|  Hostname:     " + $hostName +
"`n|  OS:           " + $osName +
"`n|  Version:      " + $osVersion + " Build" + $osBuild +
"`nInstalled programs:  " + $programs| Out-File -FilePath "AlbertLatif-Sysinfologger.log" -Append

