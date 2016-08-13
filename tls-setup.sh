#!/bin/bash

MASTER_HOST=172.17.8.101
WORKER_COUNT=2
K8S_SERVICE_IP=10.3.0.1
TLS_ASSETS_DIR=".assets/tls"
TLS_CA_CN="kube-ca"
TLS_API_CN="kube-apiserver"
TLS_ADMIN_CN="kube-admin"

# Create and navigate to the TLS assets directory
mkdir -p ${TLS_ASSETS_DIR}
cd ${TLS_ASSETS_DIR}

# Create Cluster Root CA
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=${TLS_CA_CN}"

# Create SSL Configuration for API Server Certificate
cat <<EOF > openssl-apiserver.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = ${K8S_SERVICE_IP}
IP.2 = ${MASTER_HOST}
EOF

# Generate the API Server Keypair
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=${TLS_API_CN}" -config openssl-apiserver.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl-apiserver.cnf

# Create SSL Configuration for the Worker Keypairs
cat <<EOF > openssl-worker.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = \$ENV::WORKER_IP
EOF

# Generate the Worker Keypairs
for WORKER_ID in $(seq 1 $WORKER_COUNT)
do
    WORKER_IP="172.17.8.$((101+$WORKER_ID))"
    WORKER_FQDN="kube-worker-n0${WORKER_ID}"

    openssl genrsa -out ${WORKER_FQDN}-worker-key.pem 2048
    WORKER_IP=${WORKER_IP} openssl req -new -key ${WORKER_FQDN}-worker-key.pem -out ${WORKER_FQDN}-worker.csr -subj "/CN=${WORKER_FQDN}" -config openssl-worker.cnf
    WORKER_IP=${WORKER_IP} openssl x509 -req -in ${WORKER_FQDN}-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out ${WORKER_FQDN}-worker.pem -days 365 -extensions v3_req -extfile openssl-worker.cnf
done

# Generate the Cluster Administrator Keypair
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=${TLS_ADMIN_CN}"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365
