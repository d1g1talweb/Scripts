$cluster = Get-Cluster
$esx = Get-VMHost -Location $cluster
$stat = 'cpu.usage.average','mem.usage.average'
$start = (Get-Date).AddHours(-1)
 
$stats = Get-stat -Entity $esx -Stat $stat -Start $start -Instance ''
$stats | Group-Object -Property {$_.Entity.ExtensionData.Parent} | %{
    New-Object -TypeName PSObject -Property @{
        Cluster = Get-View -Id $_.Name -Property Name | Select -ExpandProperty Name
        Date = $start
        CPUAvg = $_.Group | where{$_.MetricId -eq 'cpu.usage.average'} | Measure-Object -Property Value -Average | Select -ExpandProperty Average
        MemAvg = $_.Group | where{$_.MetricId -eq 'mem.usage.average'} | Measure-Object -Property Value -Average | Select -ExpandProperty Average
    }
}