#!/bin/sh

extract_value() 
{
	echo "$1"|grep "$2"|awk -F'":' '{print $2}'|grep -o '[^"]*'	
}


. /etc/storage/ddns_secrets
. /etc/storage/ddns_params

MAC_TR_TAIL=$(cat /sys/class/net/eth?/address|tail -n 1|tr -d ':'|tail -c 7)
IPV6_BR0=$(ip -6 a show br0|grep global|tail -n 1|awk '{print $2}'|awk -F'/' '{print $1}')
IPV4_TUN0=$(ip a show tun0|grep global|tail -n 1|awk '{print $2}'|awk -F'/' '{print $1}')

logger -t gd-script "IPV4_TUN0: $IPV4_TUN0" 
logger -t gd-script "IPV6_BR0: $IPV6_BR0"                                               

IPV4="$IPLOCAL"

if [ -z "$IPV4" ] && [ ! -z "$IPV4_TUN0" ]; then
	IPV4=$IPV4_TUN0
fi

logger -t gd-script "IPV4: $IPV4"


HOST=$(nvram get computer_name)


if [[ $(echo $HOST | grep -c "$MAC_TR_TAIL") -eq "0" ]]; then
        NEW_NAME="$HOST-$MAC_TR_TAIL"
        nvram set computer_name=$NEW_NAME
        nvram commit
        hostname "$NEW_NAME"
	HOST=$NEW_NAME
fi


LOWER_HOSTNAME=$(echo "$HOST"| tr '[:upper:]' '[:lower:]')

EXISTING_OUR_RECORDS=$(wget -O - --header "PddToken: $PDD_TOKEN" "https://pddimp.yandex.ru/api2/admin/dns/list?domain=$DOMAIN"|tr -d ' '|sed -e 's/},{/\n},{\n/g'|sed -e 's/}]/\n}]/g'|sed -e 's/\[{/\[{\n/g'|grep $LOWER_HOSTNAME)


EXISTING_OUR_RECORD_AAAA=$(echo "$EXISTING_OUR_RECORDS"|grep '"type":"AAAA"'|tail -n 1|sed 's/,/\n/g')
EXISTING_OUR_RECORD_A=$(echo "$EXISTING_OUR_RECORDS"|grep '"type":"A"'|tail -n 1|sed 's/,/\n/g')


if [[ -z "$EXISTING_OUR_RECORD_A" ]]; then 
	WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=$DOMAIN&type=A&subdomain=$LOWER_HOSTNAME&ttl=$A_TTL&content=$IPV4" 'https://pddimp.yandex.ru/api2/admin/dns/add')
	logger -t gd-script "A record added. Results: $WGET_RES"
else
	EXISTING_OUR_IPV4=$(extract_value "$EXISTING_OUR_RECORD_A" "content")
	if [[ "$EXISTING_OUR_IPV4" != "$IPV4" ]]; then
		logger -t gd-script "$EXISTING_OUR_IPV4 != $IPV4"
		RECORD_ID=$(extract_value "$EXISTING_OUR_RECORD_A" "record_id")
		WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=$DOMAIN&record_id=$RECORD_ID&subdomain=$LOWER_HOSTNAME&ttl=$A_TTL&content=$IPV4" 'https://pddimp.yandex.ru/api2/admin/dns/edit')
		logger -t gd-script "A record modified. Results: $WGET_RES"
			
	fi
fi                                                                                                                                                                       

if [[ -z "$EXISTING_OUR_RECORD_AAAA" ]]; then                                                            
        WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=$DOMAIN&type=AAAA&subdomain=$LOWER_HOSTNAME&ttl=$AAAA_TTL&content=$IPV6_BR0" 'https://pddimp.yandex.ru/api2/admin/dns/add')
	logger -t gd-script "AAAA record added. Results: $WGET_RES"
else                                                                                                                                             
        EXISTING_OUR_IPV6=$(extract_value "$EXISTING_OUR_RECORD_AAAA" "content")                                                                    

        if [[ "$EXISTING_OUR_IPV6" != "$IPV6_BR0" ]]; then                                                                                           
                logger -t gd-script "$EXISTING_OUR_IPV6 != $IPV6_BR0"                                                                                
                RECORD_ID=$(extract_value "$EXISTING_OUR_RECORD_AAAA" "record_id")                                                                  
                WGET_RES=$(wget -O - --header "PddToken: $PDD_TOKEN" --post-data "domain=$DOMAIN&record_id=$RECORD_ID&subdomain=$LOWER_HOSTNAME&ttl=$AAAA_TTL&content=$IPV6_BR0" 'https://pddimp.yandex.ru/api2/admin/dns/edit')
                logger -t gd-script "AAAA record modified. Results: $WGET_RES"                                                                      
                                                                                                                                                 
        fi                                                                                                                                       
fi                                                                                                                                                                       



