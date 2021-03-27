#!/bin/sh
TXT_LOG=" ----- "
CONFS_FILES_DIR="./node_cnf/"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
Node01_DIR="nodo01"
Node01_KEY="nodo01.key"
Node01_CSR="nodo01.csr"
Node01_CRT="nodo01.crt"
Node01_CNF="${CONFS_FILES_DIR}nodo01_CN.cnf"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
Node02_DIR="nodo02"
Node02_KEY="nodo02.key"
Node02_CSR="nodo02.csr"
Node02_CRT="nodo02.crt"
Node02_CNF="${CONFS_FILES_DIR}nodo02_CN.cnf"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
NodeArbiter_DIR="nodo_arbiter"
NodeArbiter_KEY="nodo_arbiter.key"
NodeArbiter_CSR="nodo_arbiter.csr"
NodeArbiter_CRT="nodo_arbiter.crt"
NodeArbiter_CNF="${CONFS_FILES_DIR}nodo_arbiter_CN.cnf"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
Server_DIR="CA"
Server_KEY="server_root_CA.key"
Server_CRT="server_root_CA.crt"
Server_SRL="server_root_CA.srl"
Server_CNF="${CONFS_FILES_DIR}server_root_CA.cnf"
PASS_PHRASE_CA="MjAyMDEwMTkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwA"
CLUSTER_PHRASE_CA="QzzuGEjsCOURNO7xCeZyCX"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
FINAL_KEYCERT_PEM="mdb_nodes_keycert.pem"
Client_DIR="client"
Client_KEY="client.key"
Client_CSR="client.csr"
Client_CRT="client.crt"
Client_PEM="client.pem"
Client_CN_CNF="${CONFS_FILES_DIR}client_CN.cnf"

#-------------------------------------------------------------------
# Orden de los parámetros
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
move_files() {    
    mkdir $1 2> /dev/null
    printf "Moviendo $2 A ./$1/$2 $TXT_LOG  \n"
    mv ./$2 ./$1/$2
}

#-------------------------------------------------------------------
# Orden de los parámetros
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
copy_files() {    
    mkdir $1 2> /dev/null
    printf "Copiando $2 A ./$1/$2 $TXT_LOG  \n"
    cp ./$2 ./$1/$2
}

#-------------------------------------------------------------------
# Orden de los parámetros
# DIR         ----- $1 - $MDB_NODEX_DIR
# NODE .key file  ----- $2 - $MDB_NODEX_KEY
# NODE .csr file  ----- $3 - $MDB_NODEX_CSR
# NODE .cnf file  ----- $4 - $MDB_NODEX_CNF
# MDB CA .crt file  ----- $5 - $Server_CRT
# MDB CA .key file  ----- $6 - $Server_KEY
# NODE .crt file  ----- $7 - $MDB_NODEX_CRT
gen_replicakeycerts(){
    printf "\nGenerando certificados de $1 $TXT_LOG  \n"
    
    mkdir $1 2> /dev/null

    printf "nGenerando $1 - archivos .KEY y .CSR $TXT_LOG \n"
    
    openssl genrsa -des3 -out $2 -passout pass:"$PASS_PHRASE_CA" 4096
    
    printf "\nGenerando $1 - archivo .CRT $TXT_LOG \n"
    
    openssl req -new -config $4 -key $2 -passin pass:"$PASS_PHRASE_CA" -out $3 -config $4
    openssl x509 -req -days 365 -in $3 -CA $5 -CAkey $6 -CAcreateserial -passin pass:"$PASS_PHRASE_CA" -out $7
    
    printf "\nGenerando $1 - archivo .PEM $TXT_LOG \n"
    
    cat $2 $7 > $FINAL_KEYCERT_PEM
    
    move_files $1 $2
    move_files $1 $3
    move_files $1 $7
    move_files $1 $FINAL_KEYCERT_PEM
    copy_files $1 $5
    
    printf "\FINALIZADO... $1 $TXT_LOG \n"
}

openssl rand -out .rnd -hex 256
printf "INICIANDO SCRIPT $TXT_LOG \n\n"

openssl genrsa -des3 -out $Server_KEY -passout pass:"$PASS_PHRASE_CA" 4096
printf "Root CA .key OK $TXT_LOG  \n"

openssl req -x509 -new -key $Server_KEY -sha256 -passin pass:"$PASS_PHRASE_CA" -days 720 -out $Server_CRT -config $Server_CNF
printf "Root CA .crt OK $TXT_LOG  \n"

printf "FINALIZADO CERTIFICADO CA $TXT_LOG  \n"

gen_replicakeycerts $Node01_DIR $Node01_KEY $Node01_CSR $Node01_CNF $Server_CRT $Server_KEY $Node01_CRT
gen_replicakeycerts $Node02_DIR $Node02_KEY $Node02_CSR $Node02_CNF $Server_CRT $Server_KEY $Node02_CRT
gen_replicakeycerts $NodeArbiter_DIR $NodeArbiter_KEY $NodeArbiter_CSR $NodeArbiter_CNF $Server_CRT $Server_KEY $NodeArbiter_CRT

printf "Generando certificados de acceso del cliente: .key y .cert $TXT_LOG  \n"
openssl req -new -out $Client_CSR -keyout $Client_KEY -passout pass:"$PASS_PHRASE_CA" -config $Client_CN_CNF

printf "Firmando certificados de acceso del cliente $TXT_LOG  \n"
openssl x509 -req -in $Client_CSR -CA $Server_CRT -CAkey $Server_KEY -passin pass:"$PASS_PHRASE_CA" -out $Client_CRT

printf "Generando archivo .PEM del cliente $TXT_LOG  \n"

cat $Client_KEY $Client_CRT > $Client_PEM

move_files $Client_DIR $Client_CSR
move_files $Client_DIR $Client_KEY
move_files $Client_DIR $Client_CRT
move_files $Client_DIR $Client_PEM

copy_files $Client_DIR $Server_CRT

move_files $Server_DIR $Server_KEY
move_files $Server_DIR $Server_CRT
move_files $Server_DIR $Server_SRL

printf "FINALIZADO $1 $TXT_LOG \n"