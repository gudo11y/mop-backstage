#!/bin/bash

local_registry="localhost:5005"

cd mop-backstage

yarn install --immutable
yarn tsc
yarn build:backend

# eval $(minikube docker-env)

# # Build the Docker image
docker buildx build . -f packages/backend/Dockerfile --push --tag "$local_registry/backstage/backstage:latest"
# # Tag and push to local minikube registry
# # docker tag backstage:latest "$local_registry/backstage:latest"
# # docker push "$local_registry/backstage/backstage:latest"

# echo "Docker image built and pushed to $local_registry/backstage/backstage:latest"