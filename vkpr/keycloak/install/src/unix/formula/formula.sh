#!/bin/sh

runFormula() {
  PG_USER="postgres"
  PG_PASSWORD=$($VKPR_JQ -r '.credential.password' ~/.rit/credentials/default/postgres)
  PG_DATABASE_NAME="keycloak"
  PG_EXISTING_DATABASE=$(checkExistingDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME $PG_DATABASE_NAME)

  VKPR_KEYCLOAK_YAML=$(dirname "$0")/utils/keycloak.yaml
  
  
  if [ -z $(cat $VKPR_GLOBALS/.env | grep KEYCLOAK_ADMIN_USER) ] || [ -z $(cat $VKPR_GLOBALS/.env | grep KEYCLOAK_ADMIN_PASSWORD) ]; then
    VKPR_ENV_KEYCLOAK_ADMIN_USER=$ADMIN_USER
    VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD=$ADMIN_PASSWORD
    VKPR_ENV_SECURE=$SECURE
    VKPR_ENV_DOMAIN=$DOMAIN
    verifyExistingEnv 'KEYCLOAK_ADMIN_USER' "$VKPR_ENV_KEYCLOAK_ADMIN_USER" \
    'KEYCLOAK_ADMIN_PASSWORD' "$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD" \
    'SECURE' "$VKPR_ENV_SECURE" 'DOMAIN' "$VKPR_ENV_DOMAIN"
  fi

  addRepoKeycloak
  if [[ $(verifyExistingPostgres) -eq "true" ]]; then
    echoColor "yellow" "Initializing Keycloak with Postgres already created"
    VKPR_KEYCLOAK_YAML=$(dirname "$0")/utils/keycloak-db.yaml
    if [[ ! -n $PG_EXISTING_DATABASE ]]; then
      createDatabase $PG_USER $PG_PASSWORD $PG_DATABASE_NAME
    fi
    installKeycloakDB
  else
    echoColor "yellow" "There is no Postgres installed, Keycloak will generate one for your use"
    installKeycloak
  fi
}

addRepoKeycloak(){
  $VKPR_HELM repo add bitnami https://charts.bitnami.com/bitnami
  $VKPR_HELM repo update
}

verifyExistingPostgres(){
  POSTGRES=$($VKPR_KUBECTL wait --for=condition=Ready pod/postgres-postgresql-0 -o name | cut -d "/" -f2)
  if [[ $POSTGRES -eq "postgres-postgresql-0" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

installKeycloak(){
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_DOMAIN'" |
  .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" |
  .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"' "$VKPR_KEYCLOAK_YAML" \
 | $VKPR_HELM upgrade -i -f - keycloak bitnami/keycloak
}

installKeycloakDB(){
  $VKPR_YQ eval '.ingress.hosts[0].host = "'$VKPR_ENV_DOMAIN'" | .ingress.tls[0].hosts[0] = "'$VKPR_ENV_DOMAIN'" |
  .externalDatabase.host = "postgres-postgresql" | .externalDatabase.port = "5432" |
  .externalDatabase.user = "'$PG_USER'" | .externalDatabase.password = "'$PG_PASSWORD'" |
  .externalDatabase.database = "'$PG_DATABASE_NAME'" |
  .auth.adminUser = "'$VKPR_ENV_KEYCLOAK_ADMIN_USER'" | .auth.adminPassword = "'$VKPR_ENV_KEYCLOAK_ADMIN_PASSWORD'"' "$VKPR_KEYCLOAK_YAML" \
 | $VKPR_HELM upgrade -i -f - keycloak bitnami/keycloak
}