#!/bin/sh
TXT_LOG=" ----- "
CONFS_FILES_DIR="./node_cnf/"
Server_DIR="./CA/"
#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
NodeXX_DIR=$1
NodeXX_KEY="${NodeXX_DIR}.key"
NodeXX_CSR="${NodeXX_DIR}.csr"
NodeXX_CRT="${NodeXX_DIR}.crt"
NodeXX_CNF="${CONFS_FILES_DIR}node_base.cnf"

#-------------------------------------------------------------------
# las rutas de los certificados generados deben coincidir en el archivo serverCluster
Server_CRT="${Server_DIR}server_root_CA.crt"
PASS_PHRASE_CA=$2

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
    
    printf "\nFINALIZADO... $1 $TXT_LOG \n"
}

gen_replicakeycerts $NodeXX_DIR $NodeXX_KEY $NodeXX_CSR $NodeXX_CNF $Server_CRT $Server_KEY $NodeXX_CRT

printf "FINALIZADO $1 $TXT_LOG \n"