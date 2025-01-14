#!/bin/bash

runFormula() {
  echoColor "bold" "$(echoColor "green" "Removing Vault...")"
  $VKPR_HELM uninstall vault -n $VKPR_K8S_NAMESPACE
  $VKPR_KUBECTL delete secret vault-storage-config -n $VKPR_K8S_NAMESPACE
  $VKPR_KUBECTL delete secret aws-unseal-vault -n $VKPR_K8S_NAMESPACE
  #$VKPR_KUBECTL delete pvc -l app.kubernetes.io/instance=vault -n $VKPR_K8S_NAMESPACE
}
