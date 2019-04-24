#######################################################################################
#                               UCS Config SCRIPT                                     #
#                           Bobby Anderson 3/31/2014                                  #
#            Make sure the UCSPowertool is installed to the directory below           #
# C:\Program Files (x86)\Cisco\Cisco UCS PowerTool\Modules\CiscoUcsPS\CiscoUcsPS.psd1 #                                  
#######################################################################################

# Global Variables #
$user = "admin"
$password = "ucsadmin"
$ucsvip = "10.10.1.100"
$mgmtDNS = ("10.10.1.1","10.10.2.1")
$mgmtNTP = ("10.10.1.1","10.10.2.1")
# call home variables #
$smtp_server = "smtp.d1g1talweb.com"
$smtp_port = "25"
$callhome_street_address = "## Street, City, State(xx) zipcode"
$callhome_contact_name = "Robert Anderson"
$callhome_contact_phone = "+15555555555"
$callhome_email_to = "bobby@d1g1talweb.com"
$callhome_email_from = "bobby@d1g1talweb.com"
$callhome_email_reply = "bobby@d1g1talweb.com"
# ethernet port channel variables #
$ethpc_a_name = "po101"
$ethpc_a_id = "101"
$ethpc_a_ports = ("17","18","19","20")
$ethpc_a_slot = "2"
$ethpc_b_name = "po102"
$ethpc_b_id = "102"
$ethpc_b_ports = ("17","18","19","20")
$ethpc_b_slot = "2"
# fc port channel variables #
$fcpc_a_name = "pc10"
$fcpc_a_id = "10"
$fcpc_a_ports = ("37","38","39","40")
$fcpc_a_slot = "2"
$fcpc_b_name = "pc11"
$fcpc_b_id = "11"
$fcpc_b_ports = ("37","38","39","40")
$fcpc_b_slot = "2"
# vsans #
$vsan_a_name = "VSAN_A_10"
$vsan_a_id = "10"
$vsan_a_fcoe = "1500"
$vsan_b_name = "VSAN_B_11"
$vsan_b_id = "11"
$vsan_b_fcoe = "1501"
# cimc, uuid, iscsi pools #
$cimcGW = "10.30.240.1"
$cimcIPfrom = "10.30.244.9"
$cimcIPto = "10.30.245.73"
# san boot variables #
$vHBA0_primary_boot = "50:06:01:62:3C:E0:2D:51"
$vHBA0_secondary_boot = "50:06:01:6B:3C:E0:2D:51"
$vHBA1_primary_boot = "50:06:01:63:3C:E0:2D:51"
$vHBA1_secondary_boot = "50:06:01:6A:3C:E0:2D:51"
# service profiles #
$host_fw = "2.23d"
$service_profile_name = "esxi0"
$count = "2"

#########################################
# Import the Cisco UCS PowerTool module #
#########################################
Import-Module 'C:\Program Files (x86)\Cisco\Cisco UCS PowerTool\Modules\CiscoUcsPS\CiscoUcsPS.psd1'

############################################
# Authenticate to UCSM with the admin user #
############################################
$password_1 = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object system.Management.Automation.PSCredential($user, $password_1)
$handle1 = Connect-Ucs $ucsvip -Credential $cred

################
# Create VLANs #
################
Start-UcsTransaction
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 3248 -Name ESXi3248
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 3240 -Name KVM3240
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 224 -Name MGMT224
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 128 -Name VDI128
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 132 -Name VDI132
Get-UcsLanCloud | Add-UcsVlan -DefaultNet no -Id 136 -Name VDI136
Complete-UcsTransaction

##################################
# Create CIMC, UUID, iSCSI pools #
##################################
Get-UcsIpPool -Name ext-mgmt | Add-UcsIpPoolBlock -DefGw $cimcGW -From $cimcIPfrom -To $cimcIPto

Start-UcsTransaction
$uuid = Get-UcsOrg -Level root  | Add-UcsUuidSuffixPool -Descr "UUID Pool for Server system board IDs" -Name Global-UUID-Pool -Prefix 000025B5-0005-0000 -AssignmentOrder sequential
$uuid_1 = $uuid | Add-UcsUuidSuffixBlock -From 0000-000000000001 -To 0000-000000000080
Complete-UcsTransaction

Get-UcsIpPool -Name iscsi-initiator-pool | Add-UcsIpPoolBlock -From 169.254.3.8 -To 169.254.3.8

