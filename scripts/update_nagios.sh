#!/bin/bash
### SCRIPT PARA LA CONFIGURACION DE NAGIOS ###
## variables ##
# Nombre de la instancia #
name=$1
# Archvio de configuracion nagios #
file=$2
# Buscar Instancia por nombre #
instance=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$name")
# Extraccion de la direccion IP publica #
ip=$(echo "$instance" | grep '"PublicIpAddress"' | cut -d : -f2 | tr -d '"' | tr -d ',' | tr -d ' ')
# Crear variable IP en el main.cfg #
echo IP_$name'="'$ip'"' >> /Auto-Scaling/scripts/main.cfg

# Añadir nuevo host #
cat<<EOF>>$file
define host{
	use			linux-server
	host_name		${name}
	alias			${name}
	address			${ip}
}
EOF

# Reiniciar servicio #
ssh -i /Auto-Scaling/keys/MyREDHAT.pem -o "StrictHostKeyChecking no" root@localhost 'systemctl reload nagios'
