#!/bin/bash

source sources/extra.sh

function show_help
{
  c_print "Green" "This script stores the IP addesses of the data communication interfaces with location+date information to keep track of them preciesly!"
  c_print "Bold" "Example: ./ip_addr_logger.sh [-a INTF1 -b INTF2 -s SLEEP_TIME] "
  c_print "Bold" "\t\t-a <INTF1>: set the primary interface name that is used to connect to the internet via mobile data communication (Default: intf1)."
  c_print "Bold" "\t\t-b <INTF2>: set the secondary interface name that is used to connect to the internet via mobile data communication (Default: intf2)."
  c_print "Bold" "\t\t-s <SLEEP_TIME>: sleep time IN SECONDS between two consecutive measurements. Cannot be less than 5 seconds (Default: 300)."
  c_print "None" "How to simply get these interfaces on a non-rooted phone? just use 'ip addr show' and look for the interfaces that have meaningful IP addresses"
  exit
}

intf1="rmnet_data0"
intf2="rmnet_data2"
sleep_time=300

while getopts "h?a:b:s:" opt
  do
    case "$opt" in
    h|\?)
      show_help
      ;;
    a)
      intf1=$OPTARG
      ;;
    b)
      intf2=$OPTARG
      ;;
    s)
      sleep_time=$OPTARG
      ;;
    *)
      show_help
      ;;
     esac
  done

if [[ $sleep_time -lt 5 ]]
then
  c_print "Red" "Sleep time cannot be less than 5 seconds" 
  exit -1
fi


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT


#graceful quit function that releases the termux lock and kills termux-location app
#that might still run in the background (it does not give results fast and if cancelled it stucks)
function quit () {
  c_print "Green" "Releasing wake lock..."
  termux-wake-unlock
  c_print "Bold" "[DONE]"
  pkill termux-location
  exit 0
  sleep 1
}


#subscribe to Ctrl+C event and handle it differently
function ctrl_c () {
  c_print "BYellow" "** Trapped CTRL-C"
  c_print "BYellow"  "|--Graceful exiting..."
  quit
}

c_print "Bold" "Starting IPv6 logger with GPS data..."

function check_connectivity () {
  termux-telephony-deviceinfo |grep "data_state" |grep "disconnected" > /dev/null
  retval=$(echo $?)
  if [[ $retval -eq 0 ]] #retval is 0 if grep had success
  then
#    echo "Device is disconnected"
    return 0
  else
#    echo "Device is connected to mobile data"
  return 1
  fi
}

function get_date () {
  d=$(date +"%d-%m-%y__%H%M")
  echo $d
}

c_print "Bold" "Acquiring wakelock to let the app and termux run in the background..."
termux-wake-lock

DATE=$(get_date)
LOG="ipv6-started-on-${DATE}.log"
CSV="ipv6-started-on-${DATE}.csv"

echo "date_start,date_end,ipv4_${intf1},ipv6_${intf1},ipv4_${intf2},ipv6_${intf2},latitude,longitude" > $CSV
count=0
while true
do
  check_connectivity #in bash we need to call a function first
  CONNECTED=$? #get return value of the last called function
  c_print "Bold" "Connected to data network: ${CONNECTED}"
  if [[ $CONNECTED -eq 1 ]]
  then
    counter=`expr $count + 1`
    c_print "None" "running data gathering..."
    #save date
    echo -e "---=== Measurement data ${count} ===---" |tee -a $LOG
    date_start=$(get_date)
    echo -e "${date_start}" |tee -a $LOG
    echo -e "|--IPv6 data" | tee -a $LOG
    ipv4_addr_intf1=$(ip addr show $intf1 |grep "inet " |grep "global" |awk '{print $2}')
    ipv6_addr_intf1=$(ip addr show $intf1 |grep "inet6" |grep "global" |awk '{print $2}')
    ipv4_addr_intf2=$(ip addr show $intf2 |grep "inet " |grep "global" |awk '{print $2}')
    ipv6_addr_intf2=$(ip addr show $intf2 |grep "inet6" |grep "global" |awk '{print $2}')
    echo -e "IPv4 ${intf1}: ${ipv4_addr_intf1}" |tee -a $LOG
    echo -e "IPv6 ${intf1}: ${ipv6_addr_intf1}" |tee -a $LOG
    echo -e "IPv4 ${intf2}: ${ipv4_addr_intf2}" |tee -a $LOG
    echo -e "IPv6 ${intf2}: ${ipv6_addr_intf2}" |tee -a $LOG
    echo -e "--------" |tee -a $LOG
    echo -e "|--Location data:" | tee -a $LOG
    termux-location |tee last_location.json  #tee -a $LOG
    latitude=$(cat last_location.json |jq .latitude)
    longitude=$(cat last_location.json |jq .longitude)
    echo -e "Lat: ${latitude}" | tee -a $LOG
    echo -e "Long: ${longitude}" | tee -a $LOG
    echo -e "--------" | tee -a $LOG
    echo -e "|--celldata" | tee -a $LOG
    termux-telephony-cellinfo | tee -a $LOG
    echo -e "---=======---" | tee -a $LOG
    date_end=$(get_date)
    echo -e "${date_end}" |tee -a $LOG
    echo "${date_start},${date_end},${ipv4_addr_intf1},${ipv6_addr_intf1},${ipv4_addr_intf2},${ipv6_addr_intf2},${latitude},${longitude}" |tee -a $CSV
  else
    c_print "Yellow"  "device is disconnected...let's skip this round..."
  fi

  sleep_update_time=$(echo $(($sleep_time/5)))
  c_print "None" "Sleeping " 1
  for i in `seq 1 $sleep_update_time $sleep_time`
  do
    c_print "Yellow" " . " 1
    sleep $sleep_update_time
  done
  c_print "None" "\n"
done



