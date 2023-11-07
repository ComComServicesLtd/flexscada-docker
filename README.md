# flexscada-docker
FlexSCADA Daemon Docker Container Source
build with docker build -t flexscada .



# Installing the FlexSCADA Cloud Suite



Install The FlexSCADA Daemon, Grafana and Influxdb with the below script. You do not need to build the docker image since it is already submitted to the dockerhub. Simply run the script at the bottom of the page.

The installation script will create a folder

<Home User>/flexscada
                     /grafana (All grafana data stored here)
                     /influxdb (All InfluxDB data stored here)
                     /flexscada (All FlexSCADA Daemon data stored here)
    
When it is first run it will generate a random password and place in ~/flexscada/key.txt
this key is used as the InfluxDB root password, the grafana admin password and the flexscada daemon admin user
API key.

After running the below script you should be able to open your web browser to http://localhost:3000 to access your grafana installation.

The first thing you will want to do after installing grafana is activate the flexSCADA plugin. This is done from the grafana web interface and is the same as any other plugin.   Use the key found in key.txt to activate the plugin.

Initially you will be using the admin account on grafana, you will need to setup a client account before you can start adding flexSCADA devices.

Do this by going to the FlexSCADA menu > Plugin Config and fill out the form for creating a new client account

Creating a new client account will create a new influxDB and Grafana user which can be used to manage FlexSCADA devices.

If you want to install additional plugins they can be copied into the ~/flexscada/grafana/plugins directory. If you do this dont forget to restart the docker container

```console
sudo docker stop fs_grafana
sudo docker start fs_grafana
or
sudo docker restart fs_grafana
```
Influxdb and the felxscada daemon can also be stopped and started the same way by changing the container name to fs_grafana and fs_flexscada

Application debug output can be viewed by the following commands,very useful for troubleshooting

```console
sudo docker attach  fs_flexscada
sudo docker attach  fs_influxdb
sudo docker attach  fs_grafana
```
View all application status

```console
sudo docker ps -a
```


Logs for the Database, Daemon and Grafana can be accesesd through the docker log tool

```console
sudo docker logs --tail 100 --follow fs_flexscada
sudo docker logs --tail 100 --follow fs_influxdb
sudo docker logs --tail 100 --follow fs_grafana
```



If you are running a reverse proxy to put grafana behind a high level url on your domain e.g. <domain.com>/cloud
you will need to change the root url on grafana in the script below. The default for GRAFANA_ROOT is http://localhost:3000
You will also need to reverse proxy /plugins and /dashborad as below since there are some hard links there in the flexscada app plugin

example nginx reverse proxy for accessing the grafana at /cloud, this is especially useful for shielding grafana behind https

```
location /cloud/ {
   proxy_pass http://localhost:3000/;
  }

  location /dashboard/ {
   proxy_pass http://localhost:3000/dashboard/;
  }



  location /plugins/ {
   proxy_pass http://localhost:3000/plugins/;
  }
  ```


If you want to use email notifications you will have to also add the relevant confguration overrides to the docker start commands for ana.

See https://grafana.com/docs/installation/docker/ for more information.




## Reinstalling / Updating

Just run the script below again to update all of the docker containers.  Your data and configurations should not be lost since they are stored in seperate volumes outside the docker containers.






## Install Script

Tested on Ubuntu Linux. Requires Docker and Git be installed

