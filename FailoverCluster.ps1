
#######################################################################################################################

# Set Default Variables
$ScriptBlockID   = "01"
$ScriptBlockName = "Script Initialisation"
$global:ScriptName  = "FailoverClustering"
# $ServerName      = $env:COMPUTERNAME

#######################################################################################################################

#######################################################################################################################
# Retrieve Variables for Cluster Build
$OSDClusterVariables = Get-OSDClusterVariables
$ServerName          = $env:COMPUTERNAME
$OSDClusNodes = $OSDClusterVariables.OSDClusterNodes
$OSDPriClusNode = $OSDClusNodes | Where-Object {$_.name -like "*N01"}
$OSDSecClusNodes = $OSDClusNodes | Where-Object {$_.name -notlike "*N01"}
$OSDClusNode        = $OSDClusNodes | Where-Object {$_.name -like $ServerName}
$OSDClusNodeIPAddr = $OSDClusNode.IPAddress
$OSDClusNodeHBIPAddr = $OSDClusNode.HBAddress
$OSDClusName         = $OSDClusterVariables.OSDCluster.Name
$OSDClusIP    = $OSDClusterVariables.OSDCluster.IPAddress
$OSDFSWitnessPath = $OSDClusterVariables.OSDCluster.FSWitnessPath
$ClusterValidationLog = "$env:windir\build\logs\$(Get-LogDate('Compact'))_$OSDClusName" + "_Cluster_Validation"
$env:ScriptName      = "FailoverClustering"
$env:ScriptLogFile   = "$env:windir\build\logs\$(Get-LogDate('Compact'))_$ScriptName.log" #check which script sets this

#######################################################################################################################


#######################################################################################################################
$ScriptBlockID        = "02"
$ScriptBlockName      = "Configure HeartBeat NIC"


try
{
    Get-NetAdapter -Name "Ethernet 2"| New-NetIPAddress -AddressFamily IPv4 -IPAddress $OSDClusNodeHBIPAddr -PrefixLength 24
    Get-NetAdapter -Name "Ethernet 2"| Rename-NetAdapter -NewName "Heartbeat"

}
catch
{
    Exit "99$($ScriptBlockID)"
}

#######################################################################################################################


#######################################################################################################################
$ScriptBlockID   = "03"
$ScriptBlockName = "Install Windows Feature Failover-Clustering"


if ($(Get-WindowsFeature Failover-Clustering).installstate -notlike '*Installed*')
{
    try
    {
        Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -WarningAction SilentlyContinue -OutVariable ResClusInstall | Out-Null
    }
    catch
    {
        Exit "99$($ScriptBlockID)"
    }
}
if($ResClusInstall.RestartNeeded -eq 'Yes')
{
    try
    {
        #Set-NextAction -TaskName "FailoverClustering" -Action "Reboot" -ErrorAction Stop
        Exit "99$($ScriptBlockID)`nNeeds Reboot..."
    }
    catch
    {
        Exit "99$($ScriptBlockID)"
    }
}

#######################################################################################################################


#######################################################################################################################
$ScriptBlockID   = "04"
$ScriptBlockName = "Test Failover Cluster"

if ($ServerName -like "*N01*")
{
    try
    {
        if ((Test-Connection -CN $OSDClusName -BufferSize 16 -Count 1 -ErrorAction Stop -Quiet) -or (Get-Cluster -Name $OSDClusName))
        {
                $CanBuildCluster = $false
        }
        else
        {
                $CanBuildCluster = $true
        }
        if((Get-WindowsFeature -ComputerName $SecClusNodes.Name -Name Failover-Clustering).InstallState -eq 'Installed') # Check this works on more than one secondary node
        {
                $FeatureInstalled = $true
        }
        if(($CanBuildCluster -eq $true -and $FeatureInstalled -eq $true))
        {
            Test-Cluster -Node $OSDClusNodes -ReportName $ClusterValidationLog -ErrorAction Stop
        }
    }
    catch
    {
        Write-Warning $OSDClusName "Already exists, ....Exiting."
        $CanBuildCluster = $false
        Exit "99$($ScriptBlockID)"
    }
}

else
{
    {
        Get-WindowsFailoverCluster -Name $OSDClusName
        Exit "99$($ScriptBlockID)"
    }
}
#######################################################################################################################


#######################################################################################################################
$ScriptBlockID   = "05"
$ScriptBlockName = "Build Failover Cluster"

try
{
    $ClusterBuild = New-Cluster -Name $OSDClusName -Node $OSDClusNodes -StaticAddress $OSDClusIP -NoStorage -ErrorAction Stop -war
}
catch
{
     Exit "99$($ScriptBlockID)"
}
#######################################################################################################################


#######################################################################################################################
$ScriptBlockID   = "06"
$ScriptBlockName = "Configure Failover Cluster"
Start-Sleep -Seconds 30


try
{
    $ClusterWitness = Get-Cluster -Name $OSDClusName | Set-ClusterQuorum -FileShareWitness $OSDClusFSWit -ErrorAction Stop
}
catch
{
    Exit "99$($ScriptBlockID)"
}
try
{
    #  Fine Tuning failover cluster network thresholds. (applied to Windows Server 2012 R2 and Windows Server 2016) - Article 3153887
    $SameSubnetThreshold = (Get-Cluster -Name $OSDClusName).SameSubnetThreshold = 10
    $CrossSubnetThreshold = (Get-Cluster -Name $OSDClusName).CrossSubnetThreshold = 20
    $RouteHistoryLength = (Get-Cluster -Name $OSDClusName).RouteHistoryLength = 20
}
catch
{
    Exit "99$($ScriptBlockID)"
}
try
{
    $ClusterIntNetNameChange = (Get-Cluster -Name $OSDClusName | Get-ClusterNetwork | where{$_.role -eq 1}).Name = "Heartbeat"
    $ClusterHBNetNameChange = (Get-Cluster -Name $OSDClusName | Get-ClusterNetwork | where{$_.role -eq 3}).Name = "Internal"
}
catch
{
    Exit "99$($ScriptBlockID)"
}
#######################################################################################################################


#End of Script
$ScriptBlockID   = "99"
$ScriptBlockName = ""

