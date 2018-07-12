#By Saugata Datta 
#Specify the output CSV file bellow 
$ExportPath = "c:\vmware\vsi.csv" 
#Temporary variable to run this script faster 
$VmInfo = Get-VM 
$VMS = ($VmInfo).Name 
#Getting the required value 
$VCenter = @() 
foreach ($VM in $VMS) 
{ 
    $HostServer = (($VmInfo | ? {$_.Name -eq $VM}).Host).Name 
    $VMSysInfo = Get-VMGuest -VM $VM 
    $MyObject = New-Object PSObject -Property @{ 
       VMName = $VM 
       VMHostName = $VMSysInfo.HostName 
       VMIP = $VMSysInfo.IPAddress 
       VMInstalledOS = $VMSysInfo.OSFullName 
       PowerState = ($VmInfo | ? {$_.Name -eq $VM}).PowerState 
       NumberOfCPU = ($VmInfo | ? {$_.Name -eq $VM}).NumCpu 
       MemoryGB = (($VmInfo | ? {$_.Name -eq $VM}).MemoryMB/1024) 
       VMDataS = (Get-Datastore -VM $VM).Name 
       HostServer = (($VmInfo | ? {$_.Name -eq $VM}).Host).Name 
       HostCluster = (Get-Cluster -VMHost $HostServer).Name     
    } 
       $VCenter += $MyObject 
} 
$VCenter |  
Select VMName, 
       VMHostName, 
       @{N='VMIPAddress';E={$_.VMIP -join '; '}}, 
       VMInstalledOS, 
       PowerState, 
       NumberOfCPU, 
       MemoryGB, 
       @{N='VMDataStore';E={$_.VMDataS -join '; '}}, 
       HostServer, 
       HostCluster |  
Export-Csv $ExportPath -NoTypeInformation