############################
# Create MAC Address Pools #
############################
Start-UcsTransaction
$maca = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-0 on Fabric A" -Name vNIC-0-Fabric-A -AssignmentOrder sequential
$maca_1 = $maca | Add-UcsMacMemberBlock -From 00:25:B5:05:A0:00 -To 00:25:B5:05:A0:7F
Complete-UcsTransaction

Start-UcsTransaction
$macb = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-1 on Fabric B" -Name vNIC-1-Fabric-B  -AssignmentOrder sequential
$macb_1 = $macb | Add-UcsMacMemberBlock -From 00:25:B5:05:B1:00 -To 00:25:B5:05:B1:7F
Complete-UcsTransaction

Start-UcsTransaction
$maca = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-2 on Fabric A" -Name vNIC-2-Fabric-A -AssignmentOrder sequential
$maca_1 = $maca | Add-UcsMacMemberBlock -From 00:25:B5:05:A2:00 -To 00:25:B5:05:A2:7F
Complete-UcsTransaction

Start-UcsTransaction
$macb = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-3 on Fabric B" -Name vNIC-3-Fabric-B -AssignmentOrder sequential
$macb_1 = $macb | Add-UcsMacMemberBlock -From 00:25:B5:05:B3:00 -To 00:25:B5:05:B3:7F
Complete-UcsTransaction

Start-UcsTransaction
$maca = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-4 on Fabric A" -Name vNIC-4-Fabric-A -AssignmentOrder sequential
$maca_1 = $maca | Add-UcsMacMemberBlock -From 00:25:B5:05:A4:00 -To 00:25:B5:05:A4:7F
Complete-UcsTransaction

Start-UcsTransaction
$macb = Get-UcsOrg -Level root  | Add-UcsMacPool -Descr "MAC Address Pool for vNIC-5 on Fabric B" -Name vNIC-5-Fabric-B -AssignmentOrder sequential
$macb_1 = $macb | Add-UcsMacMemberBlock -From 00:25:B5:05:B5:00 -To 00:25:B5:05:B5:7F
Complete-UcsTransaction

###########################
# Create WWNN, WWPN Pools #
###########################
Start-UcsTransaction
$wwnn = Get-UcsOrg -Level root  | Add-UcsWwnPool -Descr "Server WWNN Pool" -Name Global-WWNN-Pool -Purpose node-wwn-assignment -AssignmentOrder sequential
$wwnn_1 = $wwnn | Add-UcsWwnMemberBlock -From 20:00:00:25:B5:05:11:00 -To 20:00:00:25:B5:05:11:7F
Complete-UcsTransaction

Start-UcsTransaction
$wwpna = Get-UcsOrg -Level root  | Add-UcsWwnPool -Descr "WWPN Pool for vHBA-0 on Fabric A" -Name vHBA-0-Fabric-A -Purpose port-wwn-assignment -AssignmentOrder sequential
$wwpna_1 = $wwpna | Add-UcsWwnMemberBlock -From 20:00:00:25:B5:05:A0:00 -To 20:00:00:25:B5:05:A0:7F
Complete-UcsTransaction

Start-UcsTransaction
$wwpnb = Get-UcsOrg -Level root  | Add-UcsWwnPool -Descr "WWPN Pool for vHBA-1 on Fabric B" -Name vHBA-1-Fabric-B -Purpose port-wwn-assignment -AssignmentOrder sequential
$wwpnb_1 = $wwpnb | Add-UcsWwnMemberBlock -From 20:00:00:25:B5:05:B1:00 -To 20:00:00:25:B5:05:B1:7F
Complete-UcsTransaction

################
# Create VSANs #
################
Start-UcsTransaction
Get-UcsFabricSanCloud -Id A | Add-UcsVsan -FcoeVlan $vsan_a_fcoe -Id $vsan_a_id -Name $vsan_a_name
Get-UcsFabricSanCloud -Id B | Add-UcsVsan -FcoeVlan $vsan_b_fcoe -Id $vsan_b_id -Name $vsan_b_name
Complete-UcsTransaction

##############################################################
# Remove default Server, UUID, WWNN, WWPN, IQN and MAC pools #
##############################################################
Get-UcsServerPool -Name default -LimitScope | Remove-UcsServerPool -Force
Get-UcsUuidSuffixPool -Name default -LimitScope | Remove-UcsUuidSuffixPool -Force
Get-UcsWwnPool -Name node-default -LimitScope | Remove-UcsWwnPool -Force
Get-UcsWwnPool -Name default -LimitScope | Remove-UcsWwnPool -Force
Get-UcsMacPool -Name default -LimitScope | Remove-UcsMacPool -Force

