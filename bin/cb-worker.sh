#!/bin/bash
# cb-worker.sh - starts a callback when a teller is free
OUT=/var/spool/asterisk/outgoing
q() { mariadb bank -N -e "$1"; }

pass() {
  for id in $(q "SELECT id FROM callbacks WHERE status='calling'"); do
    if [ ! -e "$OUT/cb-$id.call" ]; then
      q "UPDATE callbacks SET status='failed', completed_at=NOW() WHERE id=$id AND status='calling'"
    fi
  done
  row=$(q "SELECT id,number,queue_name,language,customer_id FROM callbacks WHERE status='pending' ORDER BY id LIMIT 1")
  [ -z "$row" ] && return
  read -r id num qn lang cust <<< "$row"
  id=$(echo "$id" | tr -cd '0-9')
  num=$(echo "$num" | tr -cd '0-9')
  qn=$(echo "$qn" | tr -cd 'a-z')
  lang=$(echo "$lang" | tr -cd 'a-z')
  cust=$(echo "$cust" | tr -cd '0-9')
  if [ -z "$FORCE" ]; then
    ready=$(asterisk -rx "queue show $qn" | grep -c "(Not in use)")
    busy=$(q "SELECT COUNT(*) FROM callbacks WHERE queue_name='$qn' AND status IN ('calling','answered')")
    [ "$ready" -le "$busy" ] && return
  fi
  printf '%s\n' "Channel: PJSIP/$num" 'CallerID: "Bank" <8000>' "MaxRetries: 2" "RetryTime: 60" "WaitTime: 30" "Context: cb-answer" "Extension: s" "Priority: 1" "Setvar: CBID=$id" "Setvar: QNAME=$qn" "Setvar: SLANG=$lang" "Setvar: CUST_ID=$cust" > /tmp/cb-$id.call
  q "UPDATE callbacks SET status='calling' WHERE id=$id"
  mv /tmp/cb-$id.call $OUT/cb-$id.call
}

while true; do
  pass
  [ -n "$ONCE" ] && break
  sleep 10
done
