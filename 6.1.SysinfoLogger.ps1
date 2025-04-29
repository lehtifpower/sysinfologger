Write-Host "`nOperating System ↓" -ForegroundColor magenta

get-ciminstance CIM_OperatingSystem | format-list Version, BuildNumber, Caption, CSName

Write-Host "Installed programs ↓" -ForegroundColor Magenta

Get-CimInstance CIM_Product | Select-Object Caption

$osName = (Get-CimInstance CIM_OperatingSystem).Caption
$osVersion = (get-ciminstance CIM_OperatingSystem).Version
$osBuild = (get-ciminstance CIM_OperatingSystem).BuildNumber
$hostName = (get-ciminstance CIM_OperatingSystem).CSName
$programs = (Get-CimInstance CIM_Product).Caption
$partitions = Get-CimInstance -Class CIM_LogicalDisk

foreach ($partition in $partitions) { 
    if ($partition.DeviceID -eq "C:") {
        $usedSpace = $partition.Size - $partition.FreeSpace
        Write-Host ($usedSpace / 1048576)
    }
}

$cpuName = (Get-CimInstance CIM_Processor).name
$totalRAM = (Get-CIMInstance CIM_OperatingSystem).TotalVisibleMemorySize
$date = Get-Date -Format "dd/MM/yyyy"
$time = Get-Date -Format "HH:mm:ss"





$logTab = "╔══════════════════════════════════════════════════════════════════════════════════╗`n" +
          "║                                  SYSINFO LOGGER                                  ║`n" +
          "╠══════════════════════════════════════════════════════════════════════════════════╣`n" +
          "║ Log date : " + $time + "                                                              ║`n" +
          "╚══════════════════════════════════════════════════════════════════════════════════╝`n"

$logTab + 
"`n┌  OPERATING SYSTEM " + 
"`n|  Hostname:     " + $hostName +
"`n|  OS:           " + $osName +
"`n|  Version:      " + $osVersion + " Build " + $osBuild +
"`n" +
"`n┌  HARDWARE" +
"`n|  CPU" + $cpuName +
"`n" +
"`n" +
"`n┌  Installed programs:  " + 
"`n|  $programs" +
"`n" +
"`n" | Out-File -FilePath "logs/$date Sysinfologger.log" -Append

