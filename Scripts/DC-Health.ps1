

Clear-Host

#---------------------------------------------------------
# Import Module
#---------------------------------------------------------

try
{
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch
{
    Write-Host "Failed to import Active Directory module." -ForegroundColor Red
    return
}

#---------------------------------------------------------
# Project Paths
#---------------------------------------------------------

$ProjectRoot = Split-Path $PSScriptRoot -Parent

$ReportFolder = Join-Path $ProjectRoot "Reports"

$LogFolder = Join-Path $ProjectRoot "Logs"

$LogFile = Join-Path $LogFolder "Security-Audit.log"

#---------------------------------------------------------
# Logging Function
#---------------------------------------------------------

function Write-Log
{
    param(
        [string]$Message,
        [string]$Level="INFO"
    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $Entry = "$Time [$Level] $Message"

    Add-Content $LogFile $Entry

    Write-Host $Entry
}

Write-Log "Starting Domain Controller Health Check."

#---------------------------------------------------------
# Get Domain Controllers
#---------------------------------------------------------

$DomainControllers = Get-ADDomainController -Filter *

$Results = @()

#---------------------------------------------------------
# Health Check
#---------------------------------------------------------

foreach($DC in $DomainControllers)
{

    Write-Log "Checking $($DC.HostName)"

    # Ping

    $Ping = Test-Connection `
        -ComputerName $DC.HostName `
        -Count 2 `
        -Quiet

    # Uptime

    $OS = Get-CimInstance `
        Win32_OperatingSystem `
        -ComputerName $DC.HostName

    $BootTime = $OS.LastBootUpTime

    $Uptime = (Get-Date) - $BootTime

    # Disk

    $Disk = Get-CimInstance `
        Win32_LogicalDisk `
        -ComputerName $DC.HostName `
        -Filter "DeviceID='C:'"

    # Memory

    $Memory = Get-CimInstance `
        Win32_OperatingSystem `
        -ComputerName $DC.HostName

    $FreeMemory = [math]::Round($Memory.FreePhysicalMemory/1024,2)

    $Results += [PSCustomObject]@{

        DomainController = $DC.HostName

        Site = $DC.Site

        IPv4Address = $DC.IPv4Address

        Reachable = $Ping

        OperatingSystem = $DC.OperatingSystem

        UptimeDays = [math]::Round($Uptime.TotalDays,1)

        FreeMemoryMB = $FreeMemory

        DriveC_FreeGB = [math]::Round($Disk.FreeSpace/1GB,2)

        DriveC_SizeGB = [math]::Round($Disk.Size/1GB,2)

    }

}

#---------------------------------------------------------
# Export Report
#---------------------------------------------------------

$Results |

Export-Csv `
"$ReportFolder\DC-Health.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Summary
#---------------------------------------------------------

$Summary = [PSCustomObject]@{

AuditDate = Get-Date

DomainControllers = $Results.Count

Reachable = ($Results | Where Reachable).Count

Unreachable = ($Results | Where {!$_.Reachable}).Count

}

$Summary |

Export-Csv `
"$ReportFolder\DC-Health-Summary.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Output
#---------------------------------------------------------

Write-Host ""

Write-Host "==========================================="

Write-Host " DOMAIN CONTROLLER HEALTH"

Write-Host "==========================================="

Write-Host ""

$Results |

Format-Table

Write-Host ""

Write-Host "Reports Generated"

Get-ChildItem "$ReportFolder\DC*"

Write-Host ""

Write-Log "Domain Controller Health Check Completed."