##############################################################
# Set Global System Policies for chassis discovery and power #
##############################################################
Get-UcsChassisDiscoveryPolicy | Set-UcsChassisDiscoveryPolicy -Action 1-link -LinkAggregationPref port-channel -Rebalance user-acknowledged -Force
Get-UcsPowerControlPolicy | Set-UcsPowerControlPolicy -Redundancy grid -Force
Get-UcsFirmwareAutoSyncPolicy | Set-UcsFirmwareAutoSyncPolicy -SyncState "No Actions"

##########################
# Set UCS Admin Settings #
##########################
foreach ($dns in $mgmtDNS)
    {
    Add-UcsDnsServer -Name $dns
    }
	
Set-UcsTimezone -Timezone America/New_York -Force 

foreach ($ntp in $mgmtNTP)
    {
    Add-UcsNtpServer -Name $ntp
    }

######################
# Configure Callhome #
######################
Start-UcsTransaction
$mo = Get-UcsCallhome | Set-UcsCallhome -AdminState on -AlertThrottlingAdminState on -Force
$mo_1 = Get-UcsCallhomeSmtp | Set-UcsCallhomeSmtp -Host $smtp_server -Port $smtp_port -Force
$mo_2 = Get-UcsCallhomeSource | Set-UcsCallhomeSource -Addr $callhome_street_address -Contact $callhome_contact_name -Email $callhome_email_to -From $callhome_email_from -Phone $callhome_contact_phone -ReplyTo $callhome_email_reply -Urgency debug -Force
Complete-UcsTransaction

#########################################################
# Remove default Server, UUID, WWNN, WWPN and MAC pools #
#########################################################
Get-UcsServerPool -Name default -LimitScope | Remove-UcsServerPool -Force
Get-UcsUuidSuffixPool -Name default -LimitScope | Remove-UcsUuidSuffixPool -Force
Get-UcsWwnPool -Name node-default -LimitScope | Remove-UcsWwnPool -Force
Get-UcsWwnPool -Name default -LimitScope | Remove-UcsWwnPool -Force
Get-UcsMacPool -Name default -LimitScope | Remove-UcsMacPool -Force

############################
# Create LAN Port-Channels #
############################
Start-UcsTransaction
$mo = Get-UcsFabricLanCloud -Id A | Add-UcsUplinkPortChannel -AdminState disabled -Name $ethpc_a_name -PortId $ethpc_a_id
foreach ($ethaport in $ethpc_a_ports)
    {
    $mo_1 = $mo | Add-UcsUplinkPortChannelMember -ModifyPresent -AdminState enabled -PortId $ethaport -SlotId $ethpc_a_slot
    }
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsFabricLanCloud -Id B | Add-UcsUplinkPortChannel -AdminState disabled -Name $ethpc_b_name -PortId $ethpc_b_id
foreach ($ethbport in $ethpc_b_ports)
    {
    $mo_1 = $mo | Add-UcsUplinkPortChannelMember -ModifyPresent -AdminState enabled -PortId $ethbport -SlotId $ethpc_b_slot
    }
Complete-UcsTransaction

############################
# Create SAN Port-Channels #
############################
Start-UcsTransaction
$mo = Get-UcsFabricSanCloud -Id A | Add-UcsFcUplinkPortChannel -AdminState disabled -Name $fcpc_a_name -PortId $fcpc_a_id
foreach ($fcaport in $fcpc_a_ports)
    {
$mo_1 = $mo | Add-UcsFabricFcSanPcEp -ModifyPresent -AdminSpeed auto -AdminState enabled -PortId $fcaport -SlotId $fcpc_a_slot
    }
Complete-UcsTransaction

Get-UcsFabricSanCloud -Id A | Get-UcsVsan -Name $vsan_a_name | Add-UcsVsanMemberFcPortChannel -ModifyPresent -AdminState disabled -PortId $vsan_a_id -SwitchId A

Start-UcsTransaction
$mo = Get-UcsFabricSanCloud -Id B | Add-UcsFcUplinkPortChannel -AdminState disabled -Name $fcpc_b_name -PortId $fcpc_b_id
foreach ($fcbport in $fcpc_b_ports)
    {
$mo_1 = $mo | Add-UcsFabricFcSanPcEp -ModifyPresent -AdminSpeed auto -AdminState enabled -PortId $fcbport -SlotId $fcpc_b_slot
    }
Complete-UcsTransaction

