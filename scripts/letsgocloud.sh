#!/bin/bash
aws ec2 run-instances --cli-input-json file://$1 --user-data file://$2 > /dev/null 

