#!/bin/bash

runFormula() {
  local VKPR_VAULT_VALUES=$(dirname "$0")/utils/vault.yaml
  local VKPR_VAULT_CONFIG=$(dirname "$0")/utils/config.hcl
  local RIT_CREDENTIALS_PATH=~/.rit/credentials/default

  checkGlobalConfig $DOMAIN "localhost" "domain" "DOMAIN"
  checkGlobalConfig $SECURE "false" "secure" "SECURE"
  checkGlobalConfig $VAULT_MODE "raft" "vault.storageMode" "VAULT_MODE"
  checkGlobalConfig $VAULT_AUTO_UNSEAL "false" "vault.autoUnseal" "VAULT_AUTO_UNSEAL"
  checkGlobalConfig "nginx" "nginx" "vault.ingressClassName" "VAULT_INGRESS"

  local VKPR_ENV_VAULT_DOMAIN="vault.${VKPR_ENV_DOMAIN}"
  
  startInfos
  configureRepository
  installVault
}

startInfos() {
  echo "=============================="
  echoColor "bold" "$(echoColor "green" "VKPR Vault Install Routine")"
  echoColor "bold" "$(echoColor "blue" "Vault UI Domain:") ${VKPR_ENV_VAULT_DOMAIN}"
  echoColor "bold" "$(echoColor "blue" "Vault UI HTTPS:") ${VKPR_ENV_SECURE}"
  echoColor "bold" "$(echoColor "blue" "Ingress Controller:") ${VKPR_ENV_VAULT_INGRESS}"
  echoColor "bold" "$(echoColor "blue" "Storage Mode:") ${VKPR_ENV_VAULT_MODE}"
  echoColor "bold" "$(echoColor "blue" "Auto Unseal:") ${VKPR_ENV_VAULT_AUTO_UNSEAL}"
  echo "=============================="
}

configureRepository() {
  registerHelmRepository hashicorp https://helm.releases.hashicorp.com
}

