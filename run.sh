#!/bin/bash -e

FILE=/flexscada/devices.json
if [ ! -f "$FILE" ]; then
    echo "{
    \"accounts\": {
        \"$FS_ADMIN_KEY\": {
            \"admin\": true
        }
    },
    \"keys\": {
    }
}" > /flexscada/devices.json

fi



FILE=/flexscada/flexscada.json
if [ ! -f "$FILE" ]; then
    echo "{
\"port\" : \"7001\",
\"host\" : \"0.0.0.0\",
\"www_directory\" : \"www\",
\"log_directory\" : \"logs\",
\"log_level\" : 2,
\"device_database\" : \"devices.json\",
\"listener_port\" : 8001,
\"influxdb_remote\":\"http://localhost:8086\",
\"influxdb\": \"$FS_INFLUXDB_URL\",
\"influx_credentials\" : \"&u=root&p=$FS_ADMIN_KEY\",
\"grafana_url\":\"$FS_GRAFANA_URL\",
\"grafana_remote\":\"http://localhost:3000\",
\"grafana_admin_user\":\"admin\",
\"grafana_admin_password\":\"$FS_ADMIN_KEY\"
}" > /flexscada/flexscada.json

fi


FILE=/flexscada/www/app.js
if [ ! -f "$FILE" ]; then
cp /app.js /flexscada/www/app.js
fi

FILE=/flexscada/www/index.html
if [ ! -f "$FILE" ]; then
cp /index.html /flexscada/www/index.html
fi


flexscada_d flexscada.json
