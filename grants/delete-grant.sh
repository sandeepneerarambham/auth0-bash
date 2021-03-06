#!/bin/bash

set -euo pipefail

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-a access_token] [-i grant_id] [-v|-h]
        -e file        # .env file location (default cwd)
        -a token       # Access Token
        -i id          # grant id
        -u user_id     # user_id
        -h|?           # usage
        -v             # verbose

eg,
     $0 -i 5bcd5f14a2cc5cb9c16fe980
     $0 -u 'windowslive|63dd7bfd36exxxx'
END
    exit $1
}

declare grantId=''
declare user_id=''
declare opt_verbose=0

while getopts "e:a:i:u:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        a) access_token=${OPTARG};;
        i) grantId=${OPTARG};;
        u) user_id=${OPTARG};;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
#[[ -z "${grantId}" ]] && { echo >&2 "ERROR: grant_id undefined."; usage 1; }

declare -r AUTH0_DOMAIN_URL=$(echo "${access_token}" | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

if [[ -n "${grantId}" ]]; then
    curl -s --request DELETE \
        -H "Authorization: Bearer ${access_token}" \
        --url "${AUTH0_DOMAIN_URL}api/v2/grants/${grantId}"
elif [[ -n "${user_id}" ]]; then
    curl -s --request DELETE \
        -H "Authorization: Bearer ${access_token}" \
        --url "${AUTH0_DOMAIN_URL}api/v2/grants?user_id=${user_id}"
else
   echo >&2 "ERROR: grant_id or user_id required."; usage 1;
fi
