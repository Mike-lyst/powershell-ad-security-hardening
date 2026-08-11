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

Write-Log "Starting DNS Health Check."

#---------------------------------------------------------
# Domain Controllers
#---------------------------------------------------------

$DCs = Get-ADDomainController -Filter *

$Results = @()

#---------------------------------------------------------
# DNS Checks
#---------------------------------------------------------

foreach($DC in $DCs)
{
    Write-Log "Checking DNS on $($DC.HostName)"

    # Ping

    $Ping = Test-Connection `
        -ComputerName $DC.HostName `
        -Count 2 `
        -Quiet

    # DNS Service

    $DNSService = Get-Service `
        -ComputerName $DC.HostName `
        -Name DNS `
        -ErrorAction SilentlyContinue

    # Resolve DNS

    try
    {
        $Resolved = Resolve-DnsName `
            $DC.HostName `
            -ErrorAction Stop

        $DNSResolution = "Success"
    }
    catch
    {
        $DNSResolution = "Failed"
    }

    # DNS Diagnostic

    $DNSDiag = dcdiag /test:dns /s:$($DC.HostName)

    $Results += [PSCustomObject]@{

        DomainController = $DC.HostName

        IPv4Address = $DC.IPv4Address

        Reachable = $Ping

        DNSService = $DNSService.Status

        DNSResolution = $DNSResolution

    }

    $DNSDiag |

    Out-File `
    "$ReportFolder\$($DC.HostName)-DNSDiag.txt"

}

#---------------------------------------------------------
# Export Report
#---------------------------------------------------------

$Results |

Export-Csv `
"$ReportFolder\DNS-Health.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Summary
#---------------------------------------------------------

$Summary = [PSCustomObject]@{

AuditDate = Get-Date

ServersChecked = $Results.Count

Reachable = ($Results | Where Reachable).Count

DNSRunning = ($Results | Where {$_.DNSService -eq "Running"}).Count

DNSResolutionPassed = ($Results | Where {$_.DNSResolution -eq "Success"}).Count

}

$Summary |

Export-Csv `
"$ReportFolder\DNS-Health-Summary.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Output
#---------------------------------------------------------

Write-Host ""

Write-Host "===================================="

Write-Host " DNS HEALTH CHECK COMPLETE"

Write-Host "===================================="

Write-Host ""

$Results |

Format-Table

Write-Host ""

Write-Host "Reports Generated"

Get-ChildItem "$ReportFolder\DNS*"

Write-Host ""

Write-Log "DNS Health Check Completed."