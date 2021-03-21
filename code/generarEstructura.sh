#!/bin/sh
logText=" ----- "
CONFS_FILES_DIR="./confs/"

#Part 01 -------------------------------------------------------------------
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
ServerNode01_DIR="replica01"
ServerNode01_KEY="mdb_replica01.key"
ServerNode01_CSR="mdb_replica01.csr"
ServerNode01_CRT="mdb_replica01.crt"
ServerNode01_CNF="${CONFS_FILES_DIR}ServerNode01_CN.cnf"

#Part 02 -------------------------------------------------------------------
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
ServerNode02_DIR="replica02"
ServerNode02_KEY="mdb_replica02.key"
ServerNode02_CSR="mdb_replica02.csr"
ServerNode02_CRT="mdb_replica02.crt"
ServerNode02_CNF="${CONFS_FILES_DIR}ServerNode02_CN.cnf"

#Part 03 -------------------------------------------------------------------
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
MDB_NODE_ARB_DIR="replicaarbiter"
MDB_NODE_ARB_KEY="mdb_replicaarbiter.key"
MDB_NODE_ARB_CSR="mdb_replicaarbiter.csr"
MDB_NODE_ARB_CRT="mdb_replicaarbiter.crt"
MDB_NODE_ARB_CNF="${CONFS_FILES_DIR}mdb_replicaarbiter_CN.cnf"

#Part 04 -------------------------------------------------------------------
# must match the file name of cluster.conf
MDB_CA_DIR="CA"
MDB_CA_KEY="mdb_root_CA.key"
MDB_CA_CRT="mdb_root_CA.crt"
MDB_CA_SRL="mdb_root_CA.srl"
MDB_CA_CNF="${CONFS_FILES_DIR}mdb_root_CA.cnf"
MDB_PASS_PHRASE_CA="b2RlIjoiUEdPIiwiZmFsbGJhY2tEYXRlIjoiMjAyMS0wMi0xOSIsInBhaWRVcFRvIjoiMjAyMi0wMi0"

#Part 05 -------------------------------------------------------------------
# must match the file name of cluster.conf
MDB_FINAL_KEYCERT_PEM="mdb_nodes_keycert.pem"
MDB_CLIENT_DIR="serverclient"
MDB_CLIENT_KEY="mdb_client.key"
MDB_CLIENT_CSR="mdb_client.csr"
MDB_CLIENT_CRT="mdb_client.crt"
MDB_CLIENT_PEM="mdb_client.pem"
MDB_CLIENT_CN_CNF="${CONFS_FILES_DIR}mdb_client_CN.cnf"
# param order
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
move_files() {
mkdir $1 2> /dev/null
printf "Moving $2 to ./$1/$2 $logText \n"
mv ./$2 ./$1/$2
}
# param order
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
copy_files() {
mkdir $1 2> /dev/null
printf "Copying $2 to ./$1/$2 $logText \n"
cp ./$2 ./$1/$2
}
# param order
# DIR         ----- $1 - $MDB_NODEX_DIR
# NODE .key file  ----- $2 - $MDB_NODEX_KEY
# NODE .csr file  ----- $3 - $MDB_NODEX_CSR
# NODE .cnf file  ----- $4 - $MDB_NODEX_CNF
# MDB CA .crt file  ----- $5 - $MDB_CA_CRT
# MDB CA .key file  ----- $6 - $MDB_CA_KEY
# NODE .crt file  ----- $7 - $MDB_NODEX_CRT
gen_replicakeycerts(){
printf "\nSTARTING $1 Certificates $logText \n"
mkdir $1 2> /dev/null
printf "Generating $1 - KEY and CSR files $logText\n"
openssl genrsa -des3 -out $2 -passout pass:"$MDB_PASS_PHRASE_CA" 4096
printf "\nGenerating $1 - CRT file $logText\n"
openssl req -new -config $4 -key $2 -passin pass:"$MDB_PASS_PHRASE_CA" -out $3 -config $4
openssl x509 -req -days 365 -in $3 -CA $5 -CAkey $6 -CAcreateserial -passin pass:"$MDB_PASS_PHRASE_CA" -out $7
printf "\nGenerating $1 - PEM file $logText\n"


cat $2 $7 > $MDB_FINAL_KEYCERT_PEM
move_files $1 $2
move_files $1 $3
move_files $1 $7
move_files $1 $MDB_FINAL_KEYCERT_PEM
copy_files $1 $5
printf "\nFINISHED $1 $logText\n"
}

openssl rand -writerand .rnd
printf "STARTING SCRIPT $logText\n\n"
openssl genrsa -des3 -out $MDB_CA_KEY -passout pass:"$MDB_PASS_PHRASE_CA" 4096
printf "Root CA key OK $logText \n"
openssl req -x509 -new -key $MDB_CA_KEY -sha256 -passin pass:"$MDB_PASS_PHRASE_CA" -days 720 -out $MDB_CA_CRT -config $MDB_CA_CNF
printf "Root CA crt OK $logText \n"
printf "FINISHED CA CERTIFICATE $logText \n"

gen_replicakeycerts $ServerNode01_DIR $ServerNode01_KEY $ServerNode01_CSR $ServerNode01_CNF $MDB_CA_CRT $MDB_CA_KEY $ServerNode01_CRT
gen_replicakeycerts $ServerNode02_DIR $ServerNode02_KEY $ServerNode02_CSR $ServerNode02_CNF $MDB_CA_CRT $MDB_CA_KEY $ServerNode02_CRT
gen_replicakeycerts $MDB_NODE_ARB_DIR $MDB_NODE_ARB_KEY $MDB_NODE_ARB_CSR $MDB_NODE_ARB_CNF $MDB_CA_CRT $MDB_CA_KEY $MDB_NODE_ARB_CRT

printf "Generating client access certificates key and cert $logText \n"
openssl req -new -out $MDB_CLIENT_CSR -keyout $MDB_CLIENT_KEY -passout pass:"$MDB_PASS_PHRASE_CA" -config $MDB_CLIENT_CN_CNF
printf "Signing client access certificates $logText \n"
openssl x509 -req -in $MDB_CLIENT_CSR -CA $MDB_CA_CRT -CAkey $MDB_CA_KEY -passin pass:"$MDB_PASS_PHRASE_CA" -out $MDB_CLIENT_CRT
printf "Generating client PEM file $logText \n"

cat $MDB_CLIENT_KEY $MDB_CLIENT_CRT > $MDB_CLIENT_PEM
move_files $MDB_CLIENT_DIR $MDB_CLIENT_CSR
move_files $MDB_CLIENT_DIR $MDB_CLIENT_KEY
move_files $MDB_CLIENT_DIR $MDB_CLIENT_CRT
move_files $MDB_CLIENT_DIR $MDB_CLIENT_PEM
copy_files $MDB_CLIENT_DIR $MDB_CA_CRT
move_files $MDB_CA_DIR $MDB_CA_KEY
move_files $MDB_CA_DIR $MDB_CA_CRT
move_files $MDB_CA_DIR $MDB_CA_SRL

printf "FINISHED $1 $logText\n"