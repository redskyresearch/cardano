#!/bin/bash
# daily-check script for cardano nodes
# REDSKY RESEARCH (c)

#initialize 
filepath="/home/ec2-user/.local/bin/daily-check"
outputfile="output.out"
email=`cat $filepath/emailid`
notifyByEmail=1
currdate=$(date '+%m/%d/%Y %H:%M:%S');
echo "" >> $filepath/$outputfile
echo "###########################" > $filepath/$outputfile
echo "REDSKY RESEARCH" >> $filepath/$outputfile
echo "$currdate" >> $filepath/$outputfile
echo "Cello @ MAINNET" >> $filepath/$outputfile
echo "Executing script as $USER" >> $filepath/$outputfile
echo "###########################" >> $filepath/$outputfile

# first check if updates are availeable
echo "" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile
echo "checking for OS updates" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile
updatescount=`yum list updates | wc -l` 
if [ $updatescount = 1 ]
then
	echo "Up to date. No updates necessary." >> $filepath/$outputfile
else
	echo $updatescount " updates are pending!" >> $filepath/$outputfile
fi
	
# get the system info needed for the checks
echo "" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile
echo "Instance Info" >> $filepath/$outputfile
echo "[load avg must be < 1.0]" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile
#get the number of cpu cores to check the load average
cpucores=( `grep MHz /proc/cpuinfo | wc -l` )
echo "CPU Cores = " $cpucores >> $filepath/$outputfile
loadaverage=$(uptime | awk -F "load average: " '{print $2}' | awk -F"," '{print $2}')
echo "Load Average = " $loadaverage >> $filepath/$outputfile
uptime=`uptime | awk '{print $3 " " $4}'`
echo "Instance uptime = " $uptime >> $filepath/$outputfile 
diskusage=`df -h /dev/xvda1 | awk '{ print $5 }'`
echo "Disk used:" $diskusage >> $filepath/$outputfile 
diskavailable=`df -h /dev/xvda1 | awk '{ print $4 }'`
echo "Disk space:" $diskavailable >> $filepath/$outputfile 
freemem=`free -m | awk '{ print $6}'`
echo "Memory [in MB]:" $freemem >> $filepath/$outputfile 

#check the cardano-node
echo "" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile
echo "Cardano Node Info" >> $filepath/$outputfile
echo "-----------------------" >> $filepath/$outputfile

export PATH="~/.local/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

numberofnodeinstances=$( pgrep -c cardano-node )
if [ $numberofnodeinstances = "0" ]
then
	echo "Severe Warning! - cardano-node is not running!" >> $filepath/$outputfile
else
	echo "# of instances running = " $numberofnodeinstances >> $filepath/$outputfile
fi

export CARDANO_NODE_SOCKET_PATH=/home/ec2-user/.local/bin/block-one/db/node.socket

mainnettip=`cardano-cli query tip --mainnet  | sed -n '2p' | xargs`
echo "Mainnet Tip: " $mainnettip >> $filepath/$outputfile

slotnumber=`cardano-cli query tip --mainnet  | sed -n '4p' | xargs`
echo "Slot Number: " $slotnumber >> $filepath/$outputfile

nodestatus=`sudo systemctl status startBlockProducerNode.service  | sed -n '3p' | xargs`
echo "Node Status: " $nodestatus >> $filepath/$outputfile

#notify by email
if [ $notifyByEmail = 1 ]
then
	mail -v -s "Cello Health Report - $currdate" "$email" < $filepath/$outputfile
else
	cat $filepath/$outputfile
fi

