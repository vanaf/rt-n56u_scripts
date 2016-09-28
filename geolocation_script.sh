#!/bin/sh

. /etc/storage/geolocation_secrets
. /etc/storage/geolocation_params

get_aps()
{
  local signal_fix=$SIGNAL_FIX
  if [[ $1 == "2g" ]]; then
    local suffix="_2g"
    signal_fix=140
  fi
  local URL="http://localhost/wds_aplist$suffix.asp"
  wget -O - $URL|tr '[:lower:]' '[:upper:]'| sed -e 's/^.*= \[//g;s/\["[^"]*", \("[^"]*"\), "\([0-9]*\)", "\([0-9]*\)"\]/|{"macAddress": \1, "channel": \2, "signalStrength": \3|}/g;s/\];$//g' | tr '|' '\n' |awk -v signal_fix=$signal_fix -F '"signalStrength": ' '{printf "%s",$1; if ($2!="") printf "%s%d", FS, $2-signal_fix}'
}

APS_2G=$(get_aps 2g)
APS_5G=$(get_aps 5g)

OUR_DIR="/tmp/geolocation/$(hostname)"
cp $SCP_KNOWN_HOSTS $HOME/.ssh/known_hosts

mkdir -p "$OUR_DIR"
chmod 755 "$OUR_DIR"

wget -O "$OUR_DIR/geolocation.json" --post-data "{"wifiAccessPoints": [$APS_2G, $APS_5G]}" --header "Content-Type: application/json" "https://www.googleapis.com/geolocation/v1/geolocate?key=$GOOGLE_KEY"


scp -i $SCP_KEYFILE -r "$OUR_DIR" "$SCP_DEST"
