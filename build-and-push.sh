#!/bin/bash

# Build and Push Docker Image to ECR
# This script builds the 2048 game Docker image and pushes it to Amazon ECR

set -e

# Configuration
# Account ID is fetched dynamically so it is never hardcoded
AWS_REGION="us-east-1"
IMAGE_TAG="latest"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/game2048-production"

echo "================================================"
echo "Building and Pushing 2048 Game to ECR"
echo "================================================"
echo "Repository: $ECR_REPOSITORY_URI"
echo "Region: $AWS_REGION"
echo "Tag: $IMAGE_TAG"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

# Authenticate Docker to ECR
echo "Step 1: Authenticating Docker with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI

if [ $? -ne 0 ]; then
    echo "Error: Failed to authenticate with ECR"
    exit 1
fi
echo "✓ Authentication successful"
echo ""

# Build the Docker image
echo "Step 2: Building Docker image..."
cd app
docker build -t game2048:$IMAGE_TAG .

if [ $? -ne 0 ]; then
    echo "Error: Failed to build Docker image"
    exit 1
fi
echo "✓ Docker image built successfully"
echo ""

# Tag the image for ECR
echo "Step 3: Tagging image for ECR..."
docker tag game2048:$IMAGE_TAG $ECR_REPOSITORY_URI:$IMAGE_TAG
docker tag game2048:$IMAGE_TAG $ECR_REPOSITORY_URI:build-$(date +%Y%m%d-%H%M%S)
echo "✓ Image tagged"
echo ""

# Push to ECR
echo "Step 4: Pushing image to ECR..."
docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
docker push $ECR_REPOSITORY_URI:build-$(date +%Y%m%d-%H%M%S)

if [ $? -ne 0 ]; then
    echo "Error: Failed to push image to ECR"
    exit 1
fi
echo "✓ Image pushed to ECR successfully"
echo ""

echo "================================================"
echo "Success!"
echo "================================================"
echo "Image: $ECR_REPOSITORY_URI:$IMAGE_TAG"
echo ""
echo "To verify, run:"
echo "aws ecr describe-images --repository-name game2048-production --region $AWS_REGION"
echo ""
echo "✓ Step 2 completed successfully!"
