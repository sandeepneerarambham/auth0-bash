#!/bin/bash

set -euo pipefail

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-a access_token] [-p user_id] [-s id_token] [-v|-h]
        -e file        # .env file location (default cwd)
        -a token       # APIv2 access token with `update:current_user_identities` scope
        -p user_id     # primary user_id (i.e. current identities)
        -s id_token    # secondary user id_token
        -h|?           # usage
        -v             # verbose

eg,
     $0 -a 'eyJhbGci...' -p 'auth0|xxxx' -s 'eyJhbGc...'
END
    exit $1
}

declare access_token=''
declare user_id=''
declare id_token=''
declare opt_verbose=0

while getopts "e:a:p:s:hv?" opt
do
    case ${opt} in
        e) source "${OPTARG}";;
        a) access_token=${OPTARG};;
        p) user_id=${OPTARG};;
        s) id_token=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
[[ -z "${user_id}" ]] && { echo >&2 "ERROR: user_id undefined"; usage 1; }
[[ -z "${id_token}" ]] && { echo >&2 "ERROR: id_token undefined"; usage 1; }

declare -r AUTH0_DOMAIN_URL=$(echo "${access_token}" | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

declare -r BODY=$(cat <<EOL
{
  "link_with": "${id_token}"
}
EOL
)

curl --request POST \
    -H "Authorization: Bearer ${access_token}" \
    --url "${AUTH0_DOMAIN_URL}api/v2/users/${user_id}/identities" \
    --header 'content-type: application/json' \
    --data "${BODY}"
