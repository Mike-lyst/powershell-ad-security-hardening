Clear-Host

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

    Add-Content $LogFile $Entry

    Write-Host $Entry
}

Write-Log "Building Active Directory Security Dashboard."

#---------------------------------------------------------
# Count Records
#---------------------------------------------------------

function Get-CSVCount
{
    param([string]$File)

    if(Test-Path $File)
    {
        return (Import-Csv $File).Count
    }

    return 0
}

$DisabledUsers =
Get-CSVCount "$ReportFolder\Disabled-Users.csv"

$InactiveUsers =
Get-CSVCount "$ReportFolder\Inactive-Users.csv"

$LockedAccounts =
Get-CSVCount "$ReportFolder\Locked-Accounts.csv"

$PasswordNeverExpires =
Get-CSVCount "$ReportFolder\Password-Never-Expires.csv"

$ExpiredPasswords =
Get-CSVCount "$ReportFolder\Expired-Passwords.csv"

$NeverLoggedOn =
Get-CSVCount "$ReportFolder\Never-Logged-On.csv"

$PrivilegedAccounts =
Get-CSVCount "$ReportFolder\Privileged-Accounts.csv"

$DomainControllers =
Get-CSVCount "$ReportFolder\Domain-Controllers.csv"

#---------------------------------------------------------
# Build Dashboard
#---------------------------------------------------------

$Dashboard = [PSCustomObject]@{

AuditDate = Get-Date

DisabledUsers = $DisabledUsers

InactiveUsers = $InactiveUsers

LockedAccounts = $LockedAccounts

PasswordNeverExpires = $PasswordNeverExpires

ExpiredPasswords = $ExpiredPasswords

NeverLoggedOn = $NeverLoggedOn

PrivilegedAccounts = $PrivilegedAccounts

DomainControllers = $DomainControllers

}

#---------------------------------------------------------
# Export Dashboard
#---------------------------------------------------------

$Dashboard |

Export-Csv `
"$ReportFolder\Security-Dashboard.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Dashboard
#---------------------------------------------------------

Write-Host ""

Write-Host "==========================================="
Write-Host " ACTIVE DIRECTORY SECURITY DASHBOARD"
Write-Host "==========================================="
Write-Host ""

Write-Host ("Disabled Users          : {0}" -f $DisabledUsers)
Write-Host ("Inactive Users          : {0}" -f $InactiveUsers)
Write-Host ("Locked Accounts         : {0}" -f $LockedAccounts)
Write-Host ("Password Never Expires  : {0}" -f $PasswordNeverExpires)
Write-Host ("Expired Passwords       : {0}" -f $ExpiredPasswords)
Write-Host ("Never Logged On         : {0}" -f $NeverLoggedOn)
Write-Host ("Privileged Accounts     : {0}" -f $PrivilegedAccounts)
Write-Host ("Domain Controllers      : {0}" -f $DomainControllers)

Write-Host ""

Write-Host "Dashboard Report Generated"

Get-ChildItem "$ReportFolder\Security-Dashboard.csv"

Write-Host ""

Write-Log "Security dashboard generated successfully."