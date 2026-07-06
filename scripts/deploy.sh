#!/bin/bash
set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-640471340191}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/gojocalories/api"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "Ensuring AWS Copilot CLI is installed..."
if ! command -v copilot &> /dev/null; then
    echo "AWS Copilot not found. Installing locally..."
    mkdir -p .bin
    curl -Lo .bin/copilot https://github.com/aws/copilot-cli/releases/latest/download/copilot-linux
    chmod +x .bin/copilot
    export PATH="$PWD/.bin:$PATH"
fi

echo "Initializing Copilot Application..."
# 1. Initialize the app and the web service manifest (without deploying yet)
copilot init \
  --app gojocalories \
  --name api \
  --type "Load Balanced Web Service" \
  --dockerfile backend/Dockerfile \
  --port 5000

echo "Initializing Production Environment..."
# 2. Init Environment
copilot env init --name prod --profile default --default-config || true

echo "Initializing Storage (PostgreSQL Aurora)..."
# 3. Environment-level Aurora addon (skip if copilot/environments/addons/gojodb.yml already exists)
if [ ! -f copilot/environments/addons/gojodb.yml ]; then
  copilot storage init \
    --name gojodb \
    --storage-type Aurora \
    --lifecycle environment \
    --engine PostgreSQL \
    --initial-db gojocalories || true
fi

echo "Building and pushing container image..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
docker build -t "${ECR_REPO}:${IMAGE_TAG}" -f backend/Dockerfile backend
docker push "${ECR_REPO}:${IMAGE_TAG}"

echo "Deploying Environment..."
# 4. Deploy the Environment (sets up VPC, ECS Cluster, etc.)
copilot env deploy --name prod

echo "Deploying the API Service..."
# 5. Deploy the Service (uses image.location from manifest.yml)
copilot deploy --name api --env prod

echo "Deployment completed successfully!"
