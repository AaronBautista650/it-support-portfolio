# New-BulkUsers.ps1
# Creates Active Directory user accounts from a CSV file.
# Run on DC01 as a domain admin. Requires the ActiveDirectory module (installed with AD DS).
#
# CSV columns: FirstName,LastName,SamAccountName,Group,OU
#   Group must be the exact AD group name, such as Sales-Users or HR-Users.
#   Example row: Test,User,tuser1,Sales-Users,"OU=Sales,DC=lab,DC=local"
#
# The password is entered once at the prompt and is never written to a file.
# Each new user must change it at the first sign-in.
#
# Usage:
#   .\New-BulkUsers.ps1 -CsvPath "C:\Scripts\new-users.csv" -WhatIf   # preview only
#   .\New-BulkUsers.ps1 -CsvPath "C:\Scripts\new-users.csv"           # create accounts

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

Import-Module ActiveDirectory

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    return
}

$defaultPassword = Read-Host -Prompt "Temporary password for new users" -AsSecureString
$users = Import-Csv -Path $CsvPath

foreach ($u in $users) {
    $name = "$($u.FirstName) $($u.LastName)"

    if (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue) {
        Write-Warning "Skipped $($u.SamAccountName): account already exists."
        continue
    }

    if ($PSCmdlet.ShouldProcess($u.SamAccountName, "Create user in $($u.OU) and add to $($u.Group)")) {
        $created = $false
        try {
            New-ADUser `
                -Name $name `
                -GivenName $u.FirstName `
                -Surname $u.LastName `
                -SamAccountName $u.SamAccountName `
                -UserPrincipalName "$($u.SamAccountName)@lab.local" `
                -Path $u.OU `
                -AccountPassword $defaultPassword `
                -ChangePasswordAtLogon $true `
                -Enabled $true
            $created = $true

            Add-ADGroupMember -Identity $u.Group -Members $u.SamAccountName
            Write-Host "Created $($u.SamAccountName) and added to $($u.Group)"
        }
        catch {
            Write-Error "Failed to create $($u.SamAccountName): $_"

            # If New-ADUser failed (for example, the password was rejected),
            # remove the partial disabled account so the file can be run again.
            if (-not $created -and (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue)) {
                Remove-ADUser -Identity $u.SamAccountName -Confirm:$false
                Write-Warning "Removed the partial account $($u.SamAccountName) so the file can be run again."
            }
        }
    }
}
