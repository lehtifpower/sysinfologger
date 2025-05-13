<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script : SysinfoLogger.ps1
    Auteur : 	Albert Braimi, Latif Krasniqi (chef du groupe)
    Date :	    04.04.2025
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

.PARAMETER Param1
    Description du premier paramètre avec les limites et contraintes
	
.OUTPUTS
	Ce qui est produit par le script, comme des fichiers et des modifications du système
	
.EXAMPLE
	.\CanevasV3.ps1 -Param1 Toto -Param2 Titi -Param3 Tutu
	La ligne que l'on tape pour l'exécution du script avec un choix de paramètres
	Résultat : par exemple un fichier, une modification, un message d'erreur
	
.EXAMPLE
	.\CanevasV3.ps1
	Résultat : Sans paramètre, affichage de l'aide
	
.LINK
    D'autres scripts utilisés dans ce script
#>

<# Le nombre de paramètres doit correspondre à ceux définis dans l'en-tête
   Il est possible aussi qu'il n'y ait pas de paramètres mais des arguments
   Un paramètre peut être typé : [string]$Param1
   Un paramètre peut être initialisé : $Param2="Toto"
   Un paramètre peut être obligatoire : [Parameter(Mandatory=$True][string]$Param3
#>
# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire 
param (
    [Parameter(Mandatory = $True)][string]$RemoteMachine
)

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples
# Commentaires pour les variables

if $RemoteMachine est là 
$session = New-CimSession -ComputerName $RemoteMachine -Credential (Get-Credential) 
else 
$session = New-CimSession -ComputerName $env:COMPUTERNAME


$date = Get-Date -Format "dd/MM/yyyy"                                                                           # Date
$time = Get-Date -Format "HH:mm:ss"                                                                             # Heure de la journée
$osName = (Get-CimInstance -CimSession $session-CimSession $session CIM_OperatingSystem).Caption                # Nom du système d'exploitation
$osVersion = (Get-CimInstance -CimSession $session CIM_OperatingSystem).Version                                 # Version du système d'exploitation
$osBuild = (Get-CimInstance -CimSession $session CIM_OperatingSystem).BuildNumber                               # Version du build de l'OS
$hostName = (Get-CimInstance -CimSession $session CIM_OperatingSystem).CSName                                   # Nom de l'hôte
$programs = (Get-CimInstance -CimSession $session CIM_Product).Name                                             # Liste des programes installés
$ip = Get-NetIPConfiguration | Where-Object{$_.ipv4defaultgateway -ne $null};                                   # Adresse IP de la machine
$cpuName = (Get-CimInstance -CimSession $session CIM_Processor).name                                            # Nom du CPU
$totalRAM = ((Get-CimInstance -CimSession $session CIM_OperatingSystem).TotalVisibleMemorySize / 1MB)           # Quantité totale de RAM
$usedRAM = ($totalRAM - (Get-CimInstance -CimSession $session CIM_OperatingSystem).FreePhysicalMemory / 1MB)    # Quantitée de RAM utiliée
$disks = Get-CimInstance -CimSession $session CIM_LogicalDisk                                                   # Liste de tout les disques

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs

# Affiche l'aide si un ou plusieurs paramètres ne sont par renseignés, "safe guard clauses" permet d'optimiser l'exécution et la lecture des scripts

Write-Host $session
Write-Host $date
Write-Host $time
Write-Host $osName
Write-Host $osVersion
Write-Host $osBuild 
Write-Host $hostName
Write-Host $programs
Write-Host $ip
Write-Host $cpuName 
Write-Host $totalRAM
Write-Host $usedRAM
Write-Host $disks




if(!$RemoteMachine)
{
    Get-Help $MyInvocation.Mycommand.Path
	exit
}

###################################################################################################################
# Corps du script

# Ce que fait le script, ici, afficher un message
    










$scriptBlock = {

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
    
}

    
    
Invoke-Command -Session $session -ScriptBlock $scriptBlock 
Remove-PSSession -Session $session
   
