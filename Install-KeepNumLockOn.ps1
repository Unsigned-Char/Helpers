#requires -RunAsAdministrator
$task = 'KeepNumLockOn'
$dir  = Join-Path $env:ProgramData $task
$run  = Join-Path $dir "$task.ps1"

if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }

@'
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class IdleTimer{
    [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO{public uint cbSize;public uint dwTime;}
    [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO lii);
    public static uint Seconds(){var lii=new LASTINPUTINFO();lii.cbSize=(uint)System.Runtime.InteropServices.Marshal.SizeOf(lii);GetLastInputInfo(ref lii);return((uint)Environment.TickCount-lii.dwTime)/1000;}
}
"@
Add-Type -AssemblyName System.Windows.Forms
$s=New-Object -ComObject WScript.Shell
while($true){
    if([IdleTimer]::Seconds() -ge 300 -and -not [Console]::NumberLock){$s.SendKeys('{NUMLOCK}')}
    Start-Sleep 10
}
'@ | Set-Content -Path $run -Encoding UTF8

$action   = New-ScheduledTaskAction  -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$run`""
$trigger  = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

try { Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName $task -Action $action -Trigger $trigger -Settings $settings -Description 'Keeps NumLock enabled after 5 minutes idle' -Force
Start-ScheduledTask   -TaskName $task
Write-Host "Installed: scheduled task '$task' now running."
