#!/bin/bash
set -e

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
# 3. Add Storage to the `api` service (Aurora PostgreSQL)
# Using 'test' environment config for demonstration, but initializing explicitly for prod later
copilot storage init \
  --name gojodb \
  --storage-type Aurora \
  --workload api \
  --engine PostgreSQL \
  --initial-db gojocalories \
  --environment prod || true

echo "Deploying Environment..."
# 4. Deploy the Environment (sets up VPC, ECS Cluster, etc.)
copilot env deploy --name prod

echo "Deploying the API Service..."
# 5. Deploy the Service (Builds Docker, Pushes to ECR, and creates ECS Service & ALB)
copilot deploy --name api --env prod

echo "Deployment completed successfully!"
