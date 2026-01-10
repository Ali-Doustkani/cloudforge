#!/usr/bin/env bash
set -e

for rg in $(az group list --query "[].name" -o tsv); do
    echo "Deleting resource group: $rg"
    az group delete --name "$rg" --yes
done