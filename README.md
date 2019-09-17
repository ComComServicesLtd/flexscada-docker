# flexscada-docker
FlexSCADA Daemon Docker Container


build with docker build -t flexscada .




Install The FlexSCADA Daemon, Grafana and Influxdb with the below script.

This will create a folder

<Home User>/flexscada
                     /grafana (All grafana data stored here)
                     /influxdb (All InfluxDB data stored here)
                     /flexscada (All FlexSCADA Daemon data stored here)
    
When it is first run it will generate a random password and place in ~/flexscada/key.txt
this key is used as the InfluxDB root password, the grafana admin password and the flexscada daemon admin user
API key.

After running the below script you should be able to open your web browser to http://localhost:3000 to access your grafana installation.

The first thing you will want to do after installing grafana is activate the flexSCADA plugin. This is done from the grafana web interface and is the same as any other plugin.

Initially you will be using the adming account on grafana, you will need to setup a client account before you can start adding flexSCADA devices.

Do this by going to the FlexSCADA menu > Create Client Account and fill out the form for creating a new client account

Creating a new client account will create a new influxDB and Grafana user which can be used to manage FlexSCADA devices.


If you want to install additional plugins they can be copied into the ~/flexscada/grafana/plugins directory. If you do this dont forget to restart the docker container

```console
sudo docker stop fs_grafana
sudo docker start fs_grafana
```
Influxdb can also be stopped and started the same way

```console
sudo docker stop fs_grafana
sudo docker start fs_grafana
```
And the FlexSCADA daemon

```console
sudo docker stop fs_flexscada
sudo docker start fs_flexscada
```
Application output can be seen by the following commands,very useful for troubleshooting

```console
sudo docker attach  fs_flexscada
sudo docker attach  fs_influxdb
sudo docker attach  fs_grafana
```
View application status

```console
sudo docker ps -a
```

If you are running a reverse proxy to put grafana behind a high level url on your domain e.g. <domain.com>/cloud
you will need to change the root url on grafana in the script below. The default for GRAFANA_ROOT is http://localhost:3000

If you want to use email notifications you will have to also add the relevant confguration overrides to the docker start commands for grafana.

See https://grafana.com/docs/installation/docker/ for more information.




## Reinstalling / Updating

Manually update each of your plugins in the plugins directory. If they were sourced from github (All of the included plugins)
just do a git pull inside each plugin directoy
then just run the script below again to update all of the docker containers.  Your data and configurations should not be lost since they are stored in seperate volumes outside the docker containers.







```console
#!/bin/bash
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

sudo docker stop fs_influxdb
sudo docker rm fs_influxdb
sudo docker run --net flexscada_network --ip $influxdb_host --restart always -p 8086:8086 -d -p 8083:8083 \
    --name=fs_influxdb \
      -e INFLUXDB_HTTP_AUTH_ENABLED -e INFLUXDB_ADMIN_ENABLED=true \
      -e INFLUXDB_ADMIN_USER=admin -e INFLUXDB_ADMIN_PASSWORD=$PASSWORD \
      -v ~/flexscada/influxdb:/var/lib/influxdb \
      influxdb:latest


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
    grafana/grafana:latest



    
sudo docker stop fs_flexscada
sudo docker rm fs_flexscada

sudo docker run -d --net flexscada_network --ip $flexscada_d_host -p 7001:7001 --name fs_flexscada --user $ID --restart always \
 -v ~/flexscada/flexscada:/flexscada \
 -e FS_ADMIN_KEY=$PASSWORD \
 -e FS_GRAFANA_URL=$grafana_host \
 -e FS_INFLUXDB_URL=$influxdb_host \
 -i -t comcomservices/flexscada:latest

```







To start the Docker daemon at boot, run:

```console
rc-update add docker boot
```
