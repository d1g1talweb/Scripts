$outputFile = "c:\vmware\FCPathCount" + (get-date -Format yyyy-MM-dd-HHmm) + ".csv"

$report = @()
 
ForEach ($Datacenter in (Get-Datacenter | Sort-Object -Property Name)) { 
	for ($a=1; $a -lt 100; $a++) {
	Write-Progress -Activity "Working..." ` -PercentComplete $a -CurrentOperation "$a% complete" ` -Status ("Datacenter: {0}" -f $Datacenter.Name) }
    ForEach ($Cluster in ($Datacenter | Get-Cluster | Sort-Object -Property Name)) {  
        ForEach ($esx in ($Cluster | Get-VMhost | Sort-Object -Property Name)) { 
            foreach($hba in (Get-VMHostHba -VMHost $esx -Type FibreChannel)){
                    $target = ($hba.VMhost.ExtensionData.Config.StorageDevice.ScsiTopology.Adapter | where {$_.Adapter -eq $hba.Key}).Target 
                    $luns = Get-ScsiLun -Hba $hba
                    $nrPaths = ($target | %{$_.Lun.Count} | Measure-Object -Sum).Sum
                    $row = "" | select Cluster, VMHost, vmhba, Targets, Devices, Paths
                    $row.Cluster = $Cluster.Name
                    $row.VMHost = $esx.Name
 
                    if ($hba.ExtensionData.Status -eq "online") {
                    if ($row.vmhba -eq $null) {
                        $row.vmhba = $hba.Device
                        $row.Targets = $target.count
                        $row.Devices = $luns.count
                        $row.Paths = $nrpaths
                    } elseif ($row.vmhba -eq $null) {
                        $row.vmhba = $hba.Device
                        $row.Targets = $target.count
                        $row.Devices = $luns.count
                        $row.Paths = $nrpaths
                    }
                    $report += $row
                }
            }
        }
    }
}
 
$report | Export-Csv -Path $outputFile -NoTypeInformation -UseCulture