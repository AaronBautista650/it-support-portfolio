# Find-InactiveUsers.ps1
# Lists enabled AD user accounts that have not signed in for a set number of days.
# Use it for account cleanup and to find accounts that should be disabled.
# Run on DC01 as a domain admin.
#
# Usage:
#   .\Find-InactiveUsers.ps1                     # default: 90 days
#   .\Find-InactiveUsers.ps1 -Days 30
#   .\Find-InactiveUsers.ps1 -Days 60 -ExportCsv "C:\Reports\inactive.csv"

[CmdletBinding()]
param(
    [int]$Days = 90,
    [string]$ExportCsv
)

Import-Module ActiveDirectory

$cutoff = (Get-Date).AddDays(-$Days)

$inactive = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, Department |
    Where-Object { $_.LastLogonDate -lt $cutoff -or $_.LastLogonDate -eq $null } |
    Select-Object SamAccountName, Name, Department, LastLogonDate |
    Sort-Object LastLogonDate

if (-not $inactive) {
    Write-Host "No enabled accounts have been inactive for $Days days."
    return
}

$inactive | Format-Table -AutoSize
Write-Host "$($inactive.Count) account(s) inactive for more than $Days days."

if ($ExportCsv) {
    $inactive | Export-Csv -Path $ExportCsv -NoTypeInformation
    Write-Host "Saved to $ExportCsv"
}
