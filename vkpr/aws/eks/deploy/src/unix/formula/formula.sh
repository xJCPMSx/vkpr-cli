#!/bin/sh

runFormula() {
  validateGitlabUsername $GITLAB_USERNAME
  validateGitlabToken $GITLAB_TOKEN
  
  local PROJECT_ID=$(curl https://gitlab.com/api/v4/users/$GITLAB_USERNAME/projects | $VKPR_JQ '.[0] | .id')
  local BUILD_COMPLETE=$(curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs | $VKPR_JQ '.[2] | .status')
  waitPipelineComplete
  runDeploy
}

waitPipelineComplete(){
  SECONDS=0
  while [[ $BUILD_COMPLETE != '"success"' ]]; do
    echoColor "yellow" "Pipeline still executing, await more... ${SECONDS}s passed"
    sleep 30
    let "SECONDS+30"
    BUILD_COMPLETE=$(curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs | $VKPR_JQ '.[2] | .status')
  done
}

runDeploy(){
  local DEPLOY_ID=$(curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs | $VKPR_JQ '.[1] | .id')
  curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -X POST -s https://gitlab.com/api/v4/projects/$PROJECT_ID/jobs/$DEPLOY_ID/play > /dev/null
}