*   Copy the below script into a file called fs_install.sh on your local machine
*   Modify the fs_install.sh file and adjust the rootDir variable to match your desired install path.
*   Make any custom modifications as needed for your system (ports, url's etc)
*   chmod +x ./fs_install.sh
*   sudo ./fs_install.sh


install script

```console
#!/bin/bash -e
rootDir="/home/administrator/flexscada"

influxdb_ip="172.18.0.20"
grafana_ip="172.18.0.21"
flexscada_ip="172.18.0.22"

cfg_influxdb="true"
cfg_grafana="true"
cfg_flexscada="true"

GRAFANA_ROOT="http://localhost:3000"


mkdir -p $rootDir
cd $rootDir

sudo docker network create --subnet=172.18.0.0/16 flexscada_network || true


ID=$(id -u) # saves your user id in the ID variable

mkdir -p $rootDir/influxdb

FILE=$rootDir/key.txt
if [ ! -f "$FILE" ]; then
    echo "$FILE does not exist, Creating new random key for influxdb and flexscada daemon"
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c20 > key.txt
fi

PASSWORD=`cat $rootDir/key.txt`

#override random password with below line
#PASSWORD=myrandompassword


if $cfg_influxdb; then

echo "Deploying Influxdb Docker Image.."

sudo docker stop fs_influxdb || true
sudo docker rm fs_influxdb || true
sudo docker pull influxdb:1.8.10 || true

sudo docker run --net flexscada_network --ip $influxdb_ip --restart always -d \
    --name=fs_influxdb -p 8086:8086 --log-opt max-size=10m --log-opt max-file=5 \
      -e INFLUXDB_HTTP_AUTH_ENABLED -e INFLUXDB_ADMIN_ENABLED=true \
      -e INFLUXDB_ADMIN_USER=admin -e INFLUXDB_ADMIN_PASSWORD=$PASSWORD \
      -e INFLUXDB_HTTP_BIND_ADDRESS=:8086 \
      -e INFLUXDB_DATA_MAX_CONCURRENT_COMPACTIONS=4 \
      -e INFLUXDB_DATA_TSM_USE_MADV_WILLNEED=true \
      -e INFLUXDB_DATA_WAL_FSYNC_DELAY=100ms \
      -e GOMAXPROCS=8 \
      -e INFLUXDB_HTTP_LOG_ENABLED=false \
      -v $rootDir/influxdb:/var/lib/influxdb \
      influxdb:1.8.10

fi

if $cfg_grafana; then
echo "Deploying Grafana Plugins..."
      
mkdir -p $rootDir/grafana
mkdir -p $rootDir/grafana/plugins
mkdir -p $rootDir/grafana/logs
mkdir -p $rootDir/grafana/conf

cd $rootDir/grafana/plugins
git clone https://github.com/comcomservices/FlexSCADA-Grafana-Map-Panel.git || true
git clone https://github.com/ComComServicesLtd/flexscada-grafana-app.git || true


current_host="127.0.0.1"
sudo sed -i -e 's/'"$current_host"'/'"$flexscada_ip"'/g' $rootDir/grafana/plugins/flexscada-grafana-app/dist/plugin.json 


echo "Deploying Grafana Docker Image.."


sudo docker stop fs_grafana || true
sudo docker rm fs_grafana || true
sudo docker pull grafana/grafana-oss:10.2.0 || true

sudo chmod -R 777 $rootDir/grafana
sudo chown -R 472:472 $rootDir/grafana

sudo docker run -d --net flexscada_network --ip $grafana_ip --restart always --user 472 -p 3000:3000 \
    --name=fs_grafana --log-opt max-size=10m --log-opt max-file=5 \
  -e GF_SECURITY_ADMIN_PASSWORD=$PASSWORD \
  -e GF_PATHS_LOGS=/var/lib/grafana/logs \
  -e GF_USERS_AUTO_ASSIGN_ORG=true \
  -e GF_USERS_AUTO_ASSIGN_ORG_ROLE=Admin \
  -e "GF_SERVER_SERVE_FROM_SUB_PATH=true" \
  -e "GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS=flexscada,q5-data-editor,flexscada-map-panel" \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel" \
  -e GF_SERVER_ROOT_URL=$GRAFANA_ROOT \
  -e "GF_SERVER_ENABLE_GZIP=true" \
  -e "GF_SECURITY_DISABLE_GRAVATAR=true" \
  -e "GF_CONTENT_SECURITY_POLICY=false" \
  -e "GF_UNIFIED_ALERTING_ENABLED=true" \
  -v $rootDir/grafana:/var/lib/grafana \
    grafana/grafana-oss:10.2.0

fi


if $cfg_flexscada; then

echo "Deploying FlexSCADA Docker Image.."
    
mkdir -p $rootDir/flexscada
mkdir -p $rootDir/flexscada/logs
mkdir -p $rootDir/flexscada/www

    
sudo docker stop fs_flexscada || true
sudo docker rm fs_flexscada || true
#sudo docker pull comcomservices/flexscada:latest


sudo docker run -d --net flexscada_network --ip $flexscada_ip -p 8000:8000/udp -p 8001:8001/udp -p 7001:7001 --name fs_flexscada --user $ID --restart always --log-opt max-size=10m --log-opt max-file=5 \
 -v $rootDir/flexscada:/flexscada \
 -e FS_ADMIN_KEY=$PASSWORD \
 -e FS_GRAFANA_URL=http://$grafana_ip:3000 \
 -e FS_INFLUXDB_URL=http://$influxdb_ip:8086 \
 -i -t comcomservices/flexscada:latest

fi


echo "Setup is complete!  You can now login to your grafana account at $GRAFANA_ROOT with the username admin and password $PASSWORD"
echo "You can also login directly to the FlexSCADA management app at http://localhost:7001/login using the API Key $PASSWORD"









```




```
