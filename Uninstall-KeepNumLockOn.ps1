Unregister-ScheduledTask -TaskName KeepNumLockOn -Confirm:$false
Remove-Item -Recurse -Force $env:ProgramData\KeepNumLockOn
