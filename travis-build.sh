#!/usr/bin/env bash

#Notif another build
trigger(){

  if [ -f ./trigger-build.sh ]; then
    . ./trigger-build.sh $1 $2
  fi
}

build_only_project()
{
  version=$1
  project=$2
  dockerfilePath=$3

  docker build -t "synker/${project}:${version}" -t "synker/${project}:latest" --build-arg version=$version -f $dockerfilePath .
  docker push "synker/${project}"
  trigger "Fazzani/synker-docker"
}

set -evuxo
echo "$TRAVIS_TAG"
if [ -z "$TRAVIS_TAG" ]; then
  echo "Isn't a Docker build";
  exit 0
fi

if [[ "$DOCKER_BUILD" == true ]]; then
  echo "Is a Docker build";
  docker login -u=$DOCKER_USER -p=$DOCKER_PASS
  export version=$TRAVIS_TAG
  
  # si le message contient build_webclient alors on build uniquement l'admin ui
  if [[ $TRAVIS_COMMIT_MESSAGE == *"build_admin"* ]]; then
    build_only_project $version "adminidp" "src/SynkerIdpAdminUI.Admin/Dockerfile"
	exit 0
  fi

  # si le message contient build_webapi alors on build uniquement l'idp
  if [[ $TRAVIS_COMMIT_MESSAGE == *"build_idp"* ]]; then
    build_only_project $version "idp" "src/SynkerIdpAdminUI.STS.Identity/Dockerfile"
	exit 0
  fi

  # build image with github tag version
  docker-compose build
  docker-compose push

 # build image with latest tag version
  export version="latest"
  docker-compose build
  docker-compose push
  
  trigger "Fazzani/synker-docker" $TRAVIS_TAG
  
  exit 0
fi

exit 0