#!/bin/bash
set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-640471340191}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/gojocalories/admin"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "Building and pushing admin panel image..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Create ECR repo if it doesn't exist
aws ecr describe-repositories --repository-names gojocalories/admin --region "$AWS_REGION" 2>/dev/null || \
  aws ecr create-repository --repository-name gojocalories/admin --region "$AWS_REGION"

docker build \
  --build-arg NEXT_PUBLIC_API_URL=https://api.gojocalories.com/api \
  -t "${ECR_REPO}:${IMAGE_TAG}" \
  -f admin/Dockerfile \
  admin

docker push "${ECR_REPO}:${IMAGE_TAG}"

echo "Deploying admin service..."
copilot deploy --name admin --env prod --force

echo "Admin panel deployed to https://admin.gojocalories.com"
