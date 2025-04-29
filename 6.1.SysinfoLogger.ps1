# Write-Host "`nOperating System ↓" -ForegroundColor magenta
# 
# get-ciminstance CIM_OperatingSystem | format-list Version, BuildNumber, Caption, CSName
# 
# 
# Write-Host "IPv4        : " $ip.IPv4Address.ipaddress -ForegroundColor Green
# 
# Write-Host "Installed programs ↓" -ForegroundColor Magenta
# 
# Get-CimInstance CIM_Product | Select-Object Caption

$date = Get-Date -Format "dd/MM/yyyy"
$time = Get-Date -Format "HH:mm:ss"
$osName = (Get-CimInstance CIM_OperatingSystem).Caption
$osVersion = (get-ciminstance CIM_OperatingSystem).Version
$osBuild = (get-ciminstance CIM_OperatingSystem).BuildNumber
$hostName = (get-ciminstance CIM_OperatingSystem).CSName
$programs = (Get-CimInstance CIM_Product).Caption | Format-List
$ip = Get-NetIPConfiguration | Where-Object{$_.ipv4defaultgateway -ne $null};
$cpuName = (Get-CimInstance CIM_Processor).name
$totalRAM = ((Get-CIMInstance CIM_OperatingSystem).TotalVisibleMemorySize / 1MB)
$usedRAM = ($totalRAM - (Get-CIMInstance CIM_OperatingSystem).FreePhysicalMemory / 1MB)
$disks = Get-CimInstance CIM_LogicalDisk

foreach ($disk in $disks) { 
    if ($disk.DeviceID -eq "C:") {
        $usedDiskSpace = $disk.Size - $disk.FreeSpace
        $diskSize = $disk.Size
    }
}

$logTab = "╔══════════════════════════════════════════════════════════════════════════════════╗`n" +
          "║                                  SYSINFO LOGGER                                  ║`n" +
          "╠══════════════════════════════════════════════════════════════════════════════════╣`n" +
          "║ Log date : " + $time + "                                                              ║`n" +
          "╚══════════════════════════════════════════════════════════════════════════════════╝`n"

$log =  
"`n┌─ OPERATING SYSTEM " + 
"`n│  Hostname:     " + $hostName +
"`n│  OS:           " + $osName +
"`n|  Version:      " + $osVersion + " Build " + $osBuild +
"`n|  IPv4:         " + $ip.IPv4Address.ipaddress +
"`n" +
"`n┌─ HARDWARE" +
"`n|  CPU:          " + $cpuName +
"`n|  RAM:          " + $usedRAM.ToString('.00') + " GB / " + $totalRAM.ToString('.00') + " GB" +
"`n|  DISK          " + ($usedDiskSpace / 1GB).ToString('.00') + " GB / " + ($diskSize / 1GB).ToString('.00') + " GB" +
"`n" +
"`n┌─ Installed programs:  " + 
"`n|  " + $programs +
"`n|  " 
"`n" 


$logTab + $log | Out-File -FilePath "logs/$date Sysinfologger.log" -Append
$log | Write-Host
