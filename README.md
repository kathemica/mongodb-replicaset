
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
# FIUBA - MongoDB replicaset
Autor
* Ing. Katherine E. Aguirre
<br>
<br>
<p style="color:#ff9900"><i class="fas fa-exclamation-triangle"></i>&nbsp;Advertencia:</p>

Se hacen las siguientes presunciones:

* El cliente donde se va a configurar el *replicaset* ya posee instalado y configurado *Docker* como contenedor de imágenes.

---

## Implementar en MongoDB un ReplicaSet con 3 servidores que contengan la información de la BD Finanzas. Un nodo Primary, un secondary y un arbiter.<br>

Esta implementación se realizará con Docker Run, de esta manera quedarán los volumenens

1. Descargar los archivos de configuración:

* >wget https://raw.githubusercontent.com/kathemica/mongodb-replicaset/main/code/generarEstructura.sh

* >wget https://raw.githubusercontent.com/kathemica/mongodb-replicaset/main/code/serverCluster.conf

2. creamos una carpeta llamada *conf*:
> mkdir conf

3. Copiamos el archivo *serverCluster.conf* en *conf*:
> cp serverCluster.conf conf/

3. Le damos atributo de ejecutable al script:
> sudo chmod -w generarEstructura.sh

4. Luego ejecutamos el script:
> sudo sh generarEstructura.sh




---


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