Get-UcsFabricSanCloud -Id B | Get-UcsVsan -Name $vsan_b_name | Add-UcsVsanMemberFcPortChannel -ModifyPresent -AdminState disabled -PortId $vsan_b_id -SwitchId B

################################
# Configure QoS System classes #
################################
Start-UcsTransaction
Set-UcsQosClass -QosClass platinum -Weight best-effort -AdminState enabled -cos 6 -drop no-drop -mtu normal -Force
Set-UcsQosClass -QosClass gold -Weight 2 -AdminState enabled -cos 4 -drop drop -mtu normal -Force
Set-UcsQosClass -QosClass silver -Weight 10 -AdminState disabled -cos 2 -drop drop -mtu normal -Force
Set-UcsQosClass -QosClass bronze -Weight 10 -AdminState disabled -cos 1 -drop drop -mtu normal -Force
Set-UcsBestEffortQosClass -Weight 7 -mtu normal -Force
Set-UcsFcQosClass -cos 3 -Weight 10 -Force
Complete-UcsTransaction

#######################
# Create QoS Policies #
#######################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Default
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl full -Prio best-effort 
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Platinum
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl none -Prio platinum 
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Gold
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl none -Prio gold
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Silver
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl none -Prio silver 
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Bronze
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl none -Prio bronze 
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsQosPolicy -Name QoS_Fc
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -HostControl none -Prio fc 
Complete-UcsTransaction

###############################################
# Create Network Control Policy to Enable CDP #
###############################################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsNetworkControlPolicy -Cdp enabled -MacRegisterMode only-native-vlan -Name CDP-Link-Loss -UplinkFailAction link-down
$mo_1 = $mo | Add-UcsPortSecurityConfig -ModifyPresent -Forge allow
Complete-UcsTransaction

#########################
# Create vNIC Templates #
#########################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic0 for Management vmkernel on Fabric A" -IdentPoolName vNIC-0-Fabric-A -Mtu 1500 -Name vNIC-0-Fabric-A -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId A -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet yes -Name ESXi3248
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic1 for Management vmkernel on Fabric B" -IdentPoolName vNIC-1-Fabric-B -Mtu 1500 -Name vNIC-1-Fabric-B -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId B -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet yes -Name ESXi3248
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic2 for vMotion vmkernel on Fabric A" -IdentPoolName vNIC-2-Fabric-A -Mtu 1500 -Name vNIC-2-Fabric-A -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId A -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet yes -Name VMOTION999
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic3 for vMotion vmkernel on Fabric B" -IdentPoolName vNIC-3-Fabric-B -Mtu 1500 -Name vNIC-3-Fabric-B -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId B -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VMOTION999
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic4 for VM networking on Fabric A" -IdentPoolName vNIC-4-Fabric-A -Mtu 1500 -Name vNIC-4-Fabric-A -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId A -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI128
$mo_2 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI132
$mo_3 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI136
$mo_4 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI140
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "VMware ESXi vmnic5 for VM networking on Fabric A" -IdentPoolName vNIC-5-Fabric-B -Mtu 1500 -Name vNIC-5-Fabric-B -NwCtrlPolicyName CDP-Link-Loss -QosPolicyName QoS_Default -StatsPolicyName default -SwitchId B -TemplType updating-template
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI128
$mo_2 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI132
$mo_3 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI136
$mo_4 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet no -Name VDI140
Complete-UcsTransaction

#########################
# Create vHBA Templates #
#########################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVhbaTemplate -Descr "VMware ESXi vHBA-0 for Fabric A" -IdentPoolName vHBA-0-Fabric-A -MaxDataFieldSize 2048 -Name vHBA-0-Fabric-A -QosPolicyName QoS_Fc -StatsPolicyName default -SwitchId A -TemplType updating-template
$mo_1 = $mo | Add-UcsVhbaInterface -ModifyPresent -Name default
Complete-UcsTransaction

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVhbaTemplate -Descr "VMware ESXi vHBA-1 for Fabric B" -IdentPoolName vHBA-1-Fabric-B -MaxDataFieldSize 2048 -Name vHBA-1-Fabric-B -QosPolicyName QoS_Fc -StatsPolicyName default -SwitchId B -TemplType updating-template
$mo_1 = $mo | Add-UcsVhbaInterface -ModifyPresent -Name default
Complete-UcsTransaction

