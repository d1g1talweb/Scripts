###		UCS Firmware ESXi Upgrade Script   
### 	Bobby Anderson 12/13/2018
###
###		This script will execute the following on each host in "hostlist.txt" sequentially:
###		1. Enter maint mode and shut down host
###		2. Map host to UCS SP
###		3. Change UCS SP Template
###		4. Acknowledge blade maintenance
###		5. upgrade UCS FW
###		6. Attach VUM baselines
###		7. Upgrade ESXi and patch host
###		8. Exit maint mode
###
###		Add hosts to "hostlist.txt" in working directory
###		In UCSPowerTool - Log into each UCS Domain and run this command to export sessions: 
###		Export-UcsPsSession -Path .\ucs-sessions.xml -Key $(ConvertTo-SecureString -AsPlainText "password" -Force)

##########################################################################
########################   Import Modules    #############################
##########################################################################

	if ((Get-Module |where {$_.Name -ilike "CiscoUcsPS"}).Name -ine "CiscoUcsPS")
	{
	Write-Host "Loading Module: Cisco UCS PowerTool Module"
	Import-Module CiscoUcsPS
	}
	if ((Get-Module | where {$_.Name -ilike "Vmware*Core"}).Name -ine "VMware.VimAutomation.Core")
	{
	Write-Host "Loading PS Module: VMware VimAutomation Core"
	Import-Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue
	}
	if ((Get-Module | where {$_.Name -ilike "Vmware*"}).Name -ine "VMware.VumAutomation")
	{
	Write-Host "Loading PS Module: VMware.VumAutomation"
	Import-Module VMware.VumAutomation -ErrorAction SilentlyContinue
	}	
	if ((Get-Module | where {$_.Name -ilike "Vmware*Core"}).Name -ine "VMware.VimAutomation.Core")
	{
	Write-Host "Loading PS Module: VMware VimAutomation Core"
	Import-Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue
	}
	if ((Get-Module | where {$_.Name -ilike " VMware.DeployAutomation"}).Name -ine "VMware.DeployAutomation")
	{
	Write-Host "Loading PS Module: VMware VMware.DeployAutomation"
	Import-Module VMware.DeployAutomation -ErrorAction SilentlyContinue
	}
	if ((Get-Module | where {$_.Name -ilike "VMware.ImageBuilder"}).Name -ine "VMware.ImageBuilder")
	{
	Write-Host "Loading PS Module: VMware VMware.ImageBuilder"
	Import-Module VMware.ImageBuilder -ErrorAction SilentlyContinue
	}
	
##########################################################################	
########################     Variables     ###############################
##########################################################################	
	
	#Global Settings
	set-ucspowertoolconfiguration -supportmultipledefaultucs $true
	$WarningPreference = "SilentlyContinue"
	
	# Get UCS Info
	Write-Host "What UCS are you connecting to?"
	$ucs_session = Read-Host "qorb.xml or qorc.xml"
	$NewSPtemplate = "VDI-ESXi-3.2.3g"
	$ucsorg = "org-root"
	
	# Get VCenter Info
	$vCenter = Read-Host "What VCenter are you connecting to?"
	$vcuser = Read-Host "Enter VCenter Username"
	$vcpass = Read-Host "Enter VCenter Password"
	$hostlist = "hostlist.txt"

##########################################################################	
########################    Start Script   ###############################
##########################################################################

