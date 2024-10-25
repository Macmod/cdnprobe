#!/bin/bash

HTTPXFLAGS="-v -duc -nfs -sc -cl -ct -lc -wc -server -title -location -timeout 3 -hash md5 -random-agent=false"
URLDOMAIN="$1"
URLPATH="${2:-}"
SCHEMA="${3:-https}"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0'

echo "[+] Trying to find $SCHEMA://$URLDOMAIN$URLPATH"

jq -rc 'to_entries[] | "\(.key),\(.value[])"' cdnips.json | while IFS="," read provider cdnip; do
    result=$(httpx -no-stdin -u "$SCHEMA://$cdnip$URLPATH" -sni "$URLDOMAIN" -H "Host: $URLDOMAIN" -H "User-Agent: $UA" $HTTPXFLAGS 2>&1 | tail -n 1)
    echo -e "\e[34m[$provider $cdnip]\e[0m $result"
done
