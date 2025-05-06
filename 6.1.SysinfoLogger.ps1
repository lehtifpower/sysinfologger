<#
$remoteComputer = "PC2"
$remoteUser = "$remoteComputer\Albert"


# Define the script block to create and run the scheduled task
$scriptBlock = {
  param($remoteUser)
  # Create a scheduled task to launch Microsoft Edge
  $action = New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -Argument "https://www.google.com"
  Register-ScheduledTask -TaskName "RunEdge" -User $remoteUser -Action $action
  # Run the scheduled task
  Start-ScheduledTask -TaskName "RunEdge"
  # Optionally, remove the task after execution
  Unregister-ScheduledTask -TaskName "RunEdge" -Confirm:$false
}

# Create a remote PowerShell session

# Invoke the script block on the remote computer
# Close the remote session
Remove-PSSession -Session $session
#>
param (
    [Parameter(Mandatory = $True)][string]$remoteMachine
)

$scriptBlock = {

$date = Get-Date -Format "dd/MM/yyyy"
$time = Get-Date -Format "HH:mm:ss"
$osName = (Get-CimInstance CIM_OperatingSystem).Caption
$osVersion = (get-ciminstance CIM_OperatingSystem).Version
$osBuild = (get-ciminstance CIM_OperatingSystem).BuildNumber
$hostName = (get-ciminstance CIM_OperatingSystem).CSName
$programs = (Get-CimInstance CIM_Product).Name
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

foreach ($program in $programs) {
    $installedPrograms = $installedPrograms + $program + "`n" +
    "|  " 
}

$logTab = "╔══════════════════════════════════════════════════════════════════════════════════╗`n" +
          "║                                  SYSINFO LOGGER                                  ║`n" +
          "╠══════════════════════════════════════════════════════════════════════════════════╣`n" +
          "║ Log date : " + $time + "                                                              ║`n" +
          "╚══════════════════════════════════════════════════════════════════════════════════╝`n"

$log =  
"`n┌─ OPERATING SYSTEM :" + 
"`n|  " +
"`n│  Hostname:     " + $hostName +
"`n│  OS:           " + $osName +
"`n|  Version:      " + $osVersion + " Build " + $osBuild +
"`n|  IPv4:         " + $ip.IPv4Address.ipaddress +
"`n" +
"`n┌─ HARDWARE :" +
"`n|  " +
"`n|  CPU:          " + $cpuName +
"`n|  RAM:          " + $usedRAM.ToString('.00') + " GB / " + $totalRAM.ToString('.00') + " GB" +
"`n|  DISK          " + ($usedDiskSpace / 1GB).ToString('.00') + " GB / " + ($diskSize / 1GB).ToString('.00') + " GB" +
"`n" +
"`n┌─ INSTALLED PROGRAMS :" + 
"`n|  " +
"`n|  " + $installedPrograms +
"`n" 


$logTab + $log | Out-File -encoding utf8 -FilePath "Z:/projet/logs/$date Sysinfologger.log" -Append
$log | Write-Host

}


$session = New-PSSession -ComputerName $remoteMachine -Credential (Get-Credential)
Invoke-Command -Session $session -ScriptBlock $scriptBlock 
Remove-PSSession -Session $session
