#!/bin/bash
shopt -s globstar
set -o pipefail

LSLINT_PATH=$1
FAILED=.

for file in src/**/*.lsl; do
    echo "[>>] Linting $file..." | tee -a ./test.run.txt
    $1 "$file" 2>&1 | tee -a ./test.run.txt
    
    if [ ${PIPESTATUS[0]} != 0 ] ; then
        echo "[!!] Linting failed on $file" | tee -a ./test.run.txt
        FAILED=$FAILED.
    else
        echo "[>>] Linting passed" | tee -a ./test.run.txt
    fi
done

if [ $FAILED != . ] ; then
  echo "[!!!] Linting failed on ${#FAILED} files - check the logs."
  exit ${#FAILED}
fi
