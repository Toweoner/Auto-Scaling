#!/bin/bash
### SCRIPT PARA GENERAR PLANTILLAS DE INSTANCIAS A PARTIR DEL FICHERO /Auto-Scaling/templates/cloud.json ###

## Variables ##
find=0
# Extraer el nombre que hay en la plantilla #
name=$(cat /Auto-Scaling/templates/cloud.json | grep -A1 '"Name"' | tr -d " " | sed '1d' | cut -d : -f2 | tr -d '"'| tr -d ',')

## Main ##
# Buscar si hay generada ya una plantilla para el servidor proporcionado #
if [ -f "/Auto-Scaling/templates/$1_0_AWS.json" ]
then
	# Contar cuantar plantillas hay para dicho servidor #
	num=`ls /Auto-Scaling/templates/$1_* | wc -l`
	# Formar nombre #
	new_name=$1"_"$num"_AWS"
else
	# Si no se encuentra plantillas generadas, entonces es la 0 #
	new_name=$1"_"0"_AWS"
fi

# Leer el fichero cloud.json por lineas #
while IFS='' read -r line || [[ -n "$line" ]]; do
	# Si $find es igual a 0 #
	if [ $find -eq 0 ]
	then
		# Si la linea contiene la palabra "Name" #
		if  echo $line | grep -q '"Name"'
		then
			find=1
		fi
		
		# Añadir la lnea al nuevo fichero #
		echo "$line" >> /Auto-Scaling/templates/$new_name.json
	
	else
		# Añadir la linea al nuevo ficheor modificando el nombre #
		echo "$line" | sed 's/'$name'/'$new_name'/g' >> /Auto-Scaling/templates/$new_name.json
		find=0
	fi
done < /Auto-Scaling/templates/cloud.json

# Crear variable TEMPLATE en el ficheor main.cfg #
echo 'TEMPLATE_'$new_name'="/Auto-Scaling/templates/'$new_name'.json"' >> /Auto-Scaling/scripts/main.cfg
