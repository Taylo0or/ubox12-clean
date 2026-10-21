#!/bin/bash
# nc-install.sh <local.apk> <remote-name>   -- standalone wrapper around lib.sh nc_install
source "$(dirname "$0")/lib.sh"; ensure_toolkit; nc_install "$1" "$2"
