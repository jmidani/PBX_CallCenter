#!/bin/bash
# usage: make-survey-call.sh PHONE LANG AGENT CUSTID CALLID
PHONE=$(echo "$1" | tr -cd '0-9')
SLANG=$(echo "$2" | tr -cd 'a-z')
AGENT=$(echo "$3" | tr -cd '0-9')
CUSTID=$(echo "$4" | tr -cd '0-9')
CALLID=$(echo "$5" | tr -cd '0-9.')
F=/tmp/survey-$CALLID.call
cat > "$F" <<EOF
Channel: PJSIP/$PHONE
CallerID: "Bank" <8000>
MaxRetries: 1
RetryTime: 60
WaitTime: 30
Context: survey
Extension: s
Priority: 1
Setvar: SLANG=$SLANG
Setvar: AGENT=$AGENT
Setvar: CUSTID=$CUSTID
Setvar: CALLID=$CALLID
EOF
touch -d "@$(( $(date +%s) + 45 ))" "$F"
mv "$F" /var/spool/asterisk/outgoing/
