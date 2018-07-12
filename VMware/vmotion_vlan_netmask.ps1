Get-VMHost | Get-VMHostNetworkAdapter | where {$_.VMotionEnabled} | Set-VMHostNetworkAdapter -SubnetMask 255.255.192.0

Get-VMHost | Get-VirtualPortGroup -Name vMotion | Set-VirtualPortGroup -VLanId 998