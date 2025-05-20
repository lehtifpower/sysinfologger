<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script : SysinfoLogger.ps1
    Auteur : 	    Albert Braimi, Latif Krasniqi
    Date :	        20.05.2025
 	*****************************************************************************
    Modifications
 	Date  : -
 	Auteur: -
 	Raisons: -
 	*****************************************************************************
.SYNOPSIS
	Script Permettant de recuperer des informations sur une machine local ou distante
 	
.DESCRIPTION
    Ce script PowerShell collecte des informations système d’un ordinateur local ou distant (via le paramètre -RemoteMachine) : 
    système d’exploitation, adresse IPv4, processeur, mémoire, disques et programmes installés. 
    Il utilise une session CIM pour récupérer les données, les formate et les enregistre dans un fichier log structuré,
    créé dans le dossier ./logs. Un nouveau fichier est généré à chaque exécution avec la date et l’heure,
    ce qui permet de suivre l’évolution des informations chaque jour.

.PARAMETER RemoteMachine
    choix de l'utilisateur si il choisit de recuperer les informations de la machine local ou distante.
	
.OUTPUTS
	Création d'un nouveau de fichier de log chaque jour contenant l'heure du log et les informations de la machine.
	
.EXAMPLE
	.\Sysinfologger.ps1 -RemoteMachine IP (distante ou local)
	
    Nom de l'hote : ...
    Credential : ...

    ┌─ OPERATING SYSTEM :
    |  
    │  Hostname: 	PC2
    │  OS:       	Microsoft Version d’évaluation de Windows 11 Entreprise
    |  Version:  	10.0.22000 Build 22000
    |  IPv4:     	172.20.0.2
    |
    ├─ HARDWARE :
    |
    |  CPU: 		12th Gen Intel(R) Core(TM) i7-12700F
    |  RAM: 		2,08 GB / 3,99 GB
    |  DISK:  	C:	23,71 GB / 63,28 GB
    |  			S:	,05 GB / 15,00 GB
    |  			T:	,06 GB / 24,98 GB
    |  			
    ├─ INSTALLED PROGRAMS :
    |  VirtualBox
    |  PowerShell 7-x64
    |  CIM Explorer
    |  Microsoft Update Health Tools
    |  


	
.EXAMPLE
    .\Sysinfologger.ps1

    Comme aucune adresse IP n'est renseignée, le script va s'exécuter sur la machine locale

    ┌─ OPERATING SYSTEM :
    |  
    │  Hostname: 	DESKTOP-DSVUCAI
    │  OS:       	Microsoft Windows 10 Pro
    |  Version:  	10.0.19045 Build 19045
    |  IPv4:     	192.168.1.22
    |
    ├─ HARDWARE :
    |
    |  CPU: 		AMD Ryzen 7 9800X3D 8-Core Processor           
    |  RAM: 		13.44 GB / 31.15 GB
    |  DISK:  	C:	1218.79 GB / 1862.38 GB
    |  			D:	140.12 GB / 175.71 GB
    |  			E:	274.43 GB / 14901.98 GB
    |  			I:	187.28 GB / 465.76 GB
    |  			
    ├─ INSTALLED PROGRAMS :
    |  Blender
    |  AMD DVR64
    |  Eclipse Temurin JDK with Hotspot 22.0.2+9 (x64)
    |  RyzenMasterSDK
    |  PowerShell 7-x64
    |  Eclipse Temurin JDK with Hotspot 21.0.6+7 (x64)
    |  AMD Ryzen Master
    |  AMD WVR64
    |  logisim-evolution

#>

# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire 
param (
    [Parameter(Mandatory = $false)][string]$RemoteMachine
)

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs

