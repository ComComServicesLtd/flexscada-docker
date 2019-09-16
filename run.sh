#!/bin/bash -e

FILE=/flexscada/devices.json
if [ ! -f "$FILE" ]; then
    echo "{
    \"accounts\": {
        \"$FS_ADMIN_KEY\": {
            \"admin\": true
        }
    },
    \"devices\": {
    },
    \"firmwares\": {
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
\"device_database\" : \"devices.json\",
\"listener_port\" : 8001,
\"influxdb\": \"$FS_INFLUXDB_URL\",
\"influx_credentials\" : \"&u=root&p=$FS_ADMIN_KEY\",
\"grafana_url\":\"$FS_GRAFANA_URL\",
\"grafana_admin_user\":\"admin\",
\"grafana_admin_password\":\"$FS_ADMIN_KEY\"
}" > /flexscada/flexscada.json

fi


flexscada_d flexscada.json
