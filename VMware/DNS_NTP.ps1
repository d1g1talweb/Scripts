
# Prompt for Datacenter
$DC = read-host "Enter Datacenter (a/b):"

If ($DC -eq "b") {
$dnsone = "192.168.1.50"
$dnstwo = "192.168.2.50"
$ntpone = "192.168.1.50"
$ntptwo = "192.168.2.50"
}

else {
$dnsone = "192.168.2.50"
$dnstwo = "192.168.1.50"
$ntpone = "192.168.2.50"
$ntptwo = "192.168.1.50"
}

$esxHosts = get-VMHost

foreach ($esx in $esxHosts) {

   Write-Host "Configuring DNS on $esx" -ForegroundColor Green
   Get-VMHostNetwork -VMHost $esx | Set-VMHostNetwork -DNSAddress $dnsone , $dnstwo -Confirm:$false

   Write-Host "Removing all NTP Servers from $vmhost" -ForegroundColor Green
   $allNTPList = Get-VMHostNtpServer -VMHost $esx
   Remove-VMHostNtpServer -VMHost $esx -NtpServer $allNTPList -Confirm:$false
   
   Write-Host "Configuring NTP Servers on $esx" -ForegroundColor Green
   Add-VMHostNTPServer -NtpServer $ntpone , $ntptwo -VMHost $esx -Confirm:$false
   
   Write-Host "Configuring NTP Client Policy on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Set-VMHostService -policy "on" -Confirm:$false

   Write-Host "Restarting NTP Client on $esx" -ForegroundColor Green
   Get-VMHostService -VMHost $esx | where{$_.Key -eq "ntpd"} | Restart-VMHostService -Confirm:$false

}
Write-Host "Done!" -ForegroundColor Green