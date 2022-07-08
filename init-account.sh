#!/usr/bin/env bash
set -x
# Check number of arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 account-name"
  exit 1
fi

regions="us-east-1 us-west-2"
environments="dev stage prod"

mkdir -p live/"${1}"/global
cp -r templates/account.hcl live/"${1}"/account.hcl

for region in ${regions}; do
  mkdir -p live/"${1}"/"${region}"
  cp -r templates/region.hcl live/"${1}"/"${region}"/region.hcl
  for environment in ${environments}; do
    mkdir -p live/"${1}"/"${region}"/"${environment}"
  done
done
