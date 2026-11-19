# Get-SystemInfo.ps1
# Shows basic system details for a computer: name, OS, memory, disk, and uptime.
# Use it at the start of a ticket to collect facts before troubleshooting.
#
# Usage:
#   .\Get-SystemInfo.ps1
#   .\Get-SystemInfo.ps1 -ExportCsv "C:\Reports\sysinfo.csv"

[CmdletBinding()]
param(
    [string]$ExportCsv
)

$os   = Get-CimInstance -ClassName Win32_OperatingSystem
$cs   = Get-CimInstance -ClassName Win32_ComputerSystem
$cpu  = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"

$uptime = (Get-Date) - $os.LastBootUpTime

$info = [PSCustomObject]@{
    ComputerName   = $env:COMPUTERNAME
    Domain         = $cs.Domain
    OSName         = $os.Caption
    OSBuild        = $os.BuildNumber
    CPU            = $cpu.Name.Trim()
    RAM_GB         = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    CDrive_FreeGB  = [math]::Round($disk.FreeSpace / 1GB, 2)
    CDrive_TotalGB = [math]::Round($disk.Size / 1GB, 2)
    UptimeDays     = [math]::Round($uptime.TotalDays, 2)
    LastBoot       = $os.LastBootUpTime
}

$info | Format-List

if ($ExportCsv) {
    $info | Export-Csv -Path $ExportCsv -NoTypeInformation
    Write-Host "Saved to $ExportCsv"
}