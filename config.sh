#!/bin/bash
clear
echo "Ambiente: $1";
echo "CA Pass: $2";

#Funcion que crea un contador de N a 0
#Parámetro
#Tiempo  -- $1
timerFunction(){
    for (( c=$1; c>0; c-- ))
        do  
            echo -ne "\r$c ";
            sleep 1;
    done
}

#-------------------------------------------------------------------------------------------------
printf "\n"
printf '\e[1;31m%-6s\e[m' "Ejecutando los pasos de instalación..."
printf "\n"

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "1 Clonando repositorio..."
printf "\n"
git clone https://github.com/kathemica/mongodb-replicaset.git

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "2 Moviendo los archivos del ambiente seleccionado [$1]..."
printf "\n"
if [ $1 == "dev" ]; then
  sudo mv -v ssl/scripts/dev_env/* ssl/
else
  sudo mv -v ssl/scripts/prod_env/* ssl/
fi

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "3 Eliminando archivos innnecesarios de la carpeta ssl..."
printf "\n"
sudo rm -r ssl/scripts

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "4 Otorgando permisos de ejecución al script de generación de certificados..."
printf "\n"
sudo chmod 755 ssl/generateCertificates.sh 

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "5 Cambiando nombre al arhivo de configuración de los nodos para [$1]..."
printf "\n"
if [ $1 == "dev" ]; then
  sudo mv config/serverCluster.dev.conf config/serverCluster.conf
else
  sudo mv config/serverCluster.prod.conf config/serverCluster.conf
fi

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "6 Eliminando archivos innnecesarios de la carpeta config..."
printf "\n"
if [ $1 == "dev" ]; then
  sudo rm -r config/serverCluster.prod.conf
else
  sudo rm -r config/serverCluster.dev.conf
fi

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "7 Yendo a la carpeta del script..."
printf "\n"
cd ssl/

#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-6s\e[m' "8 Generando certificados..."
printf "\n" 
sh generateCertificates.sh $2
cd ..

#-------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------
printf '\e[1;32m%-2s\e[m' "9 Generando Contenedores." 
printf "\n"
printf '\e[1;34m%-6s\e[m' "9.1 Nodo 01"
printf "\n"

docker run --name MGDB_replica01 \
-p 27017:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica01:/data/db \
-v $(pwd)/ssl/nodo01:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf

#-------------------------------------------------------------------------------------------------
printf '\e[1;34m%-6s\e[m' "9.2 Nodo 02"
printf "\n"
sudo docker run --name MGDB_replica02 \
-p 27018:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica02:/data/db \
-v $(pwd)/ssl/nodo02:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf

#-------------------------------------------------------------------------------------------------
printf '\e[1;34m%-6s\e[m' "9.3 Nodo Arbiter"
printf "\n"
sudo docker run --name MGDB_replicaArbiter \
-p 27019:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replicaarbiter:/data/db \
-v $(pwd)/ssl/nodo_arbiter:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf

printf '\e[1;32m%-2s\e[m' "Listo." 
printf "\n" 