# Reset-UserPassword.ps1
# Resets a user's password in Active Directory and requires a change at next sign-in.
# Also unlocks the account if it is locked. Run on DC01 as a domain admin.
#
# The new password is entered at the prompt and is never written to a file.
#
# Usage:
#   .\Reset-UserPassword.ps1 -SamAccountName "lsmith"
#   .\Reset-UserPassword.ps1 -SamAccountName "lsmith" -WhatIf

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$SamAccountName
)

Import-Module ActiveDirectory

$user = Get-ADUser -Identity $SamAccountName -Properties LockedOut, Enabled -ErrorAction Stop

if (-not $user.Enabled) {
    Write-Warning "$SamAccountName is disabled. Enable the account before resetting the password."
    return
}

$newPassword = Read-Host -Prompt "New temporary password for $SamAccountName" -AsSecureString

if ($PSCmdlet.ShouldProcess($SamAccountName, "Reset password and require change at next sign-in")) {
    Set-ADAccountPassword -Identity $SamAccountName -Reset -NewPassword $newPassword
    Set-ADUser -Identity $SamAccountName -ChangePasswordAtLogon $true

    if ($user.LockedOut) {
        Unlock-ADAccount -Identity $SamAccountName
        Write-Host "Unlocked $SamAccountName."
    }

    Write-Host "Password reset for $SamAccountName. The user must change it at next sign-in."
}
