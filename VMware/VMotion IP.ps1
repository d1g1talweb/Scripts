#Get-VMHost | Get-VMHostNetwork | Select Hostname, VMkernelGateway -ExpandProperty VirtualNic | Where {$_.VMotionEnabled} | Select Hostname, PortGroupName, IP, SubnetMask, VMkernelGateway, Devicename | Export-CSV C:\vmware\vmotion.csv
#
Get-VMHost | Get-VMHostNetwork | Select Hostname, VMkernelGateway -ExpandProperty VirtualNic | Where {$_.VMotionEnabled} | Select Hostname, PortGroupName, IP, SubnetMask, VMkernelGateway, Devicename | Export-CSV C:\vmware\VMotion\QorC_vmotion.csv


