# --- clear logs ---
@daily        /opt/clearlog.sh

#!/bin/bash
#Disk Space
disk=`du -ksh /var/www/ragchews/ | awk '{print $1}' |cut -d "G" -f1|head -1`
logpath='/var/www/ragchews/production/ragchews/logs/production'
logpath1='/var/www/ragchews/tigase/tigase-server-5.2.3-SNAPSHOT-b21-prod-2015-12-03-12-57/logs'
max_usage=4.9
if (( $(echo "$disk >= $max_usage" | bc -l) )); then
echo " Max size limit has been over, shell script is going to delete logs $disk "
cd $logpath
rm -rf *.log
cd $logpath1
rm -rf *.log
elif (( $(echo "$disk <= $max_usage" | bc -l) )); then
echo " Disk Space is Fine "
fi