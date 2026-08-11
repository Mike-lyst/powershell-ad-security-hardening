#=========================================================
# Active Directory Privileged Accounts Audit
# Author : Michael Okwuora
# Project: AD Security Hardening & Health Monitoring
#=========================================================

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
        [string]$Level = "INFO"
    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $Entry = "$Time [$Level] $Message"

    Add-Content -Path $LogFile -Value $Entry

    Write-Host $Entry
}

Write-Log "Starting privileged account audit."

#---------------------------------------------------------
# Groups To Audit
#---------------------------------------------------------

$Groups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Account Operators",
    "Server Operators",
    "Backup Operators",
    "Print Operators"
)

$Results = @()

#---------------------------------------------------------
# Process Groups
#---------------------------------------------------------

foreach($Group in $Groups)
{
    Write-Log "Checking group: $Group"

    try
    {
        $Members = Get-ADGroupMember `
            -Identity $Group `
            -Recursive

        if($Members)
        {
            foreach($Member in $Members)
            {
                $Results += [PSCustomObject]@{

                    Group           = $Group
                    Name            = $Member.Name
                    SamAccountName  = $Member.SamAccountName
                    ObjectClass     = $Member.ObjectClass
                }
            }

            Write-Log "$($Members.Count) member(s) found in $Group."
        }
        else
        {
            Write-Log "No members found in $Group." "WARNING"
        }
    }
    catch
    {
        Write-Log "Unable to read group: $Group" "ERROR"
    }
}

#---------------------------------------------------------
# Export Report
#---------------------------------------------------------

$Results |
Sort-Object Group,Name |
Export-Csv `
"$ReportFolder\Privileged-Accounts.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Summary
#---------------------------------------------------------

$Summary = [PSCustomObject]@{

AuditDate       = Get-Date

GroupsAudited   = $Groups.Count

AccountsFound   = $Results.Count

}

$Summary |
Export-Csv `
"$ReportFolder\Privileged-Accounts-Summary.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Output
#---------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Privileged Account Audit Complete"
Write-Host "========================================"
Write-Host ""

Write-Host "Groups Audited : $($Groups.Count)"
Write-Host "Accounts Found : $($Results.Count)"

Write-Host ""

Write-Host "Reports Generated"

Get-ChildItem "$ReportFolder\Privileged*"

Write-Host ""

Write-Log "Privileged account audit completed successfully."