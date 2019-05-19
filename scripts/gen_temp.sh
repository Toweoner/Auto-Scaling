#!/bin/bash
find=0
name=$(cat /Auto-Scaling/templates/cloud.json | grep -A1 '"Name"' | tr -d " " | sed '1d' | cut -d : -f2 | tr -d '"'| tr -d ',')

if [ -f "/Auto-Scaling/templates/$1_0_AWS.json" ]
then
	num=`ls /Auto-Scaling/templates/$1_* | wc -l`
	new_name=$1"_"$num"_AWS"
else
	new_name=$1"_"0"_AWS"
fi


while IFS='' read -r line || [[ -n "$line" ]]; do
	if [ $find -eq 0 ]
	then
		if  echo $line | grep -q '"Name"'
		then
			find=1
			echo "$line" >> /Auto-Scaling/templates/$new_name.json
		else
			echo "$line" >> /Auto-Scaling/templates/$new_name.json
		fi
	else
		echo "$line" | sed 's/'$name'/'$new_name'/g' >> /Auto-Scaling/templates/$new_name.json
		find=0
	fi
done < /Auto-Scaling/templates/cloud.json

echo 'TEMPLATE_'$new_name'="/Auto-Scaling/templates/'$new_name'.json"' >> main.cfg
