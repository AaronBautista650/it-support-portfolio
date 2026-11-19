# PowerShell Scripts

I wrote five PowerShell scripts for common help desk and admin tasks, then tested each one in the lab. Each script runs on WIN11-01 or DC01. Scripts that change something support `-WhatIf`, which shows what would happen without changing anything. No script stores a password in a file.

## Scripts at a glance

| Script | What it does | Where it runs | Tested |
|--------|--------------|---------------|--------|
| [Get-SystemInfo.ps1](scripts/Get-SystemInfo.ps1) | Shows the computer name, OS, CPU, RAM, C: free space, and uptime | WIN11-01, DC01 | Yes |
| [New-BulkUsers.ps1](scripts/New-BulkUsers.ps1) | Creates AD users from a CSV and adds each to a group | DC01 | Yes |
| [Reset-UserPassword.ps1](scripts/Reset-UserPassword.ps1) | Resets a password and requires a change at next sign-in | DC01 | Yes |
| [Find-InactiveUsers.ps1](scripts/Find-InactiveUsers.ps1) | Lists enabled accounts with no sign-in for a set number of days | DC01 | Yes |
| [Clear-TempFiles.ps1](scripts/Clear-TempFiles.ps1) | Deletes old files from the temp folder and reports the size in KB | WIN11-01 | Yes |

## Why these scripts matter

Think of each script as a checklist that a computer follows exactly the same way every time. A human might forget a step, but the script doesn't.

- **Get-SystemInfo** is like reading a car's dashboard before you check the engine. It gives you the facts before you start troubleshooting.
- **New-BulkUsers** is like a form letter. You fill in one spreadsheet, and the script makes every account the same way. Making 50 accounts by hand is slow and easy to get wrong.
- **Reset-UserPassword** is like re-keying a lock for one person. It changes the password, makes the user pick a new one at the next sign-in, and unlocks the account if it's locked.
- **Find-InactiveUsers** is like checking a library's list of books that haven't been returned in months. It finds accounts nobody uses, so you can disable them.
- **Clear-TempFiles** is like emptying the trash can. It removes files the computer no longer needs and frees disk space.

## How I tested each script

**Get-SystemInfo.ps1.** I ran it on WIN11-01 and DC01. WIN11-01 reported 52.15 GB free on C:, and DC01 reported ComputerName `DC01`. The output matched what I saw in Storage settings and Server Manager, so I knew the numbers were right.

**New-BulkUsers.ps1.** I first ran it with a CSV that had test users in the Sales and HR OUs. The first run failed on the password. Windows requires at least 12 characters with uppercase, lowercase, a number, and a symbol. The failed run left the accounts behind, disabled and with no group. I deleted them and ran the script again with a valid password. Both accounts came out as `Enabled: True`, in the right OU, and in the right group.

**Reset-UserPassword.ps1.** I first ran it with `-WhatIf`, which showed the operation without changing anything. Then I ran it for real on tuser1. The output said "The user must change it at next sign-in," and `pwdLastSet` was `0`, which confirms the change is required at next sign-in.

**Find-InactiveUsers.ps1.** I ran it with `-Days 30`. It listed tuser1 and tuser2, which never signed in, plus several existing accounts. Blank LastLogonDate means the account has never signed in.

**Clear-TempFiles.ps1.** A normal 7-day run found 0 files, since the VM is new. I ran it with `-OlderThanDays 0` so every temp file counted as old. The preview listed 32 files, and the real run deleted all 32. Then I changed the script to report KB instead of MB, since the files are too small to show as MB.

## Known limits

- **New-BulkUsers leaves a disabled account behind if the password fails.** A cleanup step in the error handler would prevent this. I haven't added it yet.
- **Find-InactiveUsers shows a blank Department column.** New-BulkUsers sets group membership, not the Department attribute, so that column stays empty.
- **Clear-TempFiles skips files that are in use.** It reports how many it deleted, so a skipped file shows up as a difference between "Found" and "Deleted."

## Running a script

1. Open PowerShell as administrator.
2. Allow scripts for this window only:
   ```
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
   This setting only lasts for the current window, so run it again in each new window.
3. Go to the scripts folder and run the script. Start with `-WhatIf` where it's available.