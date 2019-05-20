#!/bin/bash
### Crea la instancia con los parametros indicados ##
aws ec2 run-instances --cli-input-json file://$1 --user-data file://$2 > /dev/null 