if (!([string]::IsNullOrEmpty($RemoteMachine))) {
    if (Test-Connection -ComputerName $RemoteMachine -Count 1 -Quiet) {
        Write-Host "$RemoteMachine is reachable"
        try {
            $session = New-CimSession -ComputerName $RemoteMachine -Credential (Get-Credential) -ErrorAction Stop          
        }
        catch {
            Write-Host "Nom d'utilisateur ou mot de passe incorrect"
            exit
        }
    } 
    else {
        Write-Host "$RemoteMachine is not reachable"
        exit
    }
}
else {
    $session = New-CimSession -ComputerName $env:COMPUTERNAME
}

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples

if (!([string]::IsNullOrEmpty($session))) {
    $date = Get-Date -Format "dd-MM-yyyy"                                                                                       # Date
    $time = Get-Date -Format "HH:mm:ss"                                                                                         # Heure
    $osName = (Get-CimInstance -CimSession $session CIM_OperatingSystem).Caption                                                # Nom du système d'exploitation
    $osVersion = (Get-CimInstance -CimSession $session CIM_OperatingSystem).Version                                             # Version du système d'exploitation
    $osBuild = (Get-CimInstance -CimSession $session CIM_OperatingSystem).BuildNumber                                           # Version du build de l'OS
    $hostName = (Get-CimInstance -CimSession $session CIM_OperatingSystem).CSName                                               # Nom de l'hôte
    $programs = (Get-CimInstance -CimSession $session CIM_Product).Name                                                         # Liste des programes installés
    $ip = (Get-CimInstance -CimSession $session Win32_NetworkAdapterConfiguration).IPAddress | Where-Object { $_ -like '*.*' }  # Adresse IP de la machine
    $cpuName = (Get-CimInstance -CimSession $session CIM_Processor).name                                                        # Nom du CPU
    $totalRAM = (Get-CimInstance -CimSession $session CIM_OperatingSystem).TotalVisibleMemorySize / 1MB                         # Quantité totale de RAM
    $usedRAM = $totalRAM - (Get-CimInstance -CimSession $session CIM_OperatingSystem).FreePhysicalMemory / 1MB                  # Quantitée de RAM utilisée
    $disks = Get-CimInstance -CimSession $session CIM_LogicalDisk                                                               # Liste de tout les disques
}
else {
    Write-Host "Session is null"
    exit
}

###################################################################################################################
# Corps du script
    
foreach ($disk in $disks) { 
    if ($disk.DriveType -eq "3") {
        $diskOut += $disk.DeviceID + "`t" + (($disk.Size - $disk.FreeSpace) / 1GB).ToString('.00') + " GB / " + ($disk.Size / 1GB).ToString('.00') + " GB" + 
        "`n|  `t`t`t"
    }
}

foreach ($program in $programs) {
    $installedPrograms += $program + "`n" +
    "|  " 
}
    
$logTab = 
"╔══════════════════════════════════════════════════════════════════════════════════╗`n" +
"║                                  SYSINFO LOGGER                                  ║`n" +
"╠══════════════════════════════════════════════════════════════════════════════════╣`n" +
"║ Log date : " + $time + "                                                              ║`n" +
"╚══════════════════════════════════════════════════════════════════════════════════╝`n"
    
$log = 
"`n┌─ OPERATING SYSTEM :" + 
"`n|  " +
"`n│  Hostname: `t" + $hostName +
"`n│  OS:       `t" + $osName +
"`n|  Version:  `t" + $osVersion + " Build " + $osBuild +
"`n|  IPv4:     `t" + $ip +
"`n|" +
"`n├─ HARDWARE :" +
"`n|" +
"`n|  CPU: `t`t" + $cpuName +
"`n|  RAM: `t`t" + $usedRAM.ToString('.00') + " GB / " + $totalRAM.ToString('.00') + " GB" +
"`n|  DISK:  `t" + $diskOut +

"`n├─ INSTALLED PROGRAMS :" + 
"`n|  " + $installedPrograms +
"`n" 
    
$logTab + $log | Write-Output >> ./logs/$date-sysinfologger.log
$log | Write-Host
