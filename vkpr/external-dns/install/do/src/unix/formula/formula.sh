#!/bin/sh

runFormula() {
  echoColor "yellow" "Instalando external-dns with DigitalOcean DNS..."

  getProviderCreds
  add_repo_external_dns
  install_external_dns
}

add_repo_external_dns() {
  registerHelmRepository bitnami https://charts.bitnami.com/bitnami
}

install_external_dns() {
  local VKPR_EXTERNAL_DNS_VALUES=$(dirname "$0")/utils/external-dns.yaml
  $VKPR_HELM upgrade -i external-dns \
    --namespace $VKPR_K8S_NAMESPACE --create-namespace \
    --set digitalocean.apiToken=$TOKEN \
    -f $VKPR_EXTERNAL_DNS_VALUES bitnami/external-dns
}

getProviderCreds(){
  # CREDENTIAL INPUT NOT WORKING IN SHELL FORMULA
  # PARSING FILE DIRECTLY AND IGNORING INPUT ("-r" is important!!!)
  #VKPR_ACCESS_TOKEN_INPUT=$($VKPR_JQ -r .credential.token ~/.rit/credentials/default/digitalocean)
  if [ -z "$TOKEN" ]; then
    echo "yellow" "No digitalocean token found in rit credentials. Falling back to DO_AUTH_TOKEN env variable."
    TOKEN="$DO_AUTH_TOKEN"
  fi
  if [ -z "$TOKEN" ]; then
    echoColor "red" "No digitalocean token found in both rit credentials or DO_AUTH_TOKEN env variable."
    echoColor "red" "Cert-manager will fail to negotiate certificates unless you provide the digitalocean-dns secret manually."
    echoColor "red" "Please check https://cert-manager.io/docs/configuration/acme/dns01/digitalocean/"
  fi
}
