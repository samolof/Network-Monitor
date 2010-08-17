#!/usr/bin/env bash
  dbase="monitor.db"
  function convert_to_sql_date(){
    mnth=${DATE[1]}
    case $mnth in
     "Jan") mm="01" ;;
     "Feb") mm="02" ;;
     "Mar") mm="03" ;;
     "Apr") mm="04" ;;
     "May") mm="05" ;;
     "Jun") mm="06" ;;
     "Jul") mm="07" ;;
     "Aug") mm="08" ;;
     "Sep") mm="09" ;;
     "Oct") mm="10" ;;
     "Nov") mm="11" ;;
     "Dec") mm="12" ;;
    esac
    yr=${DATE[5]}    
    dd=${DATE[2]}; 
    if [ $dd -le 10 ]; then dd="0${dd}" ; fi    
    hms=${DATE[3]}
    echo "${yr}-${mm}-${dd} ${hms}"
  }

  function do_results(){
    uptime=`echo "$RAWDATA" | awk '/Ihost.*'"$HOST"'/ {print $4}'`
    freemem=`echo "$RAWDATA" | awk '/Ihost.*'"$HOST"'/ {print $6}'`
    uptime="${uptime:--}"  
    freemem="${freemem:--}"
    printf "%-20s  %-15s  %-10s  " $HOST $uptime $freemem
    for port in ${args[@]}; do
      if [ $port -eq $port 2>/dev/null ];then
        open="${port}/open"
        close="${port}/close"
      else
       open="/open/[a-zA-Z]*//$port"
       close="/open/[a-zA-Z]*//$port"
      fi
      line=`echo "$RAWDATA" | grep -v "^[[:space:]]*#" | grep "$HOST"`
      echo $line | egrep -o "$open" >/dev/null
      if [ $? -eq 0 ];then
        printf "%-8s  " "YES"
      else
        echo $line | egrep "$port" >/dev/null
        if [ $? -eq 0 ]; then 
          printf "%-8s  " "NO"
        else
          printf "%-8s  " "NA"
        fi
      fi
    done
    printf "\n" 
  }
  #Check for cmd line args
  if [ ! $1 ];then
    echo "Usage: $0 port1 [port2] [port3] ..."
    echo "     : date [options] | $0 port1 [port2] [port3] ..."
    exit 0
  fi
  #Check if date command was piped in
  if ! [ -t 0 ]; then
    dt=`cat /dev/stdin`
    DATE=( $dt )
    sqldate="$(convert_to_sql_date)"
    RAWDATA=$(sqlite3 $dbase "select * from monitor where timestamp >= datetime('$sqldate');")
  else
    RAWDATA="$(sqlite3 $dbase 'select * from monitor;')"        
  fi
  printf "%-20s  %-15s  %-10s  " "HostIP" "Uptime" "Free Mem"
  for port in $*;do
    printf "%-8s  "  $port
  done
  printf "\n"
  args=( $* )
  hosts=`echo "$RAWDATA" |awk '/Host:/ {print $2}'`
  for HOST in $hosts; do
    do_results
  done

