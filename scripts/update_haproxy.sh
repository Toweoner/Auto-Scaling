#!/bin/bash
name_aws=$1
ip=$2
ssh -i /Auto-Scaling/keys/MyREDHAT.pem -o "StrictHostKeyChecking no" root@localhost '
cat<<EOF>>/etc/haproxy/haproxy.cfg
	server '${name_aws}'	'${ip}':80
EOF

systemctl restart haproxy'
