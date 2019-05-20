#!/bin/bash

## Variables ##
source main.cfg
num_script=1

## Control de Errores ##
set -e
set -o pipefail

### MAIN ###
for h in ${HOST[@]}
do
	# Generar Plantilla #
	bash /Auto-Scaling/scripts/gen_temp.sh $h 2>> /tmp/error.log
	
	# Numero de Plantilla #
	num_temp=`ls /Auto-Scaling/templates/${h}_* | wc -l` 2>> /tmp/error.log
	let num_temp--	2>> error.log

	# Nombre de la instancia #
	name="${h}_${num_temp}_AWS" 2>> /tmp/error.log

	# Nombre Variable Plantilla #
	template="TEMPLATE_${name}" 2>> /tmp/error.log
	
	# Nombre Variable Script #
	script="SCRIPT${num_script}" 2>> /tmp/error.log
	
	# Recarga de variables #
	source main.cfg
	
	# Crear instancia y provisionar #
	bash /Auto-Scaling/scripts/letsgocloud.sh ${!template} ${!script} 2>> /tmp/error.log
	
	# Actualizar Nagios #
	bash /Auto-Scaling/scripts/update_nagios.sh $name $NAGIOS 2>> /tmp/error.log
	
	# Recarga de variables #
	source main.cfg
	
	# Nombre de la varaible IP #
	ip="IP_${name}" 2>> /tmp/error.log

	# Actualizar Haproxy #
	bash /Auto-Scaling/scripts/update_haproxy.sh $name ${!ip} 2>> /tmp/error.log
	
	# Actualizar DNS #
	bash /Auto-Scaling/scripts/update_dns.sh $h $name ${!ip} $DNS $ZONE_PATH 2>> /tmp/error.log
	
	# Aumentar Numero de SCRIPT #
	let num_script++ 2>> /tmp/error.log
done
