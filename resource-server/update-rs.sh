#!/bin/bash

set -eo pipefail
declare -r DIR=$(dirname ${BASH_SOURCE[0]})

which awk > /dev/null || { echo >&2 "error: awk not found"; exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-a access_token] [-i id] [-v|-h]
        -e file         # .env file location (default cwd)
        -a token        # access_token. default from environment variable
        -i id           # API id
        -f key          # field name. e.g. allow_offline_access, token_dialect, full list at: https://auth0.com/docs/api/management/v2#!/Resource_Servers/patch_resource_servers_by_id
        -s val          # field value to set
        -h|?            # usage
        -v              # verbose

eg,
     $0 -i
END
    exit $1
}

declare api_id=''
declare filed=''
declare value=''

while getopts "e:a:i:f:s:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        a) access_token=${OPTARG};;
        i) api_id=${OPTARG};;
        f) filed=${OPTARG};;
        s) value=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
[[ -z "${api_id}" ]] && { echo >&2 "ERROR: api_id undefined."; usage 1; }
[[ -z ${filed+x} ]] && { echo >&2 "ERROR: no 'filed' defined"; exit 1; }
[[ -z ${value+x} ]] && { echo >&2 "ERROR: no 'value' defined"; exit 1; }

declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

declare DATA=$(cat <<EOF
{
    "${filed}":"${value}"
}
EOF
)

curl -X PATCH \
    -H "Authorization: Bearer ${access_token}" \
    -H 'content-type: application/json' \
    -d "${DATA}" \
    --url ${AUTH0_DOMAIN_URL}api/v2/resource-servers/${api_id}
