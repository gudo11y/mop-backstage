#!/bin/bash
set -e

local_registry="localhost:5005"

cd mop-backstage

# Ensure GitHub credentials file exists (placeholder for local dev)
if [ ! -f "github-app-mop-backstage-credentials.yaml" ]; then
    echo "Creating placeholder GitHub app credentials file..."
    cat > github-app-mop-backstage-credentials.yaml <<EOF
# GitHub App credentials placeholder for local development
# Replace with actual credentials or decrypt the .age file for production

appId: 1
clientId: placeholder-client-id
clientSecret: placeholder-client-secret
webhookSecret: placeholder-webhook-secret
privateKey: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEAplaceholder
  -----END RSA PRIVATE KEY-----
EOF
fi

echo "Installing dependencies..."
yarn install --immutable

echo "Type checking..."
yarn tsc

echo "Building all packages (this creates the backend bundles)..."
yarn build:all

echo "Building and pushing Docker image..."
docker buildx build . -f packages/backend/Dockerfile --push --tag "$local_registry/backstage:latest"

echo "Docker image built and pushed to $local_registry/backstage:latest"