#!/bin/bash
name=$1
name_aws=`echo $2 | tr -s "_" "-"`
ip=$3
dns=$4
zone_path=$5

ssh -i /Auto-Scaling/keys/MyREDHAT.pem -o "StrictHostKeyChecking no" root@$dns '

rm -f '${zone_path}'.back
mv '${path}' '${zone_path}'.back 

while IFS='' read -r line || [[ -n "$line" ]]
do
	if  [[ `echo $line | grep '^www'` ]]
 	then
		if [[ `echo $line | grep 'agent$'` ]]
		then
			echo "$line" >> '${zone_path}'
		else
			echo "$line" | sed "s/"'${name}'"/agent/g" >> '${zone_path}'
		fi
	else
		echo "$line" >> '${zone_path}'
	fi
done < '${zone_path}.back'

cat<<EOF>>'${zone_path}'
'${name_aws}'           IN      A               '${ip}'
EOF

systemctl reload named

'
