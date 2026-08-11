
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
    Write-Host "Failed to import Active Directory Module." -ForegroundColor Red
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
# Create Folders
#---------------------------------------------------------

foreach($Folder in @($ReportFolder,$LogFolder))
{
    if(!(Test-Path $Folder))
    {
        New-Item `
            -ItemType Directory `
            -Path $Folder | Out-Null
    }
}

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

    Add-Content `
        -Path $LogFile `
        -Value $Entry

    Write-Host $Entry
}

Write-Log "Starting Active Directory Security Audit."

#---------------------------------------------------------
# Disabled Users
#---------------------------------------------------------

Write-Log "Collecting disabled accounts..."

$DisabledUsers = Get-ADUser `
    -Filter "Enabled -eq 'False'" `
    -Properties Enabled

$DisabledUsers |
Select-Object `
Name,
SamAccountName,
Enabled |
Export-Csv `
"$ReportFolder\Disabled-Users.csv" `
-NoTypeInformation

Write-Log "$($DisabledUsers.Count) disabled account(s) exported."

#---------------------------------------------------------
# Inactive Users
#---------------------------------------------------------

Write-Log "Collecting inactive accounts..."

$InactiveUsers = Get-ADUser `
    -Filter * `
    -Properties LastLogonDate |
Where-Object {
    $_.LastLogonDate -lt (Get-Date).AddDays(-90)
}

$InactiveUsers |
Select-Object `
Name,
SamAccountName,
LastLogonDate |
Export-Csv `
"$ReportFolder\Inactive-Users.csv" `
-NoTypeInformation

Write-Log "$($InactiveUsers.Count) inactive account(s) exported."

#---------------------------------------------------------
# Locked Accounts
#---------------------------------------------------------

Write-Log "Collecting locked accounts..."

$LockedUsers = Search-ADAccount `
    -LockedOut

$LockedUsers |
Select-Object `
Name,
SamAccountName,
LockedOut |
Export-Csv `
"$ReportFolder\Locked-Accounts.csv" `
-NoTypeInformation

Write-Log "$($LockedUsers.Count) locked account(s) exported."

#---------------------------------------------------------
# Password Never Expires
#---------------------------------------------------------

Write-Log "Collecting accounts with password never expires..."

$PasswordNeverExpires = Get-ADUser `
    -Filter * `
    -Properties PasswordNeverExpires |
Where-Object {
    $_.PasswordNeverExpires -eq $true
}

$PasswordNeverExpires |
Select-Object `
Name,
SamAccountName,
PasswordNeverExpires |
Export-Csv `
"$ReportFolder\Password-Never-Expires.csv" `
-NoTypeInformation

Write-Log "$($PasswordNeverExpires.Count) account(s) found."

#---------------------------------------------------------
# Password Expired
#---------------------------------------------------------

Write-Log "Collecting expired passwords..."

$ExpiredPasswords = Search-ADAccount `
    -PasswordExpired

$ExpiredPasswords |
Select-Object `
Name,
SamAccountName |
Export-Csv `
"$ReportFolder\Expired-Passwords.csv" `
-NoTypeInformation

Write-Log "$($ExpiredPasswords.Count) expired password account(s)."

#---------------------------------------------------------
# Accounts Without Recent Logon
#---------------------------------------------------------

Write-Log "Collecting accounts that never logged on..."

$NeverLoggedOn = Get-ADUser `
    -Filter * `
    -Properties LastLogonDate |
Where-Object {
    !$_.LastLogonDate
}

$NeverLoggedOn |
Select-Object `
Name,
SamAccountName |
Export-Csv `
"$ReportFolder\Never-Logged-On.csv" `
-NoTypeInformation

Write-Log "$($NeverLoggedOn.Count) account(s) never logged on."

#---------------------------------------------------------
# Summary Report
#---------------------------------------------------------

$Summary = [PSCustomObject]@{

AuditDate = Get-Date

DisabledUsers = $DisabledUsers.Count

InactiveUsers = $InactiveUsers.Count

LockedAccounts = $LockedUsers.Count

PasswordNeverExpires = $PasswordNeverExpires.Count

ExpiredPasswords = $ExpiredPasswords.Count

NeverLoggedOn = $NeverLoggedOn.Count

}

$Summary |
Export-Csv `
"$ReportFolder\Security-Audit-Summary.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Summary
#---------------------------------------------------------

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Active Directory Security Audit Complete" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Disabled Users          : $($DisabledUsers.Count)"
Write-Host "Inactive Users          : $($InactiveUsers.Count)"
Write-Host "Locked Accounts         : $($LockedUsers.Count)"
Write-Host "Password Never Expires  : $($PasswordNeverExpires.Count)"
Write-Host "Expired Passwords       : $($ExpiredPasswords.Count)"
Write-Host "Never Logged On         : $($NeverLoggedOn.Count)"

Write-Host ""

Write-Host "Reports generated in:"

Get-ChildItem $ReportFolder

Write-Host ""

Write-Log "Security audit completed successfully."