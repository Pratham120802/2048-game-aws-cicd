#!/bin/bash

# Step 1: Deploy ECS Cluster and ECR Repository
# This script creates the foundational infrastructure for the 2048 Game CI/CD Pipeline

set -e

# Configuration
STACK_NAME="game2048-ecr-ecs-setup"
PROJECT_NAME="game2048"
ENVIRONMENT="production"
TEMPLATE_FILE="01-ecr-ecs-setup.yaml"

echo "================================================"
echo "Deploying Step 1: ECS Cluster and ECR Repository"
echo "================================================"
echo "Stack Name: $STACK_NAME"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    echo "Please install it from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials are not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
echo "AWS Region: $(aws configure get region)"
echo ""

# Check if stack already exists
if aws cloudformation describe-stacks --stack-name $STACK_NAME &> /dev/null; then
    echo "Stack $STACK_NAME already exists!"
    read -p "Do you want to update it? (yes/no): " UPDATE_CHOICE
    
    if [ "$UPDATE_CHOICE" = "yes" ]; then
        echo "Updating stack..."
        aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://$TEMPLATE_FILE \
            --capabilities CAPABILITY_NAMED_IAM \
            --parameters \
                ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
                ParameterKey=Environment,ParameterValue=$ENVIRONMENT
        
        echo "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete --stack-name $STACK_NAME
        echo "✓ Stack updated successfully!"
    else
        echo "Skipping update."
        exit 0
    fi
else
    echo "Creating new stack..."
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameters \
            ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
            ParameterKey=Environment,ParameterValue=$ENVIRONMENT
    
    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
    echo "✓ Stack created successfully!"
fi

echo ""
echo "================================================"
echo "Stack Outputs:"
echo "================================================"

# Get and display stack outputs
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

echo ""
echo "================================================"
echo "Important Information:"
echo "================================================"

# Get ECR Repository URI
ECR_URI=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryUri`].OutputValue' \
    --output text)

ECS_CLUSTER=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
    --output text)

echo "ECR Repository URI: $ECR_URI"
echo "ECS Cluster Name: $ECS_CLUSTER"
echo ""
echo "Save these values for the next steps!"
echo ""
echo "To authenticate Docker with ECR, run:"
echo "aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin $ECR_URI"
echo ""
echo "✓ Step 1 completed successfully!"