settingVault() {
  YQ_VALUES=''$YQ_VALUES' |
    .server.ingress.ingressClassName = "'$VKPR_ENV_VAULT_INGRESS'" |
    .server.ingress.hosts[0].host = "'$VKPR_ENV_VAULT_DOMAIN'"
  '

  if [[ $VKPR_ENV_SECURE == true ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .server.ingress.annotations.["'kubernetes.io/tls-acme'"] = "'true'" |
      .server.ingress.tls[0].hosts[0] = "'$VKPR_ENV_VAULT_DOMAIN'" |
      .server.ingress.tls[0].secretName = "'vault-cert'"
    '
  fi

  if [[ $VKPR_ENV_VAULT_AUTO_UNSEAL != false ]]; then
    YQ_VALUES=''$YQ_VALUES' |
      .server.extraEnvironmentVars.VAULT_LOG_LEVEL = "debug"
    '
    case $VKPR_ENV_VAULT_AUTO_UNSEAL in
      aws)
        YQ_VALUES=''$YQ_VALUES' |
          .server.extraEnvironmentVars.VAULT_SEAL_TYPE = "awskms" |
          .server.extraSecretEnvironmentVars[0].envName = "AWS_REGION" |
          .server.extraSecretEnvironmentVars[0].secretName = "aws-unseal-vault" |
          .server.extraSecretEnvironmentVars[0].secretKey = "AWS_REGION" |
          .server.extraSecretEnvironmentVars[1].envName = "AWS_ACCESS_KEY" |
          .server.extraSecretEnvironmentVars[1].secretName = "aws-unseal-vault" |
          .server.extraSecretEnvironmentVars[1].secretKey = "AWS_ACCESS_KEY" |
          .server.extraSecretEnvironmentVars[2].envName = "AWS_SECRET_KEY" |
          .server.extraSecretEnvironmentVars[2].secretName = "aws-unseal-vault" |
          .server.extraSecretEnvironmentVars[2].secretKey = "AWS_SECRET_KEY" |
          .server.extraSecretEnvironmentVars[3].envName = "VAULT_AWSKMS_SEAL_KEY_ID" |
          .server.extraSecretEnvironmentVars[3].secretName = "aws-unseal-vault" |
          .server.extraSecretEnvironmentVars[3].secretKey = "VAULT_AWSKMS_SEAL_KEY_ID" |
          .server.extraSecretEnvironmentVars[4].envName = "AWS_KMS_ENDPOINT" |
          .server.extraSecretEnvironmentVars[4].secretName = "aws-unseal-vault" |
          .server.extraSecretEnvironmentVars[4].secretKey = "AWS_KMS_ENDPOINT"
        '
        validateAwsSecretKey $AWS_SECRET_KEY
        validateAwsAccessKey $AWS_ACCESS_KEY
        validateAwsRegion $AWS_REGION
        $VKPR_YQ eval '.metadata.name = "aws-unseal-vault" |
          .data.AWS_REGION = "'$(echo -n $($VKPR_JQ -r .credential.accesskeyid $RIT_CREDENTIALS_PATH/aws) | base64)'" |
          .data.AWS_ACCESS_KEY = "'$(echo -n $($VKPR_JQ -r .credential.secretaccesskey $RIT_CREDENTIALS_PATH/aws) | base64)'" |
          .data.AWS_SECRET_KEY = "'$(echo -n $($VKPR_JQ -r .credential.awsregion $RIT_CREDENTIALS_PATH/aws) | base64)'" |
          .data.AWS_KMS_KEY_ID = "'$(echo -n $($VKPR_JQ -r .credential.kmskeyid $RIT_CREDENTIALS_PATH/aws) | base64)'" |
          .data.AWS_KMS_ENDPOINT = "'$(echo -n $($VKPR_JQ -r .credential.kmsendpoint $RIT_CREDENTIALS_PATH/aws) | base64)'"
        ' $(dirname "$0")/utils/auto-unseal.yaml
        ;;
      azure)
        YQ_VALUES=''$YQ_VALUES' |
          .server.extraEnvironmentVars.VAULT_SEAL_TYPE = "azurekeyvault" |
          .server.extraSecretEnvironmentVars[0].envName = "AZURE_TENANT_ID" |
          .server.extraSecretEnvironmentVars[0].secretName = "azure-unseal-vault" |
          .server.extraSecretEnvironmentVars[0].secretKey = "AZURE_TENANT_ID" |
          .server.extraSecretEnvironmentVars[1].envName = "AZURE_CLIENT_ID" |
          .server.extraSecretEnvironmentVars[1].secretName = "azure-unseal-vault" |
          .server.extraSecretEnvironmentVars[1].secretKey = "AZURE_CLIENT_ID" |
          .server.extraSecretEnvironmentVars[2].envName = "AZURE_CLIENT_SECRET" |
          .server.extraSecretEnvironmentVars[2].secretName = "azure-unseal-vault" |
          .server.extraSecretEnvironmentVars[2].secretKey = "AZURE_CLIENT_SECRET" |
          .server.extraSecretEnvironmentVars[3].envName = "VAULT_AZUREKEYVAULT_VAULT_NAME" |
          .server.extraSecretEnvironmentVars[3].secretName = "azure-unseal-vault" |
          .server.extraSecretEnvironmentVars[3].secretKey = "VAULT_AZUREKEYVAULT_VAULT_NAME" |
          .server.extraSecretEnvironmentVars[4].envName = "VAULT_AZUREKEYVAULT_KEY_NAME" |
          .server.extraSecretEnvironmentVars[4].secretName = "azure-unseal-vault" |
          .server.extraSecretEnvironmentVars[4].secretKey = "VAULT_AZUREKEYVAULT_KEY_NAME"
        '
        $VKPR_YQ eval '.metadata.name = "azure-unseal-vault" |
          .data.AZURE_TENANT_ID = "'$(echo -n $($VKPR_JQ -r .credential.azuretenantid $RIT_CREDENTIALS_PATH/azure) | base64)'" |
          .data.AZURE_CLIENT_ID = "'$(echo -n $($VKPR_JQ -r .credential.azureclientid $RIT_CREDENTIALS_PATH/azure) | base64)'" |
          .data.AZURE_CLIENT_SECRET = "'$(echo -n $($VKPR_JQ -r .credential.azureclientsecret $RIT_CREDENTIALS_PATH/azure) | base64)'" |
          .data.VAULT_AZUREKEYVAULT_VAULT_NAME = "'$(echo -n $($VKPR_JQ -r .credential.vaultazurekeyvaultvaultname $RIT_CREDENTIALS_PATH/azure) | base64)'" |
          .data.VAULT_AZUREKEYVAULT_KEY_NAME = "'$(echo -n $($VKPR_JQ -r .credential.vaultazurekeyvaultkeyname $RIT_CREDENTIALS_PATH/azure) | base64)'"
        ' $(dirname "$0")/utils/auto-unseal.yaml
        ;;
      esac
  fi

  if [[ $VKPR_ENV_VAULT_MODE == "raft" ]]; then
  YQ_VALUES=''$YQ_VALUES' |
    .server.ha.raft.enabled = true
  '
    printf 'storage "raft" {
  path = "/vault/data"
  performance_multiplier = 1
}' >> $VKPR_VAULT_CONFIG
    else
    printf 'storage "consul" {
  path = "vault"
  address = "consul-consul-server.vkpr.svc.cluster.local:8500"
}' >> $VKPR_VAULT_CONFIG
  fi

  mergeVkprValuesHelmArgs "vault" $VKPR_VAULT_VALUES
}

installVault() {
  echoColor "bold" "$(echoColor "green" "Installing Vault...")"
  local YQ_VALUES='.global.enabled = true'
  settingVault
  $VKPR_YQ eval "$YQ_VALUES" "$VKPR_VAULT_VALUES" \
  | $VKPR_HELM upgrade -i --version "$VKPR_VAULT_VERSION" \
      --namespace $VKPR_K8S_NAMESPACE --create-namespace \
      --wait -f - vault hashicorp/vault
  echoColor "bold" "$(echoColor "green" "Creating storage config...")"
  $VKPR_KUBECTL create secret generic vault-storage-config -n $VKPR_K8S_NAMESPACE --from-file=$VKPR_VAULT_CONFIG
}