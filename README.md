# flexscada-docker
FlexSCADA Docker Container


build with docker build -t flexscada













Install The FlexSCADA Daemon, Grafana and Influxdb with the below script



```console
mkdir ~/flexscada
cd ~/flexscada


sudo docker network create --subnet=172.18.0.0/16 flexscada_network

influxdb_host="172.18.0.20"
grafana_host="172.18.0.21"
flexscada_d_host="172.18.0.22"


ID=$(id -u) # saves your user id in the ID variable

mkdir ~/flexscada/influxdb

FILE=~/flexscada/key.txt
if [ ! -f "$FILE" ]; then
    echo "$FILE does not exist, Creating new random key for influxdb and flexscada daemon"
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c20 > key.txt
fi

PASSWORD=`cat ~/flexscada/key.txt`
GRAFANA_ROOT="http://localhost:3000"

#override random password with below line
#PASSWORD=myrandompassword

sudo docker rm fs_influxdb
sudo docker run --net flexscada_network --ip $influxdb_host --user $ID --restart always -p 8086:8086 -d -p 8083:8083 \
    --name=fs_influxdb \
      -e INFLUXDB_HTTP_AUTH_ENABLED -e INFLUXDB_ADMIN_ENABLED=true \
      -e INFLUXDB_ADMIN_USER=admin -e INFLUXDB_ADMIN_PASSWORD=$PASSWORD \
      -v ~/flexscada/influxdb:/var/lib/influxdb \
      influxdb


mkdir ~/flexscada/grafana
mkdir ~/flexscada/grafana/plugins
mkdir ~/flexscada/grafana/logs
mkdir ~/flexscada/grafana/conf

cd ~/flexscada/grafana/plugins
git clone https://github.com/comcomservices/FlexSCADA-Grafana-Map-Panel.git
git clone https://github.com/ComComServicesLtd/flexscada-grafana-app.git

current_host="127.0.0.1"
sed -i -e 's/'"$current_host"'/'"$flexscada_d_host"'/g' ~/flexscada/grafana/plugins/flexscada-grafana-app/dist/plugin.json 


sudo docker stop fs_grafana
sudo docker rm fs_grafana


sudo docker run -d --net flexscada_network --ip $grafana_host --restart always --user $ID -p 3000:3000 \
    --name=fs_grafana \
  -e GF_SERVER_ROOT_URL=$GRAFANA_ROOT \
  -e GF_SECURITY_ADMIN_PASSWORD=$PASSWORD \
  -e GF_PATHS_LOGS=/var/lib/grafana/logs \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel" \
  -v ~/flexscada/grafana:/var/lib/grafana \
    grafana/grafana



    
sudo docker stop fs_flexscada
sudo docker rm fs_flexscada

sudo docker run -d --net flexscada_network --ip $flexscada_d_host -p 7001:7001 --name fs_flexscada --user $ID --restart always \
 -v ~/flexscada/flexscada:/flexscada \
 -e FS_ADMIN_KEY=$PASSWORD \
 -e FS_GRAFANA_URL=$grafana_host \
 -e FS_INFLUXDB_URL=$influxdb_host \
 -i -t flexscada
```







To start the Docker daemon at boot, run:

```console
rc-update add docker boot
```
