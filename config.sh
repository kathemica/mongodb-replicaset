#!/bin/bash
clear
echo "Ambiente: $1";
echo "CA Pass: $2";
echo "Cluster Pass: $3";
# echo "Mongo User: $4";
# echo "Mongo Pass: $5";

#-------------------------------------------------------------------------------------------------
printf "\n"
printf '\e[1;31m%-6s\e[m' "Ejecutando los pasos de instalación..."
printf "\n"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "1 Moviendo los archivos del ambiente seleccionado [$1]..."
printf "\n"
if [[ $1 == "dev" ]]; then
  sudo mv -v ssl/scripts/dev_env/* ssl/
else
  sudo mv -v ssl/scripts/prod_env/* ssl/
fi

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "2 Eliminando archivos innnecesarios de la carpeta ssl..."
printf "\n"
sudo rm -r ssl/scripts

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "3 Otorgando permisos de ejecución al script de generación de certificados..."
printf "\n"
sudo chmod 755 ssl/generateCertificates.sh 

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "4 Yendo a la carpeta del script..."
printf "\n"
cd ssl/

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "5 Generando certificados..."
printf "\n" 
sh generateCertificates.sh $2 $3
cd ..

#-------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-2s\e[m' "6 Generando Contenedores." 
printf "\n"
printf '\e[1;34m%-6s\e[m' "6.1 Nodo 01"
printf "\n"

docker run --name MGDB_replica01 \
-p 27017:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica01:/data/db \
-v $(pwd)/ssl/nodo01:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=<INSERT YOUR USERNAME HERE> \
-e MONGO_INITDB_ROOT_PASSWORD=<INSERT YOUR KEY HERE> \
mongo:4.4.6-bionic \
mongod --config /data/config/serverCluster.conf

#-------------------------------------------------------------------------------------------------
printf '\e[1;34m%-6s\e[m' "6.2 Nodo 02"
printf "\n"
sudo docker run --name MGDB_replica02 \
-p 27018:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica02:/data/db \
-v $(pwd)/ssl/nodo02:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=<INSERT YOUR USERNAME HERE> \
-e MONGO_INITDB_ROOT_PASSWORD=<INSERT YOUR KEY HERE> \
mongo:4.4.6-bionic \
mongod --config /data/config/serverCluster.conf

#-------------------------------------------------------------------------------------------------
printf '\e[1;34m%-6s\e[m' "6.3 Nodo Arbiter"
printf "\n"
sudo docker run --name MGDB_replicaArbiter \
-p 27019:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replicaarbiter:/data/db \
-v $(pwd)/ssl/nodo_arbiter:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=<INSERT YOUR USERNAME HERE> \
-e MONGO_INITDB_ROOT_PASSWORD=<INSERT YOUR KEY HERE> \
mongo:4.4.6-bionic \
mongod --config /data/config/serverCluster.conf

printf '\e[1;32m%-2s\e[m' "Listo." 
printf "\n" 