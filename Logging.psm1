
function Test-EventLog
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $LogName
    )

    [System.Diagnostics.EventLog]::SourceExists($LogName)
}

function Get-LogDate
{
    <#
        .SYNOPSIS
            Generates ISO 8601 standard date notation: YYYY-MM-DD & 24H time
        .Example
            Get-LogDate and get 2016-06-24 17:44:23
        .Example
            Get-LogDate("Compact") and get 20160624_174423

    #>
    [cmdletbinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        $Fmt
    )
    switch($Fmt)
    {
        Default   {Get-Date -Format "yyyy-MM-dd HH:mm:ss"}
        'Compact' {Get-Date -Format "yyyMMdd_HHmmss"}
    }
}

#Default values
$Servername        = $env:COMPUTERNAME
$env:ScriptName        = $MyInvocation.MyCommand.Name
$env:ScriptLogFile = "$env:windir\build\logs\$(Get-LogDate('Compact'))_$ScriptName.log" #check which script sets this

#Create new event log if it does not exist
function New-CustomEventLog
{   
    Param
    (
        [parameter(mandatory=$true)]
        $LogName
    ) 
    $EventLogSource = $env:ScriptName
    try
    {
        New-EventLog -LogName $LogName -Source $EventLogSource -ErrorAction SilentlyContinue
        Limit-EventLog -LogName $LogName -OverflowAction OverWriteAsNeeded -MaximumSize 4096kb
    }
    catch
    {
    }
}


function New-LogEntry
{
    Param
    (
        [parameter(mandatory=$true)]
        $Message,
        [parameter(mandatory=$true)]
        $LogName,
        [parameter(mandatory=$false)]
        [switch]$Warning,
        [parameter(mandatory=$false)]
        [switch]$CopyLogs,
        [parameter(mandatory=$false)]
        $ScriptBlockID
    ) 

    $EventLogSource = $env:ScriptName

    #if((Test-EventLog -LogName $Logname) -eq $false)
    #{
        New-CustomEventLog -LogName $LogName
    #}
    

    if ($ScriptBlockID -eq $null)
    {
        $ScriptBlockID = "00"
    }

    if(-not($Servername -eq $null))
    {
        $Servername = " `[$Servername`] "
    }
    if ($Warning)
    {
        Write-Warning   "$(Get-LogDate) *** Error *** ScriptBlock - $($ScriptBlockID) $($Message)`n$($_.Exception)"
        "$(Get-LogDate)$($Servername)*** Error *** ScriptBlock - $($ScriptBlockID) $($Message)`n$($_.Exception)"| Out-File -Append -FilePath $env:ScriptLogFile
        Write-EventLog -LogName $LogName -Source $EventLogSource -Message "$($Message)`n$($_.Exception)" -EventId $ScriptBlockID -EntryType Warning
	    if($CopyLogs)
        {
            C:\Windows\Build\Tools\Copylogs.exe
        }
    }
    else
    {
        "$(Get-LogDate)$($Servername)ScriptBlock $($ScriptBlockID) $($Message)" |Tee-Object -Append -FilePath $env:ScriptLogFile
        Write-EventLog -LogName $LogName -Source $EventLogSource -Message $Message -EventId $ScriptBlockID -EntryType Information
    }
}
$env:ScriptLogFile = ""
