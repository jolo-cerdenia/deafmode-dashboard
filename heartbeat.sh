#!/bin/bash

# deafmode heartbeat emitter
# local VPS version

OUTPUT="/var/www/deafmo.de/dashboard/wakefulness.json"

while true
do

  NOW=$(date -Iseconds)

  cat > "$OUTPUT" <<EOF
{
  "last_seen": "$NOW"
}
EOF

  sleep 10

done
