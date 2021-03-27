
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.2/css/all.css" integrity="sha384-vSIIfh2YWi9wW0r9iZe7RJPrKwp6bG+s9QZMoITbCckVJqGCCRhc+ccxNcdpHuYu" crossorigin="anonymous">

[<img src="https://img.shields.io/badge/Linkedin-kathesama-blue?style=for-the-badge&logo=linkedin">](https://www.linkedin.com/in/kathesama)
![MongoDB](https://img.shields.io/badge/-MongoDB-009900?logo=mongodb&logoColor=white&style=for-the-badge)
<br>
[![GitHub issues](https://img.shields.io/github/issues/kathemica/mongodb-replicaset?style=plastic)](https://github.com/kathemica/mongodb-replicaset/issues)
[![GitHub forks](https://img.shields.io/github/forks/kathemica/mongodb-replicaset?style=plastic)](https://github.com/kathemica/mongodb-replicaset/network)
[![GitHub stars](https://img.shields.io/github/stars/kathemica/mongodb-replicaset?style=plastic)](https://github.com/kathemica/mongodb-replicaset/stargazers)
![GitHub last commit](https://img.shields.io/github/last-commit/kathemica/mongodb-replicaset?color=red&style=plastic)
![GitHub top language](https://img.shields.io/github/languages/top/kathemica/mongodb-replicaset?style=plastic)
<br>
[![GitHub license](https://img.shields.io/github/license/kathemica/mongodb-replicaset?style=plastic)](https://github.com/kathemica/mongodb-replicaset/blob/main/LICENSE)
![GitHub repo size](https://img.shields.io/github/repo-size/kathemica/mongodb-replicaset?style=plastic)
<br>

![header](assets/header.png)
---
# FIUBA - MongoDB replicaset con tres (03) nodos y TLS
Autor
* Ing. Katherine E. Aguirre
<br>
<br>
<p><i class="fas fa-exclamation-triangle" style="color:#ff9900"></i>&nbsp;&nbsp;Advertencia:</p>

Se hacen las siguientes presunciones:

* <i class="fab fa-docker" style="color:blue"></i> El cliente donde se va a configurar el *replicaset* ya posee instalado y configurado *Docker* como contenedor de imágenes.
* <i class="far fa-hand-paper" style="color:red"></i> NO SE UTILIZA **docker-compose** EN ESTE PROYECTO

---

## Implementar en MongoDB un ReplicaSet con 3 servidores que contengan la información de la BD Finanzas. Un nodo Primary, un secondary y un arbiter.<br>

Esta implementación se realizará con Docker Run, de esta manera quedarán los volúmenes corriendo de una vez, ahora procederemos:

1. Ir a la carpeta donde se van a guardar los datos y clonar el respositorio:

> git clone https://github.com/kathemica/mongodb-replicaset.git

2. Desde la misma carpeta ejecutar: 

```
sudo mv -v mongodb-replicaset/ssl/scripts/prod_env/* mongodb-replicaset/ssl/
```

**NOTA**: dependiendo del ambiente selecciona: *prod_env* ó *dev_env*

3. Ahora procederemos a cambiar los permisos del script:

```
sudo chmod -w mongodb-replicaset/ssl/generateCertificates.sh
```

4. Una vez hecho esto debemos seleccionar el archivo de configuracion, para esto ejecutaremos:
```
sudo chmod -w mongodb-replicaset/ssl/generateCertificates.sh
```

Al final de todas estas operaciones nos debería quedar la siguiente estructura:

![header](assets/treeFinal.png)

3. Luego ejecutamos el script para generar los certificados:
> sudo sh configScript.sh

Una vez que se haya ejecutado el archivo y configurado todo el sistema de certificados procedemos a levantar las instancias:

---

**Primera instancia**:<br> 
```
 sudo docker run --name MGDB_replica01 \
-p 27017:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica01:/data/db \
-v $(pwd)/ssl/replica01:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf
```
---

**Segunda instancia**:<br>
```
sudo docker run --name MGDB_replica02 \
-p 27018:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replica02:/data/db \
-v $(pwd)/ssl/replica02:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf
```
---

**Tercera instancia**:<br>
```
sudo docker run --name MGDB_replicaArbiter \
-p 27019:27017 \
--restart always \
-e "TZ=America/Argentina/Buenos_Aires" \
-e MONGODB_EXTRA_FLAGS='--wiredTigerCacheSizeGB=1' \
-v $(pwd)/data/replicaarbiter:/data/db \
-v $(pwd)/ssl/replicaarbiter:/data/ssl \
-v $(pwd)/config:/data/config \
-e MONGO_INITDB_ROOT_USERNAME=mdb_admin \
-e MONGO_INITDB_ROOT_PASSWORD=mdb_pass \
mongo:4.4.4-bionic \
mongod --config /data/config/serverCluster.conf
```
---
Esperamos a que termine de ejecutar el ultimo comando y entramos a la consola de mongo del primer nodo:
> docker exec -it MGDB_replica01 /bin/bash


Este comando permite loguearse como root en mongo

we have to log as root to create the replicaset and the user

IMPORTANT: Note that we are inside the container and they are reflecting our node mapped volume

IMPORTANT2: remember the password set in the SCRIPT and cluster.conf. Yes we are using here to connect and decrypt the files

IMPORTANT3: the option --tlsAllowInvalidHostnames is necessary because we are using self-signed certificates!

```
mongo --tls --tlsCertificateKeyFile /data/ssl/mdb_nodes_keycert.pem --tlsCAFile /data/ssl/server_root_CA.crt --tlsCertificateKeyFilePassword b2RlIjoiUEdPIiwiZmFsbGJhY2tEYXRlIjoiMjAyMS --tlsAllowInvalidHostnames
```

Ahora creamos el archivo de configuracion del cluster
```
rs.initiate({
  "_id": "my-replica-set", 
  "version": 1, 
  "writeConcernMajorityJournalDefault": true, 
  "members": [
    { 
      "_id": 0, 
      "host": "10.0.0.12:27017", 
    }, 
    { 
      "_id": 1, 
      "host": "10.0.0.12:27018", 
    }, 
    { 
      "_id": 2, 
      "host": "10.0.0.12:27019", 
      arbiterOnly: true 
    }
  ]
});
```

> use admin;

```
db.createUser({
  user: "mdb_admin",
  pwd: "mdb_pass",
  roles: [
    {role: "root", db: "admin"},
    { role: "userAdminAnyDatabase", db: "admin" }, 
    { role: "dbAdminAnyDatabase", db: "admin" }, 
    { role: "readWriteAnyDatabase", db:"admin" }, 
    { role: "clusterAdmin",  db: "admin" }
  ]
});
```
NOTA:
Si al ejecutar el comando de crear el usuario obtienes este mensaje:
>uncaught exception: Error: couldn't add user: command createUser requires authentication :
_getErrorWithCode@src/mongo/shell/utils.js:25:13
DB.prototype.createUser@src/mongo/shell/db.js:1386:11

Tienes que ir a *serverCluster.conf* y modificar:
```
security:
  authorization: enabled
```
por:

```
security:
  authorization: disabled
```
una vez creado el usuario vuelves a modificar el archivo y reinicias el cluster.
---

Finalmente, para poder hacer operaciones con el cluster emplear el siguiente connection string:

```
mongo --tls --tlsCertificateKeyFile /data/ssl/mdb_nodes_keycert.pem --tlsCAFile /data/ssl/server_root_CA.crt --tlsCertificateKeyFilePassword b2RlIjoiUEdPIiwiZmFsbGJhY2tEYXRlIjoiMjAyMS -u $MONGO_INITDB_ROOT_USERNAME -p $MONGO_INITDB_ROOT_PASSWORD --tlsAllowInvalidHostnames
```

Convertir root cert .crt a .pem, esto es para uso de **node**
> openssl x509 -in mycert.crt -out mycert.pem -outform PEM

On Error: Cannot find module 'mongodb', install
> npm install -g mongodb

2.  Conectarse al Nodo PRIMARY

3.  Crear la db finanzas.

4.  Ejecutar el script facts.js 4 veces para crear volumen de datos.

5.  Buscar los datos insertados, en el nodo PRIMARY.

6.  Buscar los datos insertados, en el nodo SECONDARY.

7.  Realizar un ejemplo de Fault Tolerance simulando una caída del Servidor PRIMARY.

1.  Explicar que sucedió.

2.  Verificar el estado de cada servidor.

3.  Insertar un nuevo documento.

4.  Levantar el servidor caído.

5.  Validar la información en cada servidor.

8.  Agregar un nuevo nodo con slaveDelay de 120 segundos.

9.  Ejecutar nuevamente el script facts.js, asegurarse antes de ejecutarlo que el nodo con
slaveDelay esté actualizado igual que el PRIMARY.

1.  Luego de ejecutado chequear el SECONDARY.

2.  Consultar el nuevo nodo y ver cuando se actualizan los datos.