#!/bin/bash
### SCRIPT PARA LA CONFIGURACION DE HAPROXY ###
## variables ##
# nombre de la instancia #
name_aws=$1
# Direccion IP #
ip=$2

# Conexion con a root  y añadir instancia #
ssh -i /Auto-Scaling/keys/MyREDHAT.pem -o "StrictHostKeyChecking no" root@localhost '
cat<<EOF>>/etc/haproxy/haproxy.cfg
	server '${name_aws}'	'${ip}':80
EOF

systemctl restart haproxy'
