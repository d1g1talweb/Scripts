$report = Get-Datacenter | % {   

      $datacenter=$_ 

      foreach($esx in Get-VMhost -Location $datacenter){ 

        $esxcli = Get-EsxCli -VMHost $esx 
		
		Get-VMHost $esx |

        Select @{N="Datacenter";E={$datacenter.Name}}, 
		
		       @{N="Cluster";E={ 

                    if($esx.ExtensionData.Parent.Type -ne "ClusterComputeResource"){"Stand alone host"} 

                    else{ 

						Get-VMHost $esx | Get-Cluster

                    }}}, 

                @{N="HostName";E={$esx.Name}}, 

                @{N="version";E={$esx.version}}, 
				
				@{N="Build";E={$esx.build}}, 

				@{N="FNIC_Version";E={$esxcli.software.vib.list() | ? {$_.Name -like "scsi-fnic"} | Select -First 1 -Expand Version}}, 
				
				@{N="ENIC_Version";E={$esxcli.software.vib.list() | ? {$_.Name -like "net-enic"} | Select -First 1 -Expand Version}},
				
				@{N="SATP Rule";E={$esxcli.storage.nmp.satp.rule.list() | where {$_.vendor -like "*XtremIO*"} | select -First 1 -Expand Vendor}},
				
				@{N="FNIC QD (128)";E={$esxcli.system.module.parameters.list("fnic") | where {$_.Name -eq "fnic_max_qdepth"} | select -Expand value}},

				@{N="DiskSchedQuantum (64)";E={get-AdvancedSetting -Entity $esx -Name "Disk.SchedQuantum" | Select -Expand Value}},
				
				@{N="MaxIOSize (4096)";E={get-AdvancedSetting -Entity $esx -Name "Disk.DiskMaxIOSize" | Select -Expand Value}},
				
				@{N="Round Robin";E={$esxcli.storage.nmp.satp.rule.list() | where {$_.vendor -like "*XtremIO*"} | select -First 1 -Expand DefaultPSP}},
				
				@{N="HBA IOPs";E={$esxcli.storage.nmp.satp.rule.list() | where {$_.vendor -like "*XtremIO*"} | select -First 1 -Expand PSPOptions}},
				
				@{N="ShellWarn (1)";E={get-AdvancedSetting -Entity $esx -Name "UserVars.SuppressShellWarning" | Select -Expand Value}},
				
				@{N="HTWarn (1)";E={get-AdvancedSetting -Entity $esx -Name "UserVars.SuppressHyperThreadWarning" | Select -Expand Value}},
				
				@{N="LicenseStatus";E={
				
					if($esx.licensekey -eq "00000-00000-00000-00000-00000"){"Evaluation"}
				
					else{"Licensed"}
				
					}}
				
      } 

}

$report | Export-Csv c:\vmware\report.csv -NoTypeInformation -UseCulture
