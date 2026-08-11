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
    Write-Host ""
    Write-Host "Active Directory module could not be loaded." -ForegroundColor Red
    Write-Host "Install RSAT or run on a Domain Controller."
    Write-Host ""
    return
}

#---------------------------------------------------------
# Project Paths
#---------------------------------------------------------

$ProjectRoot = Split-Path $PSScriptRoot -Parent

$ScriptsFolder = Join-Path $ProjectRoot "Scripts"
$ReportsFolder = Join-Path $ProjectRoot "Reports"
$LogsFolder    = Join-Path $ProjectRoot "Logs"

$LogFile = Join-Path $LogsFolder "Security-Audit.log"

#---------------------------------------------------------
# Create Required Folders
#---------------------------------------------------------

foreach($Folder in @($ReportsFolder,$LogsFolder))
{
    if(!(Test-Path $Folder))
    {
        New-Item `
            -ItemType Directory `
            -Path $Folder | Out-Null
    }
}

#---------------------------------------------------------
# Create Log File
#---------------------------------------------------------

if(!(Test-Path $LogFile))
{
    New-Item `
        -ItemType File `
        -Path $LogFile | Out-Null
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

#---------------------------------------------------------
# Banner
#---------------------------------------------------------

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Active Directory Security Hardening" -ForegroundColor Green
Write-Host " Enterprise Health Monitoring Suite" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Security Hardening Project Started."

#---------------------------------------------------------
# Scripts To Execute
#---------------------------------------------------------

$Scripts = @(

    "Security-Audit.ps1",

    "Privileged-Accounts.ps1",

    "Password-Policy.ps1",

    "DC-Health.ps1",

    "DNS-Health.ps1",

    "Replication-Health.ps1",

    "Security-Dashboard.ps1"

)

#---------------------------------------------------------
# Counters
#---------------------------------------------------------

$Executed = 0
$Failed   = 0

#---------------------------------------------------------
# Execute Scripts
#---------------------------------------------------------

foreach($Script in $Scripts)
{
    $ScriptPath = Join-Path $ScriptsFolder $Script

    Write-Host ""
    Write-Host "----------------------------------------------"
    Write-Host "Running $Script"
    Write-Host "----------------------------------------------"

    if(Test-Path $ScriptPath)
    {
        try
        {
            & $ScriptPath

            Write-Log "$Script completed successfully."

            $Executed++
        }

        catch
        {
            Write-Log "$Script failed." "ERROR"

            Write-Log $_.Exception.Message "ERROR"

            $Failed++
        }
    }

    else
    {
        Write-Log "$Script not found." "WARNING"

        $Failed++
    }
}

#---------------------------------------------------------
# Final Summary
#---------------------------------------------------------

Write-Host ""
Write-Host "======================================================"
Write-Host " EXECUTION SUMMARY"
Write-Host "======================================================"
Write-Host ""

Write-Host "Scripts Executed Successfully : $Executed"

Write-Host "Scripts Failed                : $Failed"

Write-Host ""

Write-Host "Reports Folder"

Get-ChildItem $ReportsFolder

Write-Host ""

Write-Host "Log File"

Write-Host $LogFile

Write-Host ""

Write-Log "Master execution completed."

Write-Host ""
Write-Host "======================================================"
Write-Host " Active Directory Security Audit Complete"
Write-Host "======================================================"