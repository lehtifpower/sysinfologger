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
	Script permettant de récupérer des informations sur une machine locale ou distante
 	
.DESCRIPTION
    Ce script PowerShell collecte des informations système d’un ordinateur local ou distant (via le paramètre -RemoteMachine) : 
    système d’exploitation, adresse IPv4, processeur, mémoire, disques et programmes installés. 
    Il utilise une session CIM pour récupérer les données, les formate et les enregistre dans un fichier log structuré,
    créé dans le dossier ./logs. Un nouveau fichier est généré à chaque exécution avec la date et l’heure,
    ce qui permet de suivre l’évolution des informations chaque jour.

.PARAMETER RemoteMachine
    Choix de l'utilisateur si il choisit de récupérer les informations de la machine locale ou distante.
	
.OUTPUTS
	Création d'un nouveau de fichier de log chaque jour contenant l'heure du log et les informations de la machine.
	
.EXAMPLE
	.\Sysinfologger.ps1 -RemoteMachine <Adresse ip (distante ou local)>
	
    Nom d'utilisateur : ...
    Mot de passe : ...

    ╭─ OPERATING SYSTEM :
    │  
    │  Hostname: 	PC2
    │  OS:       	Microsoft Version d’évaluation de Windows 11 Entreprise
    │  Version:  	10.0.22000 Build 22000
    │  IPv4:     	172.20.0.2
    │
    ├─ HARDWARE :
    │
    │  CPU: 		12th Gen Intel(R) Core(TM) i7-12700F
    │  RAM: 		2,08 GB / 3,99 GB
    │  DISK:  	C:	23,71 GB / 63,28 GB
    │  			S:	,05 GB / 15,00 GB
    │  			T:	,06 GB / 24,98 GB
    │  			
    ├─ INSTALLED PROGRAMS :
    │  VirtualBox
    │  PowerShell 7-x64
    │  CIM Explorer
    ╰─ Microsoft Update Health Tools 
	
.EXAMPLE
    .\Sysinfologger.ps1

    Comme aucune adresse IP n'est renseignée, le script va s'exécuter sur la machine locale

    ╭─ OPERATING SYSTEM :
    │  
    │  Hostname: 	DESKTOP-DSVUCAI
    │  OS:       	Microsoft Windows 10 Pro
    │  Version:  	10.0.19045 Build 19045
    │  IPv4:     	192.168.1.22
    │
    ├─ HARDWARE :
    │
    │  CPU: 		AMD Ryzen 7 9800X3D 8-Core Processor           
    │  RAM: 		13.44 GB / 31.15 GB
    │  DISK:  	C:	1218.79 GB / 1862.38 GB
    │  			D:	140.12 GB / 175.71 GB
    │  			E:	4274.43 GB / 14901.98 GB
    │  			I:	187.28 GB / 465.76 GB
    │  			
    ├─ INSTALLED PROGRAMS :
    │  Blender
    │  AMD DVR64
    │  Eclipse Temurin JDK with Hotspot 22.0.2+9 (x64)
    │  RyzenMasterSDK
    │  PowerShell 7-x64
    │  Eclipse Temurin JDK with Hotspot 21.0.6+7 (x64)
    │  AMD Ryzen Master
    │  AMD WVR64
    ╰─ logisim-evolution

#>

# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire 

param (
    [Parameter(Mandatory = $false)][string]$RemoteMachine   # Ip de la machine distante
)

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Vous devez exécuter ce script en tant qu'administrateur"
    Exit
}

if ($RemoteMachine) {
    if (Test-Connection -ComputerName $RemoteMachine -Count 1 -Quiet) {
        Write-Host "$RemoteMachine est atteignable" -ForegroundColor Green
        try {
            $session = New-CimSession -ComputerName $RemoteMachine -Credential (Get-Credential) -ErrorAction Stop          
        }
        catch {
            Write-Host "|  Nom d'utilisateur ou mot de passe incorrect" -ForegroundColor Red
            Write-Host "|  Le service WinRM n'est peut être pas configuré." -ForegroundColor Red
            Write-Host "|  Exécutez la commande suivante sur la destination pour analyser et configurer le service WinRM : « winrm quickconfig »." -ForegroundColor Red
            exit
        }
    } 
    else {
        Write-Host "$RemoteMachine est inatteignable" -ForegroundColor Red
        exit
    }
}
else {
    $session = New-CimSession -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue
}

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples

if ($session) {
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
    $testPath = Test-Path -Path "./logs"                                                                                        # Teste si le fichier log existe
}
else {
    Write-Host "|  Le service WinRM n'est pas configuré." -ForegroundColor red
    Write-Host "|  Exécutez la commande suivante sur la destination pour analyser et configurer le service WinRM : « winrm quickconfig »." -ForegroundColor red
    exit
}

###################################################################################################################
# Corps du script
    
foreach ($disk in $disks) { 
    if ($disk.DriveType -eq "3") {
        $diskOut += $disk.DeviceID + "`t" + (($disk.Size - $disk.FreeSpace) / 1GB).ToString('.00') + " GB / " + ($disk.Size / 1GB).ToString('.00') + " GB" + 
        "`n│  `t`t`t"
    }
}

for ($i = 0; $i -lt $programs.Count; $i++) {
    if ($i -eq ($programs.count - 1)) {
        $installedPrograms += "`n" + "╰─ " + $programs[$i] 
    }
    else {
        $installedPrograms += "`n" + "│  " + $programs[$i] 
    }
}
    
$logTab = 
"╭──────────────────────────────────────────────────────────────────────────────────╮`n" +
"│                                  SYSINFO LOGGER                                  │`n" +
"├──────────────────────────────────────────────────────────────────────────────────┤`n" +
"│ Log date : " + $time + "                                                              │`n" +
"╰──────────────────────────────────────────────────────────────────────────────────╯`n"
    
$log = 
"`n╭─ OPERATING SYSTEM :" + 
"`n│  " +
"`n│  Hostname: `t" + $hostName +
"`n│  OS:       `t" + $osName +
"`n│  Version:  `t" + $osVersion + " Build " + $osBuild +
"`n│  IPv4:     `t" + $ip +
"`n│" +
"`n├─ HARDWARE :" +
"`n│" +
"`n│  CPU: `t`t" + $cpuName +
"`n│  RAM: `t`t" + $usedRAM.ToString('.00') + " GB / " + $totalRAM.ToString('.00') + " GB" +
"`n│  DISK:  `t" + $diskOut +

"`n├─ INSTALLED PROGRAMS :" + 

"`n│  " + $installedPrograms +
"`n" 

if ($testPath -eq $false) {
    New-Item -Path . -Name "logs" -ItemType "Directory" | Out-Null
    Write-Host "`n|  Dossier des logs crée dans : $pwd\logs" -ForegroundColor Green
} 

$logTab + $log | Write-Output >> ./logs/$date-sysinfologger.log
$log | Write-Host
