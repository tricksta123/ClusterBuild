function Install-OSDFailoverClustering
{
    if ($(Get-WindowsFeature Failover-Clustering).installstate -notlike '*Installed*')
    {
        Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -WarningAction SilentlyContinue -OutVariable Result | Out-Null
        Return $Result
    }
    else
    {
        $Result = "" | select-object ExitCode
        $Result.ExitCode = "Failover Clustering Feature Already installed"
        Return $Result
    }
}

function Get-DomainStatus
{
    $ComputerInfo = Get-WmiObject Win32_ComputerSystem
    if(($ComputerInfo -eq $null) -or ($ComputerInfo.Domain -eq $null))
    {
        Return "Can't find machine's domain name"
    }
    else
    {
        Return "Machine's domain name found"
    }
}

function Get-WindowsFailoverCluster
{
    param
    (
        [parameter(mandatory)][string] $Name,
        [uint64] $RetryIntervalSec = 10,
        [uint32] $RetryCount = 60
    )
    $clusterFound = $false
    Write-Verbose -Message "Checking for cluster $Name ..."

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        try
        {
            $cluster = get-cluster -Name $Name -ErrorAction SilentlyContinue
            
            if ($cluster -ne $null)
            {
                Write-Verbose -Message "Found cluster $name"
                $clusterFound = $true
                break;
            }
        }
        catch
        {
            Write-Verbose -Message "Cluster $name not found. Will retry again after $RetryIntervalSec seconds"
        }

        Start-Sleep -Seconds $RetryIntervalSec
    }

    if (! $clusterFound)
    {
        throw "Cluster $name not found after $count attempts with $RetryIntervalSec sec interval"
    }

}

function Get-SecondaryNodeStatus
{
 param
    (
        [parameter(mandatory)][array] $OSDSecClusNodes
    )
    
    Write-Verbose -Message "Checking secondary cluster nodes are ready for clustering..."
    $startDate = Get-Date

    do 
    {
        try
        {
            $secClusNodesReady = $true

            foreach($OSDSecClusNode in $OSDSecClusNodes)
            { 
                #if("1" -eq "1"){
                    if(-Not (Test-Connection -ComputerName $OSDSecClusNode.Name -Count 1 -ErrorAction SilentlyContinue))
                    {
                        $secClusNodesReady = $false
                    }
                    else
                        {
                        if((Get-WindowsFeature -ComputerName $OSDSecClusNode.Name -Name Failover-Clustering -ErrorAction SilentlyContinue).InstallState -ne 'Installed')
                        {
                            $secClusNodesReady = $false
                        }
                    }
                #}
            }
        }
        catch
        {
            Write-Verbose -Message "Cluster nodes not yet ready. Retrying...."
        } 
    } 
    while ($secClusNodesReady -eq $false -and $startDate.AddMinutes(10) -gt (Get-Date))


    return $secClusNodesReady
}

function Get-OSDClusterVariables
{
        
$OSDClusterVars = @"
    {
        "OSDCluster":  {
                           "Name":  "CLUSC00",
                           "IPAddress":  "10.10.20.12",
                           "FSWitnessPath":  "\\\\dc01\\docs\\Witness"
                       },
        "OSDClusterNodes":  [
                                {
                                    "HBAddress":  "10.11.20.10",
                                    "Name":  "CLUSN01",
                                    "IPAddress":  "10.10.20.10"
                                },
                                {
                                    "HBAddress":  "10.11.20.11",
                                    "Name":  "CLUSN02",
                                    "IPAddress":  "10.10.20.11"
                                }
                            ]
    }
"@ | ConvertFrom-Json

return $OSDClusterVars
}
