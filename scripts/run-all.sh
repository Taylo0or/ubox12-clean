#!/bin/bash
# Run every step in order and stop at the first failure. Usage: TV_HOST=192.168.1.x scripts/run-all.sh
cd "$(dirname "$0")"; set -e
for s in 00-check.sh 01-launcher.sh 02-debloat.sh 03-dnsfilter.sh 04-apps.sh 05-system.sh 06-verify.sh; do
  echo; echo "########## $s ##########"; ./$s
done
echo; echo "ALL DONE. Block list for the router: $(cd .. && pwd)/assets/block-domains.txt"
