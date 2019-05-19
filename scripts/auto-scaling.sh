#!/bin/bash
source main.cfg

set -e
set -o pipefail

num_script=1

for h in ${HOST[@]}
do
	bash /Auto-Scaling/scripts/gen_temp.sh $h 2>> /tmp/error.log
	
	num_temp=`ls /Auto-Scaling/templates/${h}_* | wc -l` 2>> /tmp/error.log
	
	let num_temp--	2>> error.log
	name="${h}_${num_temp}_AWS" 2>> /tmp/error.log
	template="TEMPLATE_${name}" 2>> /tmp/error.log
	
	script="SCRIPT${num_script}" 2>> /tmp/error.log
	
	source main.cfg
	bash /Auto-Scaling/scripts/letsgocloud.sh ${!template} ${!script} 2>> /tmp/error.log
	
	bash /Auto-Scaling/scripts/update_nagios.sh $name $NAGIOS 2>> /tmp/error.log
	
	source main.cfg
	ip="IP_${name}" 2>> /tmp/error.log
	bash /Auto-Scaling/scripts/update_haproxy.sh $name ${!ip} 2>> /tmp/error.log

	bash /Auto-Scaling/scripts/update_dns.sh $h $name ${!ip} $DNS $ZONE_PATH 2>> /tmp/error.log
	

	let num_script=num_script+1
done
