# AWS CloudFormation - Step 1: ECS Cluster and ECR Repository Setup

This CloudFormation template sets up the foundational infrastructure for the 2048 Game CI/CD Pipeline.

## Resources Created

### Amazon ECR (Elastic Container Registry)
- **ECR Repository**: Stores Docker images for the 2048 game
- **Lifecycle Policy**: Automatically keeps only the last 10 images to save storage costs
- **Image Scanning**: Enabled to scan for vulnerabilities on push

### Amazon ECS (Elastic Container Service)
- **ECS Cluster**: Using Fargate (serverless containers)
- **CloudWatch Log Group**: For container logs
- **Container Insights**: Enabled for monitoring

### IAM Roles
- **ECS Task Execution Role**: Allows ECS to pull images from ECR and write logs
- **ECS Task Role**: Application-level permissions for the running container

## Prerequisites

1. AWS CLI installed and configured
2. AWS account with appropriate permissions
3. AWS credentials configured (`aws configure`)

## Deployment Instructions

### Option 1: Using AWS CLI

```bash
# Navigate to the cloudformation directory
cd cloudformation

# Deploy the stack
aws cloudformation create-stack \
  --stack-name 2048-game-ecr-ecs-setup \
  --template-body file://01-ecr-ecs-setup.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=2048-game \
    ParameterKey=Environment,ParameterValue=production

# Monitor stack creation
aws cloudformation wait stack-create-complete \
  --stack-name 2048-game-ecr-ecs-setup

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name 2048-game-ecr-ecs-setup \
  --query 'Stacks[0].Outputs'
```

### Option 2: Using AWS Console

1. Go to AWS CloudFormation Console
2. Click **Create Stack** → **With new resources**
3. Upload the `01-ecr-ecs-setup.yaml` file
4. Enter Stack name: `2048-game-ecr-ecs-setup`
5. Configure parameters:
   - ProjectName: `2048-game`
   - Environment: `production`
6. Check **I acknowledge that AWS CloudFormation might create IAM resources with custom names**
7. Click **Create Stack**
8. Wait for stack creation to complete (Status: CREATE_COMPLETE)

## Verify Resources

After deployment, verify the resources:

```bash
# List ECR repositories
aws ecr describe-repositories --repository-names 2048-game-production

# List ECS clusters
aws ecs list-clusters

# Describe the cluster
aws ecs describe-clusters --clusters 2048-game-cluster-production
```

## Get Repository URI

You'll need the ECR repository URI for the next steps:

```bash
aws cloudformation describe-stacks \
  --stack-name 2048-game-ecr-ecs-setup \
  --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryUri`].OutputValue' \
  --output text
```

Save this URI - you'll need it for:
- Dockerfile tagging
- CodeBuild buildspec.yml
- ECS task definitions

## Stack Outputs

The stack exports these values for use in subsequent stacks:

| Output | Description | Export Name |
|--------|-------------|-------------|
| ECRRepositoryUri | Full URI for docker push/pull | 2048-game-ECRRepositoryUri-production |
| ECRRepositoryName | Repository name | 2048-game-ECRRepositoryName-production |
| ECSClusterName | ECS cluster name | 2048-game-ECSClusterName-production |
| ECSClusterArn | ECS cluster ARN | 2048-game-ECSClusterArn-production |
| ECSTaskExecutionRoleArn | IAM role for task execution | 2048-game-ECSTaskExecutionRoleArn-production |
| ECSTaskRoleArn | IAM role for application | 2048-game-ECSTaskRoleArn-production |
| ECSLogGroupName | CloudWatch log group | 2048-game-ECSLogGroupName-production |

## Clean Up

To delete the stack and all resources:

```bash
# Delete the stack
aws cloudformation delete-stack --stack-name 2048-game-ecr-ecs-setup

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name 2048-game-ecr-ecs-setup
```

⚠️ **Warning**: This will delete the ECR repository and all Docker images stored in it.

## Estimated Costs

- **ECR**: $0.10 per GB-month for storage
- **ECS Cluster**: Free (pay only for running tasks)
- **CloudWatch Logs**: $0.50 per GB ingested
- **Fargate**: Charged when tasks are running (next step)

## Next Steps

After completing Step 1, you're ready for:
- **Step 2**: Create the 2048 game application and Dockerfile
- **Step 3**: Set up CodeBuild and CodePipeline
- **Step 4**: Configure ECS Task Definition and Service

## Troubleshooting

### Stack creation fails with "IAM role already exists"
- Delete the existing IAM roles or change the ProjectName/Environment parameters

### Permission denied errors
- Ensure your AWS user/role has permissions for:
  - CloudFormation
  - ECR
  - ECS
  - IAM
  - CloudWatch Logs

### ECR repository name conflicts
- Change the ProjectName or Environment parameter to create a unique name
