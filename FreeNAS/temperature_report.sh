#! /usr/local/bin/sh

# Write email header to temp file
(
  echo "To: foo@bar.com"
  echo "Subject: FreeNAS Temperatures"
  echo " "
) > /var/cover

# Write some general information
echo System Temperatures - `date` >> /var/cover
cat /etc/version >> /var/cover
uptime | awk '{ print "\nSystem Load:",$10,$11,$12,"\n" }' >> /var/cover

# Write CPU temperatures
echo "CPU Temperature:" >> /var/cover
sysctl -a | egrep -E "cpu\.[0-9]+\.temp" >> /var/cover
echo >> /var/cover

# Write HDD temperatures and status
echo "HDD Temperature:" >> /var/cover
for i in $(sysctl -n kern.disks | awk '{for (i=NF; i!=0 ; i--) if(match($i, '/da/')) print $i }' )
do
echo \ $i: `smartctl -a /dev/$i | awk '/Temperature_Celsius/{DevTemp=$10;} /Serial Number:/{DevSerNum=$3}; /Device Model:/{DevVendor=$3} \
END {printf "%s C - %s (%s) ", DevTemp,DevVendor,DevSerNum }'` >> /var/cover;
done

# Send status email
sendmail -t < /var/cover
exit 0
