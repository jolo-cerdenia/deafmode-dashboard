#!/bin/bash

# deafmode heartbeat emitter
# updates wakefulness.json every 5 minutes

OUTPUT="$HOME/wakefulness.json"

while true
do

  NOW=$(date -Iseconds)

  cat > "$OUTPUT" <<EOF
{
  "last_seen": "$NOW"
}
EOF

  scp "$OUTPUT" deafmode@deafmo.de:/var/www/deafmo.de/dashboard/wakefulness.json

  sleep 300

done
