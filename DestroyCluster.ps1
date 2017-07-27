#######################################################################################################################
# Retrieve Variables for Cluster Build
$OSDClusterVariables = Get-OSDClusterVariables
$OSDClusNodes = $OSDClusterVariables.OSDClusterNodes
$OSDClusName         = $OSDClusterVariables.OSDCluster.Name


#######################################################################################################################

Get-Cluster $OSDClusName | Remove-Cluster -Force -CleanupAD

foreach($OSDClusNode in $OSDClusNodes){
    Invoke-Command -ComputerName $OSDClusNode.Name -ScriptBlock {
        #Remove-WindowsFeature -Name Failover-Clustering
        Get-NetAdapter -Name "Heartbeat"| Remove-NetIPAddress -Confirm $false
        Get-NetAdapter -Name "Heartbeat"| Rename-NetAdapter -NewName "Ethernet 2"
    }
}