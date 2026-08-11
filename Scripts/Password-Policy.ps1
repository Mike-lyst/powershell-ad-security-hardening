

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

Write-Log "Starting password policy audit."

#---------------------------------------------------------
# Get Password Policy
#---------------------------------------------------------

try
{
    $Policy = Get-ADDefaultDomainPasswordPolicy

    Write-Log "Password policy collected successfully."
}
catch
{
    Write-Log "Unable to retrieve password policy." "ERROR"
    return
}

#---------------------------------------------------------
# Create Report Object
#---------------------------------------------------------

$Report = [PSCustomObject]@{

    Domain                      = (Get-ADDomain).DNSRoot

    ComplexityEnabled           = $Policy.ComplexityEnabled

    ReversibleEncryptionEnabled = $Policy.ReversibleEncryptionEnabled

    MinPasswordLength           = $Policy.MinPasswordLength

    PasswordHistoryCount        = $Policy.PasswordHistoryCount

    MaxPasswordAge_Days         = $Policy.MaxPasswordAge.Days

    MinPasswordAge_Days         = $Policy.MinPasswordAge.Days

    LockoutThreshold            = $Policy.LockoutThreshold

    LockoutDuration_Minutes     = $Policy.LockoutDuration.TotalMinutes

    LockoutObservationWindow    = $Policy.LockoutObservationWindow.TotalMinutes

    MaxPasswordAge              = $Policy.MaxPasswordAge

    MinPasswordAge              = $Policy.MinPasswordAge

    AuditDate                   = Get-Date

}

#---------------------------------------------------------
# Export Report
#---------------------------------------------------------

$Report |
Export-Csv `
"$ReportFolder\Password-Policy.csv" `
-NoTypeInformation

#---------------------------------------------------------
# Console Output
#---------------------------------------------------------

Write-Host ""
Write-Host "========================================="
Write-Host " Default Domain Password Policy"
Write-Host "========================================="
Write-Host ""

Write-Host "Domain                     :" (Get-ADDomain).DNSRoot
Write-Host "Complexity Enabled         :" $Policy.ComplexityEnabled
Write-Host "Minimum Password Length    :" $Policy.MinPasswordLength
Write-Host "Password History           :" $Policy.PasswordHistoryCount
Write-Host "Maximum Password Age       :" $Policy.MaxPasswordAge.Days "Days"
Write-Host "Minimum Password Age       :" $Policy.MinPasswordAge.Days "Days"
Write-Host "Lockout Threshold          :" $Policy.LockoutThreshold
Write-Host "Lockout Duration           :" $Policy.LockoutDuration.TotalMinutes "Minutes"
Write-Host "Observation Window         :" $Policy.LockoutObservationWindow.TotalMinutes "Minutes"

Write-Host ""

Write-Host "Report Generated"

Get-ChildItem "$ReportFolder\Password-Policy.csv"

Write-Host ""

Write-Log "Password policy audit completed successfully."