$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-NonInteractive -NoLogo -NoProfile -File C:\Scripts\Cleanup.ps1"

$Trigger = New-ScheduledTaskTrigger -At "02:00" -Daily -RandomDelay (New-TimeSpan -Minutes 60)

$Settings = New-ScheduledTaskSettingsSet

Register-ScheduledTask -Action $action -TaskName "Daily Log Cleanup" -Description "This script will clear down Event Logs and DSC log files on a host and will be launched as a daily Scheduled Task" -RunLevel Highest -Settings $settings -TaskPath Microsoft\Windows\Housekeeping -Trigger $trigger -User System
