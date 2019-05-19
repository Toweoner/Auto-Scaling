#!/bin/bash
name=$1
file=$2
instance=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$name")
ip=$(echo "$instance" | grep '"PublicIpAddress"' | cut -d : -f2 | tr -d '"' | tr -d ',' | tr -d ' ')

echo IP_$name'="'$ip'"' >> /Auto-Scaling/scripts/main.cfg

cat<<EOF>>$file
define host{
	use			generic-host
	host_name		${name}
	alias			${name}
	address			${ip}
}
EOF

ssh -i /Auto-Scaling/keys/MyREDHAT.pem -o "StrictHostKeyChecking no" root@localhost 'systemctl reload nagios3'