try {
	# Start Logging
	start-transcript ucs_fw_upgrade.txt
	
	# Login to UCS
	Write-Host "UCS: Logging into UCS"
	Connect-Ucs -Path $ucs_session -Key $(ConvertTo-SecureString -Force -AsPlainText "det00ber")
	
	# Login to VCenter
	Write-Host "vC: Logging into vCenter: $vCenter"
	$vcenterlogin = Connect-VIServer $vCenter -User $vcuser -Password $vcpass | Out-Null
	
	# Start Script
	foreach ($VMHost in (Get-VMHost -Name (Get-Content $hostlist))){
	
	# Host Enter Maintenance Mode
		Write-Host "vC: Setting $($VMHost.Name) into maintenance mode"
		$Maint = $VMHost | Set-VMHost -State Maintenance -Evacuate:$true
		
		Write-Host "vC: Waiting for $($VMHost.Name) to enter Maintenance Mode"
		do {
			Sleep 10
		} until ((Get-VMHost $VMHost).State -eq "Maintenance")
		
	# Get number of Physical NICs 
		Write-Host "vC: Getting Physical NIC Count"
		$no_nics = $VMHost | get-vmhostnetworkadapter -Physical
		Write-Host "vC: Host $($VMHost.Name) has $($no_nics.Count) vNICs"
		
	# vNIC Enumeration Warning
		if ($no_nics.count -eq '8')
		{
		$enumerate = "yes"
		#Continue
		}
		
	# Host Graceful Shut Down
		Write-Host "vC: $($VMHost.Name) now in Maintenance Mode, shutting down host"
		$Shutdown = $VMHost.ExtensionData.ShutdownHost($true)
	
	# Map ESX Host to UCS Service Profile
		Write-Host "UCS: Correlating $($VMHost.Name) to running UCS Service Profile"
		$vmMacAddr = $vmhost.NetworkInfo.PhysicalNic | where { $_.name -ieq "vmnic0" }
		$sp2upgrade =  Get-UcsServiceProfile | Get-UcsVnic -Name vNIC-0-Fabric-A |  where { $_.addr -ieq  $vmMacAddr.Mac } | Get-UcsParent 
		Write-Host "UCS: $($VMhost.Name) is running on UCS SP: $($sp2upgrade.name)"
		
	# Wait for Server power off 
		Write-Host "UCS: Waiting for UCS SP: $($sp2upgrade.name) to gracefully power down"
		do {
			if ((get-ucsmanagedobject -dn $sp2upgrade.PnDn).OperPower -eq "off")
			{
				break
			}
			Sleep 40
		} until ((get-ucsmanagedobject -dn $sp2upgrade.PnDn).OperPower -eq "off" )
		Write-Host "UCS: $($sp2upgrade.name) is powered down"
		
	# Set power state to down
		#Write-Host "UCS: Setting desired power state for UCS SP: $($sp2upgrade.name) to power down"
		#$poweron = $sp2upgrade | Set-UcsServerPower -State "down" -Force
		
	# Change Service Profile Template for new FW package
		Write-Host "UCS: Changing Service Profile Template for UCS SP: $($sp2upgrade.name) to $($NewSPtemplate)"
		$updatehfp = $sp2upgrade | Set-UcsServiceProfile -SrcTemplName $NewSPtemplate -Force
		
	# Acknowledge UCS Server for reboot to apply SP Template
		Write-Host "UCS: Acknowlodging any User Maintenance Actions for UCS SP: $($sp2upgrade.name)"
		if (($sp2upgrade | Get-UcsLsmaintAck | measure).Count -ge 1)
			{
				$ackuserack = $sp2upgrade | Get-UcsLsmaintAck | Set-UcsLsmaintAck -AdminState "trigger-immediate" -Force
			}
	
	# Wait for Upgrade to complete
		Write-Host "UCS: Waiting for UCS SP: $($sp2upgrade.name) to complete firmware update process"
		do {
			Sleep 40
		} until ((Get-UcsManagedObject -Dn $sp2upgrade.Dn).AssocState -ieq "associated")
		
	# Set power state to up
		#Write-Host "UCS: Host Firmware update process complete. Setting desired power state for UCS SP: $($sp2upgrade.name) to up"
		#$poweron = $sp2upgrade | Set-UcsServerPower -State "up" -Force
		
	# Wait for Host to boot and connect to VCenter
		Write-Host "vC: Waiting for $($VMHost.Name) to connect to vCenter"
		do {
			Sleep 40
		} until (($VMHost = Get-VMHost $VMHost).ConnectionState -eq "Maintenance" )

	# Create a Baseline Group from multiple baselines
		Write-Host "vC: Creating Baseline Group to Upgrade and Patch Host"
		$baseline = get-baseline | `
		Where {$_.name.contains("VDI 6.0u3 Update ESXi") `
		-or $_.name.contains("VDI 6.0u3 Update Cisco Drivers") `
		-or $_.name.contains("VDI 6.0u3 Update Critical Patches")}
	
    # Attach baseline host
		Write-Host "vC: Attaching Baseline Group to $($VMHost.Name)"
		Attach-Baseline -Entity $VMHost -Baseline $Baseline -ErrorAction stop
	
    # Test compliance against host
		Test-Compliance -Entity $VMHost -UpdateType HostPatch -Verbose -ErrorAction stop
	
	# Remediate VMHost
		Write-Host "vC: Remediating $($VMHost.Name)"
		$UpdateTask = Update-Entity -Baseline $baseline -Entity $vmhost -RunAsync -Confirm:$false -ErrorAction Stop
		Start-Sleep -Seconds 05
		
    # Wait for patch task to complete
		while ($UpdateTask.PercentComplete -ne 100)
		{
		Write-Progress -Activity "vC: Waiting for $($VMhost.Name) to finish patch installation" -PercentComplete $UpdateTask.PercentComplete
		Start-Sleep -seconds 10
		$UpdateTask = Get-Task -id $UpdateTask.id
		}
		
    # Check to see if remediation was sucessful
		if ($UpdateTask.State -eq 'Success')
		{
		Write-Host "vC: Host Patching for $($VMHost.Name) is complete"
		}
		if ($UpdateTask.State -ne 'Success')
		{
		Write-Warning "vC: Patch for $($VMHost.Name) was not successful"
		Read-Host 'Press enter to continue to next host or CTL+C to exit script'
		Continue
		}
		
    # Check to see if host is now in compliance
		$CurrentCompliance = Get-Compliance -Entity $VMHost -Baseline $Baseline -ErrorAction Stop
		if  ($CurrentCompliance.Status -ne 'Compliant')
		{
		Write-Warning "vC: $($VMHost.Name) is not compliant"
		Read-Host 'Press enter to continue to next host or CTL+C to exit script'
		Continue
		}
		Write-Host "vC: $($VMHost.Name) is now updated and patched"
		
	# Suppress Hyperthread Warning
		Write-Host "VC: Suppressing warning for HyperThreading"
		$KillWarning = Get-AdvancedSetting -Entity $VMHost -Name UserVars.SuppressHyperThreadWarning | Set-AdvancedSetting -Value '1' -Confirm:$false
		
	# Suppress SSH Warning
		Write-Host "VC: Suppressing warning for SSH Enabled"
		$KillSSHWarning = Get-AdvancedSetting -Entity $VMHost -Name UserVars.SuppressShellWarning | Set-AdvancedSetting -Value '1' -Confirm:$false
		
	# Set fnic Queue Depth to 128
		Write-Host "VC: Adjusting fnic Max Queue Depth to 128"
		$esxcli2 = $VMHost | get-esxcli -v2
		$args1 = $esxcli2.system.module.parameters.set.createArgs()
		$args1.parameterstring = "fnic_max_qdepth=128"
		$args1.module = "fnic"
		$esxcli2.system.module.parameters.set.invoke($args1)
		
	# Set Advanced Storage Parameters
		Write-Host "VC: Setting Disck Scheduled Quantum to 64"
		$SchedQuantum = get-AdvancedSetting -Entity $VMHost -Name "Disk.SchedQuantum" | Set-AdvancedSetting -Value "64" -Confirm:$false
		Write-Host "VC: Setting Disk Max IO Size to 4096"
		$DiskMaxIO = get-AdvancedSetting -Entity $VMHost -Name "Disk.DiskMaxIOSize" | Set-AdvancedSetting -Value "4096" -Confirm:$false
		
	# Checking for correct multipathing SATP rules
		Write-Host "VC: Checking for XtremIO SATP Rule"
		$esxcli = $VMHost | get-esxcli
		$SATPRules = $esxcli.storage.nmp.satp.rule.list() | where {$_.description -like "*XtremIO*"}
		if ($SATPRules.Count -ge 1)
		{
		Write-Host "vC: XtremIO SATP Rule Already Exists - Skipping"
		}
		if ($SATPRules.Count -eq 0)
		{
		Write-Host "VC: Setting XtremIO SATP Rule to Round Robin - IOPs=1"
		$XIOrrIOPs = $esxcli.storage.nmp.satp.rule.add($null,"tpgs_off","XtremIO Active/Active",$null,$null,$null,"XtremApp",$null,"VMW_PSP_RR","iops=1","VMW_SATP_DEFAULT_AA",$null,"vendor","XtremIO")
		}
		
	# vNIC Enumeration Warning
		if ($enumerate -eq 'yes')
		{
		Write-Host "################################################"
		Write-Host "Host $($VMHost.Name) Number of vNICs has changed"
		Write-Host "################################################"
		Read-Host 'Please manually re-enumerate vNICs and press ENTER to continue'
		Continue
		}
	
	# Host exit Maintenance Mode	
		Write-Host "vC: $($VMHost.Name) exiting Maintenance Mode"
			Sleep 40
		$NoMaint = $VMHost | Set-VMHost -State Connected
	}
	
	# Logout of UCS
		Write-Host "UCS: Logging out of UCS"
		$ucslogout = Disconnect-Ucs 

	# Logout of vCenter
		Write-Host "vC: Logging out of vCenter: $vCenter"
		$vcenterlogout = Disconnect-VIServer $vCenter -Confirm:$false
	
	# Complete
		Write-Host "Script: UCS Firmware Upgrade Complete"
}
Catch 
{
	 Write-Host "Error occurred in script:"
	 Write-Host ${Error}
     pause
}