#! /bin/bash

function get_public_ip() {

local IP=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's/"\([0-9]*.[0-9]*.[0-9]*.[0-9]*\)"/\1/')

if [ -z "$IP" ]
then
	echo ERROR. IP could not be found. 
else
	echo $IP
fi
}

function create_security_list() {

cat ingress_security_rules.json | sed "s/0.0.0.0\/0/$IP\/32/" > ingress_security_rules_tmp.json

local ID=$(oci network security-list create --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID --ingress-security-rules file://ingress_security_rules_tmp.json --egress-security-rules "[]" --display-name "$DISPLAY_NAME" | sed -n 's/"id": "\(.*\)",/\1/p' | sed  's/^[ \t]*//')

rm ingress_security_rules_tmp.json

if [ -z "$ID" ]
then
      echo ERROR. ID not set.
else
      echo $ID
fi
}

function update_security_list() {

cat ingress_security_rules.json | sed "s/0.0.0.0\/0/$IP\/32/" > ingress_security_rules_tmp.json

local RESULT=$(oci network security-list update --force --security-list-id $SECURITY_LIST_ID --ingress-security-rules file://ingress_security_rules_tmp.json)

rm ingress_security_rules_tmp.json

if [[ $RESULT == *"etag"* ]];
then
        echo OK
else 
	echo ERROR. Something went wrong. 

fi
}

##########MAIN########

#first get public ip
IP=$(get_public_ip)

if [[ $IP == *"ERROR"* ]]; 
then
	echo $IP
	exit
fi

#then load config
source ./config.sh

#CREATE SECTION
if [ "$1" == "create" ]; then

echo Creating new security list

ID=$(create_security_list)

if [[ $ID == *"ERROR"* ]]; 
then
        echo $ID
	exit
else
      	echo "SECURITY_LIST_ID=$ID" > security_list_config.sh
	echo "PUBLIC_IP=$IP" >> security_list_config.sh
fi

#UPDATE SECTION
elif [ "$1" == "update" ]; then

echo Updatind security list

if [ -a security_list_config.sh ]; 
then
	source ./security_list_config.sh
	
	if [ "$PUBLIC_IP" == "$IP" ];
	then
		echo IP has not changed. No update needed.
	else 
		RESULT=$(update_security_list)

		if [[ $RESULT == *"ERROR"* ]]; 
		then
        		echo $RESULT
        		exit
		fi
		
		echo "SECURITY_LIST_ID=$SECURITY_LIST_ID" > security_list_config.sh
        	echo "PUBLIC_IP=$IP" >> security_list_config.sh
	fi
	
else 
	echo security_list_config.sh not found. Create security list first.
fi

else 
	echo Bad option.
fi
