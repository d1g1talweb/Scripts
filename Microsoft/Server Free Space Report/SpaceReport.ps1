# Set These Variables
$users = "user@domain.com", "user2@domain.com"; 
$reportHeader = "DiskSpace Report"
$smtpServer = "smtp.domain.com"
$smtpFrom = "from@domain.com"
$smtpSubject = "Environment DiskSpace Report"

####################################### Do not change anything below #######################################

# Set your warning and critical thresholds 
$percentNormal = 99; 
$percentWarning = 20;
$percentCritcal = 10; 

# Report Path
$reportPath = "Reports\";
# Report name 
$reportName = "DiskSpaceRpt_$(get-date -format ddMMyyyy).html"; 
 
# Path and Report name together 
$diskReport = $reportPath + $reportName 
 
#Set colors for table cell backgrounds 
$redColor = "#FF0000" 
$orangeColor = "#FBB917" 
$whiteColor = "#FFFFFF" 
$greenColor = "#00CC00"
 
# Count if any computers have low disk space.  Do not send report if less than 1. 
$i = 0; 
 
# Get computer list to check disk space 
$computers = Get-Content "servers.txt"; 
$datetime = Get-Date -Format "MM-dd-yyyy_HHmmss"; 
 
# Remove the report if it has already been run today so it does not append to the existing report 
If (Test-Path $diskReport) 
    { 
        Remove-Item $diskReport 
    } 
 
# Cleanup old files.. 
$Daysback = "-7" 
$CurrentDate = Get-Date; 
$DateToDelete = $CurrentDate.AddDays($Daysback); 
Get-ChildItem $reportPath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item; 
 
# Create and write HTML Header of report 
$titleDate = get-date -uformat "%m-%d-%Y - %A" 
$header = " 
  <html> 
  <head> 
  <meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'> 
  <title>DiskSpace Report</title> 
  <STYLE TYPE='text/css'> 
  <!-- 
  td { 
   font-family: Tahoma; 
   font-size: 11px; 
   border-top: 1px solid #999999; 
   border-right: 1px solid #999999; 
   border-bottom: 1px solid #999999; 
   border-left: 1px solid #999999; 
   padding-top: 0px; 
   padding-right: 0px; 
   padding-bottom: 0px; 
   padding-left: 0px; 
  } 
  body { 
   margin-left: 5px; 
   margin-top: 5px; 
   margin-right: 0px; 
   margin-bottom: 10px; 
   table { 
   border: thin solid #000000; 
  } 
  --> 
  </style> 
  </head> 
  <body> 
  <table width='100%'> 
  <tr bgcolor='#CCCCCC'> 
  <td colspan='7' height='25' align='center'> 
  <font face='tahoma' color='#003399' size='4'><strong>$reportHeader $titledate</strong></font> 
  </td> 
  </tr> 
  </table> 
" 
 Add-Content $diskReport $header 
 
# Create and write Table header for report 
 $tableHeader = " 
 <table width='100%'><tbody> 
 <tr bgcolor=#CCCCCC> 
    <td width='10%' align='center'>Server</td> 
 <td width='5%' align='center'>Drive</td> 
 <td width='15%' align='center'>Drive Label</td> 
 <td width='10%' align='center'>Total Capacity(GB)</td> 
 <td width='10%' align='center'>Used Capacity(GB)</td> 
 <td width='10%' align='center'>Free Space(GB)</td> 
 <td width='5%' align='center'>Freespace %</td> 
 </tr> 
" 
Add-Content $diskReport $tableHeader 
  
# Start processing disk space reports against a list of servers 
  foreach($computer in $computers) 
 {  
 $disks = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk -Filter "DriveType = 3" 
 $computer = $computer.toupper() 
  foreach($disk in $disks) 
 {         
  $deviceID = $disk.DeviceID; 
        $volName = $disk.VolumeName; 
  [float]$size = $disk.Size; 
  [float]$freespace = $disk.FreeSpace;  
  $percentFree = [Math]::Round(($freespace / $size) * 100, 2); 
  $sizeGB = [Math]::Round($size / 1073741824, 2); 
  $freeSpaceGB = [Math]::Round($freespace / 1073741824, 2); 
        $usedSpaceGB = $sizeGB - $freeSpaceGB; 
        $color = $whiteColor; 
 
# Set background color to Orange if just a warning 
 if($percentFree -lt $percentNormal)       
  { 
    $color = $greenColor   
      if($percentFree -lt $percentWarning) 
        { 
        $color = $orangeColor 
		if($percentFree -lt $percentCritical)       
  {
    $color = $redColor
       }         
  }
  
 # Create table data rows  
    $dataRow = " 
  <tr> 
        <td width='10%'>$computer</td> 
  <td width='5%' align='center'>$deviceID</td> 
  <td width='15%' >$volName</td> 
  <td width='10%' align='center'>$sizeGB</td> 
  <td width='10%' align='center'>$usedSpaceGB</td> 
  <td width='10%' align='center'>$freeSpaceGB</td> 
  <td width='5%' bgcolor=`'$color`' align='center'>$percentFree</td> 
  </tr> 
" 
Add-Content $diskReport $dataRow; 
Write-Host -ForegroundColor DarkYellow "$computer $deviceID percentage free space = $percentFree"; 
    $i++   
  } 
 } 
} 

# Create table at end of report showing legend of colors for the critical and warning 
 $tableDescription = " 
 </table><br><table width='20%'> 
 <tr bgcolor='White'> 
    <td width='10%' align='center' bgcolor='#00CC00'>Normal free space</td> 
	<td width='10%' align='center' bgcolor='#FBB917'>Warning less than 20% free space</td>
 </tr> 
" 
  Add-Content $diskReport $tableDescription 
 Add-Content $diskReport "</body></html>" 
 
# Send Notification if alert $i is greater then 0 
if ($i -gt 0) 
{ 
    foreach ($user in $users) 
{ 
        Write-Host "Sending Email notification to $user" 
 
  $smtp = New-Object Net.Mail.SmtpClient($smtpServer) 
  $msg = New-Object Net.Mail.MailMessage 
  $msg.To.Add($user) 
        $msg.From = $smtpFrom 
  $msg.Subject = "$smtpSubject $titledate"
        $msg.IsBodyHTML = $true 
        $msg.Body = get-content $diskReport 
  $smtp.Send($msg) 
        $body = "" 
    } 
  } 