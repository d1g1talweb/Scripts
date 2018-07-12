# ESXi Host Rename and IP
# 4-19-18
# Robert Anderson
# Change ESXi Hostname, Mgmt IP, and VMotion IP. 
 
##add-pssnapin vmware.vimautomation.vds - Add this snapin if using PowerCLI 5.5 or lower. 
#add-pssnapin vmware.vimautomation.core - Add this snapin if using PowerCLI 5.5 or lower.
start-sleep -s 3
 
start-transcript -path C:\temp\Host-Rename\ESXI_Host_Config_Log.txt
$Servers = import-csv C:\temp\Host-Rename\ReName-IP.csv
$S = 0
 
foreach($Server in $Servers)
{
	# Connect to VCenter
	Connect-VIServer -Server $Server.VCenterName -user $Server.VCuser -password $Server.VCpass

	# Host enter maintenance mode and remove host
	Set-VMHost -VMHost $Server.OldName -State Maintenance -Evacuate:$true | Out-Null
	Set-VMHost -VMHost $Server.OldName -State Disconnected -Confirm:$false |
    Remove-VMHost -Confirm:$false | Out-Null
	Disconnect-viserver -Server * -Force -Confirm:$false
	
    # Connect to ESXI Host Direct - Change Name
    connect-viserver -server $Server.OldName -user root -password $Server.HostPassword
    $HostNet = get-vmhostnetwork
    set-vmhostnetwork -Network $HostNet -Hostname $Server.NewName
	
	# Sets IP Address of VMotion Port Group
	$VMNic = Get-VMHost | Get-VMHostNetworkAdapter | where {$_.VMotionEnabled}
	Set-VMHostNetworkAdapter -VirtualNic $VMNic -ip $Server.VMotionIP -Confirm:$false
	###Set-VMHostNetworkAdapter -VirtualNic $VMNic -ip $Server.VMotionIP -SubnetMask $Server.VMotionMask -Confirm:$false
	
	# Sets IP Address of Management Port Group
	$MGTNic = Get-VMHost | Get-VMHostNetworkAdapter | where {$_.ManagementTrafficEnabled}
	###set-vmhostnetworkadapter -virtualnic vmk0 -ip $Server.NewMGMTIP -SubnetMask $Server.MGMTMask -Confirm:$false
	Set-VMHostNetworkAdapter -VirtualNic $MGTNic -ip $Server.NewMGMTIP -Confirm:$false
	Disconnect-viserver -Server * -Force -Confirm:$false
	
	# Rename Local Datastore and exit maintenance mode
	connect-viserver -server $Server.NewName -user root -password $Server.HostPassword
	$esxhost = Get-VMHost
	$FQname = $esxhost.name
	$HostName = $FQname.Split(".")[0]
	Get-Datastore -Name *_local | Set-Datastore -Name $HostName"_local"
	Set-VMHost -State Connected -Confirm:$false
	Disconnect-viserver -Server * -Force -Confirm:$false
	
	# Add Host by New Name to VCenter
	Connect-VIServer -Server $Server.VCenterName -user $Server.VCuser -password $Server.VCpass | Out-Null
    Add-VMHost -Name $Server.NewName -Location $Server.ClusterName -user root -password $Server.HostPassword -Force -Confirm:$false
	Disconnect-viserver -Server * -Force -Confirm:$false
    }
 
start-sleep -s 5
 
$S++
Write-Progress -Activity "Configuring ESXI Hosts" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)
 
Write-Host "!!!Host Configurations Complete!!!" -ForegroundColor Green
 
Stop-Transcript