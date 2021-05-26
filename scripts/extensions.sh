#!/bin/bash
# Install and/or enable extensions.
# Usage:
#
#   extensions.sh PHP_VERSION LIST_OF_EXTENSIONS

set -e

STATIC_EXTENSIONS=(sqlsrv swoole)

function install_packaged_extensions {
    local EXTENSIONS=${@:1}
    echo "Installing packaged extensions: ${EXTENSIONS}"
    apt update
    apt install -y "${EXTENSIONS}"
}

function enable_static_extension {
    local PHP=$1
    local EXTENSION=$2
    echo "Enabling ${EXTENSION} extension"
    phpenmod -v "${PHP}" -s ALL "${EXTENSION}"
}

function enable_sqlsrv {
    local __result=$1
    local PHP=$2
    local EXTENSIONS=${@:3}
    if [[ ! ${PHP} =~ (7.3|7.4|8.0) ]];then
        echo "Skipping enabling of swoole extension; not supported on PHP < 7.3"
        eval $__result="${EXTENSIONS}"
    else
        enable_static_extension "${PHP}" sqlsrv
		eval $__result=$(echo "${EXTENSIONS}" | sed -E -e 's/php[0-9.]+-(pdo[_-]){0,1}sqlsrv/ /g' | sed -E -e 's/\s{2,}/ /g')
    fi
}

function enable_swoole {
    local __result=$1
    local PHP=$2
    local EXTENSIONS=${@:3}
    if [[ ! ${PHP} =~ (7.3|7.4|8.0) ]];then
        echo "Skipping enabling of swoole extension; not supported on PHP < 7.3"
        eval $__result="${EXTENSIONS}"
    else
        enable_static_extension "${PHP}" swoole
        eval $__result=$(echo "${EXTENSIONS}" | sed -E -e 's/php[0-9.]+-swoole/ /g' | sed -E -e 's/\s{2,}/ /g')
    fi
}

PHP=$1
EXTENSIONS=${@:2}

# Loop through known statically compiled/installed extensions, and enable them.
# Each should update the result variable passed to it with a new list of
# extensions.
for EXTENSION in "${STATIC_EXTENSIONS[@]}";do
    if [[ "${EXTENSIONS}" =~ ${EXTENSION} ]];then
        ENABLE_FUNC="enable_${EXTENSION}"
        $ENABLE_FUNC result "${PHP}" "${EXTENSIONS}"
        EXTENSIONS="${result}"
    fi
done

# If by now the extensions list is not empty, install packaged extensions.
if [[ "${EXTENSIONS}" != "" ]];then
    install_packaged_extensions "${EXTENSIONS}"
fi
