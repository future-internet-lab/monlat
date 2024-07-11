#!/bin/bash

#####CONFIG HERE#####
DOCKERHUB="bonavadeur"
TAG="v2"
NAME="monlat-agent" # docker.io/$DOCKERHUB/$NAME:$TAG
#####################

GREEN="\e[32m"
NC="\e[0m"
OPTION=$1
logSuccess() { echo -e "$GREEN-----$message-----$NC";}

buildImage() {
    image=$(docker images | grep $NAME | awk '{print $1}'):$TAG
    docker rmi $image
    message="Remove old image success" && logSuccess
    docker build -t $DOCKERHUB/$NAME:$TAG .
    message="Build Success" && logSuccess
}

pushImage() {
    image=$(docker images | grep $NAME | grep $TAG | awk '{print $1}'):$TAG
    docker push $image
    message="Push Success" && logSuccess
}

if [ $OPTION == "image" ]; then
    buildImage
elif [ $OPTION == "push" ]; then
    pushImage
elif [ $OPTION == "ful" ]; then
    buildImage
    pushImage
fi