########################
# Create BIOS Policies #
########################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsBiosPolicy -Name esxi -RebootOnUpdate no
$mo_1 = $mo | Set-UcsBiosVfQuietBoot -VpQuietBoot disabled -Force
$mo_2 = $mo | Set-UcsBiosLvDdrMode -VpLvDDRMode performance-mode -Force
$mo_3 = $mo | Set-UcsBiosVfProcessorC1E -VpProcessorC1E disabled -Force
Complete-UcsTransaction

############################
# Create SAN Boot Policies #
############################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsBootPolicy -Descr "Boot from SAN policy for ESXi hosts" -EnforceVnicName no -Name esxi-san-boot -RebootOnUpdate no
$mo_1 = $mo | Add-UcsLsbootVirtualMedia -Access read-only -Order 1
$mo_2 = $mo | Add-UcsLsbootStorage -ModifyPresent -Order 2
$mo_2_1 = $mo_2 | Add-UcsLsbootSanImage -Type primary -VnicName vHBA0-Fabric-A
$mo_2_1_1 = $mo_2_1 | Add-UcsLsbootSanImagePath -Lun 0 -Type primary -Wwn $vHBA0_primary_boot
$mo_2_1_2 = $mo_2_1 | Add-UcsLsbootSanImagePath -Lun 0 -Type secondary -Wwn $vHBA0_secondary_boot
$mo_2_2 = $mo_2 | Add-UcsLsbootSanImage -Type secondary -VnicName vHBA1-Fabric-B
$mo_2_2_1 = $mo_2_2 | Add-UcsLsbootSanImagePath -Lun 0 -Type primary -Wwn $vHBA1_primary_boot
$mo_2_2_2 = $mo_2_2 | Add-UcsLsbootSanImagePath -Lun 0 -Type secondary -Wwn $vHBA1_secondary_boot
Complete-UcsTransaction

############################
# Create Local Boot Policy #
############################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsBootPolicy -Descr "" -EnforceVnicName yes -Name Boot-Local -RebootOnUpdate no
$mo_1 = $mo | Add-UcsLsbootVirtualMedia -Access read-only -Order 1
$mo_2 = $mo | Add-UcsLsbootStorage -ModifyPresent -Order 2
Complete-UcsTransaction

############################
# Create Local Disk Policy #
############################
Get-UcsOrg -Level root  | Add-UcsLocalDiskConfigPolicy -Descr "Any-Config" -Mode any-configuration -Name Any-Config -ProtectConfig no
Get-UcsOrg -Level root  | Add-UcsLocalDiskConfigPolicy -Descr "Raid 1 Boot Policy" -Mode raid-mirrored -Name Boot-Local -ProtectConfig no

#############################
# Create maintenance policy #
#############################
Get-UcsOrg -Level root  | Add-UcsMaintenancePolicy -Descr "User acknowledge is required to reboot a server after a disruptive change" -Name user-acknowledge -UptimeDisr user-ack

#################################
# Create disk/BIOS Scrub Policy #
#################################
Get-UcsOrg -Level root  | Add-UcsScrubPolicy -BiosSettingsScrub no -DiskScrub no -Name no-scrub

################################
# Create a no-power cap policy #
################################
Get-UcsOrg -Level root  | Add-UcsPowerPolicy -Name no-power-cap -Prio no-cap

#####################################
# Create vNIC/vHBA Placement Policy #
#####################################
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsPlacementPolicy -Descr "For Half-width blades" -Name b200-b230
$mo_1 = $mo | Add-UcsFabricVCon -ModifyPresent -Fabric NONE -Id 1 -Placement physical -Select all -Share shared -Transport ethernet,fc
Complete-UcsTransaction

