#!/bin/bash

cd mop-backstage

yarn install --immutable
yarn tsc
yarn build:backend

# Build the Docker image
docker image build . -f packages/backend/Dockerfile --tag backstage:latest

# Tag and push to local minikube registry
docker tag backstage:latest minikube-registry:5000/backstage:latest
docker push minikube-registry:5000/backstage:latest

echo "Docker image built and pushed to minikube-registry:5000/backstage:latest"