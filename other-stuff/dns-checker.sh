#!/usr/bin/env bash
set -u

FILE=$1
NMAP_REPORT=$2
REPORTED_ALIVE=()
declare -A ALL_RECORDS=()

function reported_alive() {
  while IFS=$'\n' read -r; do
    if [[ "$REPLY" =~ ^Host ]]; then
      REPORTED_ALIVE+=( $(cut -d' ' -f2 <(echo $REPLY)) )
    fi
  done < $NMAP_REPORT

  echo "Reported Alive: ${REPORTED_ALIVE[@]}"
}

function get_A_records() {
  while IFS=$'\n' read -r; do
    LINE=$(grep '\<IN\>[[:space:]]\+\<A\>' <(echo $REPLY))
    if [[ -n "$LINE" ]]; then
      hostname=$(cut -d' ' -f1 <(echo $LINE))
      ip=$(cut -d' ' -f4 <(echo $LINE))
      ALL_RECORDS+=([$hostname]+=$ip)
    fi
  done <$FILE

  printf "%s\n" "----------------------------------"
  printf "%-18s %-18s\n" "Domain Name" "IP Address"
  printf "%s\n" "=================================="
  for i in ${!ALL_RECORDS[@]}; do
    #echo "host:$i -- ip:${ALL_RECORDS[$i]}"
    printf "%-18s %-18s\n" "$i" "${ALL_RECORDS[$i]}"
  done
}

reported_alive
get_A_records


if [[ $# -ne 1 ]]; then
  echo "Please supply IP address"
  exit 1
fi

SCRIPT="$HOME/bin/mac-address-lookup.sh"
MYUSER=
IP=

if [[ $(grep -F '@' <(echo $1)) ]]; then
  MYUSER=${1%%@*}
  IP=${1##*@}
else
  : ${IP:=$1}
  : ${MYUSER:=$USER}
fi

function report(){
  echo "User: $MYUSER"
  echo "IP: $IP"
  HOMEDIR=$(ssh $MYUSER@$IP "getent passwd $MYUSER | cut -d':' -f6")
  scp $SCRIPT $MYUSER@$IP:$HOMEDIR
  ssh $MYUSER@$IP "$HOMEDIR/$(basename $SCRIPT) > $HOMEDIR/report.txt && echo Success || echo Failure"
}

report