####################################
# Create Service Profile Templates #
####################################
# Boot From SAN #
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsServiceProfile -BiosProfileName esxi -BootPolicyName esxi-san-boot -Descr "Service Profile Template for VMware ESXi hosts" -ExtIPState pooled -HostFwPolicyName $host_fw -IdentPoolName Global-UUID-Pool -LocalDiskPolicyName Any-Config -MaintPolicyName user-acknowledge -Name ESX-San-Boot -PowerPolicyName no-power-cap -ScrubPolicyName no-scrub -StatsPolicyName default -Type updating-template -VconProfileName b200-b230
$mo_1 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-0-Fabric-A -NwTemplName vNIC-0-Fabric-A -Order 1 -StatsPolicyName default -SwitchId A
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-1-Fabric-B -NwTemplName vNIC-1-Fabric-B -Order 2 -StatsPolicyName default -SwitchId B
$mo_3 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-2-Fabric-A -NwTemplName vNIC-2-Fabric-A -Order 3 -StatsPolicyName default -SwitchId A
$mo_4 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-3-Fabric-B -NwTemplName vNIC-3-Fabric-B -Order 4 -StatsPolicyName default -SwitchId B
$mo_5 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-4-Fabric-A -NwTemplName vNIC-4-Fabric-A -Order 5 -StatsPolicyName default -SwitchId A
$mo_6 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-5-Fabric-B -NwTemplName vNIC-5-Fabric-B -Order 6 -StatsPolicyName default -SwitchId B
$mo_7 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-6-Fabric-A -NwTemplName vNIC-6-Fabric-A -Order 7 -StatsPolicyName default -SwitchId A
$mo_8 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-7-Fabric-B -NwTemplName vNIC-7-Fabric-B -Order 8 -StatsPolicyName default -SwitchId B
$mo_9 = $mo | Add-UcsVnicFcNode -ModifyPresent -Addr pool-derived -IdentPoolName Global-WWNN-Pool
$mo_10 = $mo | Add-UcsVhba -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -MaxDataFieldSize 2048 -Name vHBA-0-Fabric-A -NwTemplName vHBA-0-Fabric-A -Order 9 -PersBind disabled -PersBindClear no -StatsPolicyName default -SwitchId A
$mo_11 = $mo | Add-UcsVhba -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -MaxDataFieldSize 2048 -Name vHBA-1-Fabric-B -NwTemplName vHBA-1-Fabric-B -Order 10 -PersBind disabled -PersBindClear no -StatsPolicyName default -SwitchId B
$mo_12 = $mo | Set-UcsServerPower -State admin-up -Force
Complete-UcsTransaction

# Boot Local #
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsServiceProfile -BiosProfileName esxi -BootPolicyName Boot-Local -Descr "" -ExtIPState pooled -HostFwPolicyName $host_fw -IdentPoolName Global-UUID-Pool -LocalDiskPolicyName Boot-Local -MaintPolicyName user-acknowledge -Name ESXi -PowerPolicyName no-power-cap -ScrubPolicyName no-scrub -StatsPolicyName default -Type updating-template -VconProfileName b200-b230
$mo_1 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-0-Fabric-A -NwTemplName vNIC-0-Fabric-A -Order 1 -StatsPolicyName default -SwitchId A
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-1-Fabric-B -NwTemplName vNIC-1-Fabric-B -Order 2 -StatsPolicyName default -SwitchId B
$mo_3 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-2-Fabric-A -NwTemplName vNIC-2-Fabric-A -Order 3 -StatsPolicyName default -SwitchId A
$mo_4 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-3-Fabric-B -NwTemplName vNIC-3-Fabric-B -Order 4 -StatsPolicyName default -SwitchId B
$mo_5 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-4-Fabric-A -NwTemplName vNIC-4-Fabric-A -Order 5 -StatsPolicyName default -SwitchId A
$mo_6 = $mo | Add-UcsVnic -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -Mtu 1500 -Name vNIC-5-Fabric-B -NwTemplName vNIC-5-Fabric-B -Order 6 -StatsPolicyName default -SwitchId B
$mo_7 = $mo | Add-UcsVnicFcNode -ModifyPresent -Addr pool-derived -IdentPoolName Global-WWNN-Pool
$mo_8 = $mo | Add-UcsVhba -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -MaxDataFieldSize 2048 -Name vHBA-0-Fabric-A -NwTemplName vHBA-0-Fabric-A -Order 9 -PersBind disabled -PersBindClear no -StatsPolicyName default -SwitchId A
$mo_9 = $mo | Add-UcsVhba -AdaptorProfileName VMWare -Addr derived -AdminVcon 1 -MaxDataFieldSize 2048 -Name vHBA-1-Fabric-B -NwTemplName vHBA-1-Fabric-B -Order 10 -PersBind disabled -PersBindClear no -StatsPolicyName default -SwitchId B
$mo_10 = $mo | Set-UcsServerPower -State admin-up -Force
Complete-UcsTransaction

#########################################
# Deploy Service Profiles from Template #
#########################################
# Boot From SAN #
Get-UcsServiceProfile -Name ESX-San-Boot -Org org-root | Add-UcsServiceProfileFromTemplate -Prefix $service_profile_name -Count $count -DestinationOrg org-root
# Boot Local #
Get-UcsServiceProfile -Name ESXi -Org org-root | Add-UcsServiceProfileFromTemplate -Prefix $service_profile_name -Count $count -DestinationOrg org-root
