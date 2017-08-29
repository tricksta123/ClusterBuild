$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-NonInteractive -NoLogo -NoProfile -File C:\Scripts\Cleanup.ps1"
$Trigger = New-ScheduledTaskTrigger -At "02:00" -Daily -RandomDelay 60
$Settings = New-ScheduledTaskSettingsSet
$SchedTask = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Description "This script will clear down Event Logs and DSC log files on a host and will be launched as a daily Scheduled Task"
$SchedTask |Register-ScheduledTask -Taskname Daily Log Cleanup -Taskpath Housekeeping -Action $Action -User "System" -Runlevel Highest 

