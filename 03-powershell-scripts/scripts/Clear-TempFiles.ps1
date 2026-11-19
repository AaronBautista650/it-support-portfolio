# Clear-TempFiles.ps1
# Deletes files from the current user's temp folder that are older than a set number of days.
# Use it to free space on a computer that's running low on disk.
# Files in use are skipped automatically.
#
# Usage:
#   .\Clear-TempFiles.ps1 -WhatIf            # preview what would be deleted
#   .\Clear-TempFiles.ps1                    # delete files older than 7 days
#   .\Clear-TempFiles.ps1 -OlderThanDays 30

[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$OlderThanDays = 7
)

$tempFolder = $env:TEMP
$cutoff = (Get-Date).AddDays(-$OlderThanDays)

$files = Get-ChildItem -Path $tempFolder -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff }

$totalKB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1KB, 1)
Write-Host "Found $($files.Count) file(s) older than $OlderThanDays days, about $totalKB KB."

$deleted = 0
foreach ($file in $files) {
    if ($PSCmdlet.ShouldProcess($file.FullName, "Delete")) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            $deleted++
        }
        catch {
            Write-Verbose "Skipped $($file.FullName): $($_.Exception.Message)"
        }
    }
}

Write-Host "Deleted $deleted file(s)."
