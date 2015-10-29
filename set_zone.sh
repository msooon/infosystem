#!/bin/bash
# a small help script to change zone

# Globale Variablen
SCRIPTNAME=$(basename $0 .sh)

EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_ERROR=2
EXIT_BUG=10

sed -i "s/zones=./zones=$1/g" ${0%/*}/config || exit $EXIT_FAILURE

exit $EXIT_SUCCESS
