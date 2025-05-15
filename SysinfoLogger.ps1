<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script : SysinfoLogger.ps1
    Auteur : 	Albert Braimi, Latif Krasniqi
    Date :	    13.05.2025
 	*****************************************************************************
    Modifications
 	Date  : -
 	Auteur: -
 	Raisons: -
 	*****************************************************************************
.SYNOPSIS
	Script Permettant de recuperer des informations sur une machine local ou distante
 	
.DESCRIPTION
    En lançant le script il faut mettre l'adresse de la machine locale ou de la machine distante.
    Ensuite on crée un scriptblock qui va contenir tout le script qui sera lancé dans les machines.¨
    dans le script on crée 12 variables contenant toute les informations sans modification.
    Pour tout les disque on va chercher si il y en a un qui est le disque C: et pour ce disque on
    va chercher la taille utilisée en soustrayant la taille du disque par l'espace libre sur le disque.
    pour chaque programmes installé on va les mettres dans une variables avec un retour à la ligne et
    un trait pour respecter le format des logs.

.PARAMETER RemoteMachine
    choix de l'utilisateur si il choisit de recuperer les informations de la machine local ou distante.
	
.OUTPUTS
	Création d'un nouveau de fichier de log chaque jour contenant l'heure du log et les informations de la machine.
	
.EXAMPLE
	.\Sysinfologger.ps1 IP (local ou distante)
	
    Nom de l'hote : ... (ceci ne s'affichera pas si c'est sur la machine local)
    Credential : ... (ceci ne s'affichera pas si c'est sur la machine local)

┌─ OPERATING SYSTEM :
│
│  Hostname:     PC2
│  OS:           Microsoft Version d’évaluation de Windows 11 Entreprise
│  Version:      10.0.22000 Build 22000
│  IPv4:

┌─ HARDWARE :
│
│  CPU:          11th Gen Intel(R) Core(TM) i7-11700 @ 2.50GHz
│  RAM:           GB /  GB
│  DISK          23,71 GB / 63,28 GB

┌─ INSTALLED PROGRAMS :
│
│  VirtualBox
│  PowerShell 7-x64
│  CIM Explorer
│  Microsoft Update Health Tools
	
.EXAMPLE
	.\Sysinfologger.ps1

    (comme aucune adresse IP n'est renseignée,
     le script va s'exécuter sur la machine locale)

┌─ OPERATING SYSTEM :
│
│  Hostname:     PC2
│  OS:           Microsoft Version d’évaluation de Windows 11 Entreprise
│  Version:      10.0.22000 Build 22000
│  IPv4:

┌─ HARDWARE :
│
│  CPU:          11th Gen Intel(R) Core(TM) i7-11700 @ 2.50GHz
│  RAM:           GB /  GB
│  DISK          23,71 GB / 63,28 GB

┌─ INSTALLED PROGRAMS :
│
│  VirtualBox
│  PowerShell 7-x64
│  CIM Explorer
│  Microsoft Update Health Tools

#>

<# Le nombre de paramètres doit correspondre à ceux définis dans l'en-tête
   Il est possible aussi qu'il n'y ait pas de paramètres mais des arguments
   Un paramètre peut être typé : [string]$Param1
   Un paramètre peut être initialisé : $Param2="Toto"
   Un paramètre peut être obligatoire : [Parameter(Mandatory=$True][string]$Param3
#>
# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire 
param (
    [Parameter(Mandatory = $false)][string]$RemoteMachine
)

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples
# Commentaires pour les variables

if (!([string]::IsNullOrEmpty($RemoteMachine))) {
    $session = New-CimSession -ComputerName $RemoteMachine -Credential (Get-Credential) 
}

else {
    $session = New-CimSession $env:COMPUTERNAME
}


$date = Get-Date -Format "dd/MM/yyyy"                                                                           # Date
$time = Get-Date -Format "HH:mm:ss"                                                                             # Heure de la journée
$osName = (Get-CimInstance -CimSession $session CIM_OperatingSystem).Caption                # Nom du système d'exploitation
$osVersion = (Get-CimInstance -CimSession $session CIM_OperatingSystem).Version                                 # Version du système d'exploitation
$osBuild = (Get-CimInstance -CimSession $session CIM_OperatingSystem).BuildNumber                               # Version du build de l'OS
$hostName = (Get-CimInstance -CimSession $session CIM_OperatingSystem).CSName                                   # Nom de l'hôte
$programs = (Get-CimInstance -CimSession $session CIM_Product).Name                                             # Liste des programes installés
$ip = (Get-NetIPConfiguration).IPv4Address                                                  # Adresse IP de la machine
$cpuName = (Get-CimInstance -CimSession $session CIM_Processor).name                                            # Nom du CPU
$totalRAM = ((Get-CimInstance -CimSession $session CIM_OperatingSystem).TotalVisibleMemorySize / 1MB)           # Quantité totale de RAM
$usedRAM = ($totalRAM - (Get-CimInstance -CimSession $session CIM_OperatingSystem).FreePhysicalMemory / 1MB)    # Quantitée de RAM utilisée
$disks = Get-CimInstance -CimSession $session CIM_LogicalDisk                                                   # Liste de tout les disques

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs




###################################################################################################################
# Corps du script
    

foreach ($disk in $disks) { 
    if ($disk.DeviceID -eq "C:") {
        $usedDiskSpace = $disk.Size - $disk.FreeSpace
        $diskSize = $disk.Size
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
"`n│  Hostname:     " + $hostName +
"`n│  OS:           " + $osName +
"`n|  Version:      " + $osVersion + " Build " + $osBuild +
"`n|  IPv4:         " + $ip.IPv4Address.ipaddress +
"`n" +
"`n┌─ HARDWARE :" +
"`n|  " +
"`n|  CPU:          " + $cpuName +
"`n|  RAM:          " + $usedRAM.('.00') + " GB / " + $totalRAM.('.00') + " GB" +
"`n|  DISK          " + ($usedDiskSpace / 1GB).ToString('.00') + " GB / " + ($diskSize / 1GB).ToString('.00') + " GB" +
"`n" +
"`n┌─ INSTALLED PROGRAMS :" + 
"`n|  " +
"`n|  " + $installedPrograms +
"`n" 
    

New-Item -ItemType Directory -Force -Path ./logs

$logTab + $log | Out-File -encoding utf8 -FilePath ./logs/$date-sysinfologger.log -Append
$log | Write-Host
    

    
    
   
