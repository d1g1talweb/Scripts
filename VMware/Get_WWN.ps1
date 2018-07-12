$scope = Get-VMHost     # All hosts connected in vCenter
#$scope = Get-Cluster -Name 'Staging' | Get-VMHost # All hosts in a specific cluster
foreach ($esx in $scope){
Write-Host $esx
$hbas = Get-VMHostHba -VMHost $esx -Type FibreChannel
foreach ($hba in $hbas){
$wwpn = "{0:x}" -f $hba.PortWorldWideName
Write-Host `t $hba.Device, "|", $wwpn
}}