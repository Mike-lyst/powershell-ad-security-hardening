Clear-Host

#---------------------------------------------------------
# Import Active Directory Module
#---------------------------------------------------------

try
{
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch
{
    Write-Host "Unable to load Active Directory module." -ForegroundColor Red
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
# Logging
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

Write-Log "Starting Active Directory Replication Health Check."

#---------------------------------------------------------
# Collect Replication Data
#---------------------------------------------------------

Write-Log "Running repadmin /replsummary..."

$ReplicationSummary = repadmin /replsummary

$ReplicationSummary |

Out-File `
"$ReportFolder\Replication-Summary.txt"

Write-Log "Replication summary saved."

#---------------------------------------------------------
# Show Replication Partners
#---------------------------------------------------------

Write-Log "Collecting replication partners..."

$ReplicationPartners = repadmin /showrepl

$ReplicationPartners |

Out-File `
"$ReportFolder\Replication-Partners.txt"

Write-Log "Replication partner information saved."

#---------------------------------------------------------
# Domain Controller Information
#---------------------------------------------------------

$DCs = Get-ADDomainController -Filter *

$Results = foreach($DC in $DCs)
{

    [PSCustomObject]@{

        DomainController = $DC.HostName

        Site             = $DC.Site

        IPv4Address      = $DC.IPv4Address

        GlobalCatalog    = $DC.IsGlobalCatalog

        ReadOnly         = $DC.IsReadOnly

        OperatingSystem  = $DC.OperatingSystem

    }

}

$Results |

Export-Csv `
"$ReportFolder\Domain-Controllers.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Generate Summary
#---------------------------------------------------------

$Summary = [PSCustomObject]@{

AuditDate = Get-Date

DomainControllers = $Results.Count

GlobalCatalogs = ($Results | Where {$_.GlobalCatalog}).Count

ReadOnlyDCs = ($Results | Where {$_.ReadOnly}).Count

}

$Summary |

Export-Csv `
"$ReportFolder\Replication-Health-Summary.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Display Results
#---------------------------------------------------------

Write-Host ""

Write-Host "======================================"

Write-Host " REPLICATION HEALTH COMPLETE"

Write-Host "======================================"

Write-Host ""

$Results |

Format-Table

Write-Host ""

Write-Host "Reports Generated"

Get-ChildItem "$ReportFolder\Replication*"

Write-Host ""

Write-Log "Replication Health Check Completed."