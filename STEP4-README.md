# Step 4: Set up AWS CodePipeline

This final step creates the complete CI/CD pipeline that automatically builds and deploys your application.

## 🎯 What Gets Created

Step 4 consists of TWO parts:

### Part A: ECS Service Infrastructure
- **VPC** with public subnets across 2 availability zones
- **Application Load Balancer** (makes your app accessible from internet)
- **ECS Task Definition** (defines how to run your container)
- **ECS Service** (keeps your container running)
- **Security Groups** (firewall rules)

### Part B: CodePipeline
- **AWS CodePipeline** (orchestrates the entire CI/CD workflow)
- **GitHub Integration** (monitors your repository)
- **Automated Deployment** (deploys changes automatically)

## 📋 Prerequisites

Before deploying Step 4:

1. ✅ **Step 1 completed** - ECR & ECS Cluster
2. ✅ **Step 2 completed** - Docker image in ECR
3. ✅ **Step 3 completed** - CodeBuild project
4. ✅ **Code pushed to GitHub**
5. 🆕 **GitHub Personal Access Token** (required for CodePipeline)

## 🔑 Create GitHub Personal Access Token

CodePipeline needs a token to access your GitHub repository:

### Steps:
1. Go to: **https://github.com/settings/tokens**
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Name: `AWS-CodePipeline`
4. Expiration: Choose `90 days` or `No expiration`
5. **Scopes**: Check **`repo`** (full control of private repositories)
6. Click **"Generate token"**
7. **IMPORTANT**: Copy the token immediately (you won't see it again!)

Keep this token ready - you'll need it during deployment.

## 🚀 Deployment Steps

### Step 4A: Deploy ECS Service

First, deploy the ECS service and load balancer:

```cmd
cd c:\Users\prath\Desktop\aws_p1\cloudformation
.\deploy-step3b-ecs-service.bat
```

**What happens:**
- Creates VPC and networking (2-3 minutes)
- Creates Application Load Balancer (2-3 minutes)
- Creates ECS Service (1-2 minutes)
- **Total time: ~5-10 minutes**

**Expected output:**
```
Application URL: http://game2048-alb-production-XXXXXXXX.us-east-1.elb.amazonaws.com
```

### Step 4B: Deploy CodePipeline

After ECS Service is running, deploy the pipeline:

```cmd
.\deploy-step4-codepipeline.bat
```

**You'll be prompted for:**
```
Enter GitHub repository (format: username/repo-name): Pratham120802/2048-game-aws-cicd
Enter GitHub branch [main]: main
Paste your GitHub token: ghp_XXXXXXXXXXXXXXXXXXXX
```

**What happens:**
- Creates CodePipeline (1 minute)
- Connects to GitHub (automatic)
- Starts initial pipeline execution (5-8 minutes)

## 🔄 How the Pipeline Works

Once deployed, the pipeline automatically:

```
1. GitHub Push
   ↓
2. CodePipeline Detects Change
   ↓
3. Source Stage: Downloads code from GitHub
   ↓
4. Build Stage: CodeBuild builds Docker image
   ↓
5. Build Stage: Pushes image to ECR
   ↓
6. Deploy Stage: ECS updates with new image
   ↓
7. Done! New version is live
```

## 🧪 Test the Pipeline

### Test 1: Manual Verification

Check the pipeline status:

```cmd
# View pipeline
aws codepipeline get-pipeline-state --name game2048-pipeline-production
```

Or visit the AWS Console:
```
https://console.aws.amazon.com/codesuite/codepipeline/pipelines/game2048-pipeline-production/view
```

### Test 2: Make a Code Change

Let's trigger the pipeline by making a change:

```cmd
# Navigate to project
cd c:\Users\prath\Desktop\aws_p1

# Edit the game title
notepad app\index.html
```

Change the title from:
```html
<h1 class="title">2048</h1>
```

To:
```html
<h1 class="title">2048 - AWS CI/CD</h1>
```

Save and commit:

```powershell
git add app/index.html
git commit -m "Update game title"
git push
```

**Watch the pipeline:**
1. Go to AWS CodePipeline Console
2. You'll see the pipeline start automatically
3. Watch it go through Source → Build → Deploy
4. After ~5-8 minutes, refresh your game URL
5. You'll see the updated title!

## 📊 Pipeline Stages Explained

### Stage 1: Source
- **Trigger**: Git push to GitHub
- **Action**: Downloads source code
- **Output**: Source artifact (ZIP of your code)
- **Duration**: ~30 seconds

### Stage 2: Build
- **Input**: Source artifact
- **Action**: Runs buildspec.yml
  - Builds Docker image
  - Pushes to ECR
  - Creates imagedefinitions.json
- **Output**: Build artifact
- **Duration**: ~2-4 minutes

### Stage 3: Deploy
- **Input**: Build artifact (imagedefinitions.json)
- **Action**: Updates ECS service
  - Creates new task with new image
  - Waits for health checks
  - Stops old task
- **Duration**: ~2-3 minutes

## 🌐 Access Your Application

After deployment completes:

```cmd
# Get the Application URL
aws cloudformation describe-stacks ^
    --stack-name game2048-ecs-service ^
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" ^
    --output text
```

Open the URL in your browser to play 2048!

## 🔍 Monitoring & Logs

### View Pipeline Executions
```cmd
aws codepipeline list-pipeline-executions --pipeline-name game2048-pipeline-production
```

### View ECS Service Status
```cmd
aws ecs describe-services ^
    --cluster game2048-cluster-production ^
    --services game2048-service-production
```

### View Container Logs
```cmd
aws logs tail /ecs/game2048-production --follow
```

### View CodeBuild Logs
```cmd
aws logs tail /aws/codebuild/game2048-build-production --follow
```

## 🐛 Troubleshooting

### Pipeline fails at Source stage

**Issue**: "Could not access GitHub repository"

**Solutions**:
- Verify GitHub token has `repo` scope
- Check repository name format: `username/repo-name`
- Ensure repository exists and is accessible

### Pipeline fails at Build stage

**Issue**: Build errors in CodeBuild

**Solutions**:
```cmd
# Check build logs
aws codebuild batch-get-builds --ids <build-id>

# View detailed logs
aws logs tail /aws/codebuild/game2048-build-production --follow
```

### Pipeline fails at Deploy stage

**Issue**: ECS deployment fails

**Solutions**:
```cmd
# Check ECS service events
aws ecs describe-services ^
    --cluster game2048-cluster-production ^
    --services game2048-service-production ^
    --query "services[0].events[0:5]"

# Check task failures
aws ecs describe-tasks ^
    --cluster game2048-cluster-production ^
    --tasks <task-id>
```

### Application Load Balancer returns 503

**Issue**: No healthy targets

**Solutions**:
- Wait 2-3 minutes for ECS tasks to become healthy
- Check container logs for errors
- Verify Docker image runs correctly locally

## 🔒 Security Best Practices

1. **GitHub Token**:
   - Use token with minimal required scopes
   - Rotate tokens every 90 days
   - Store securely (CloudFormation encrypts it)

2. **IAM Roles**:
   - Pipeline uses least-privilege IAM roles
   - Separate roles for CodeBuild and ECS

3. **Network Security**:
   - ECS tasks only accept traffic from ALB
   - ALB accepts traffic from internet (port 80 only)

## 💰 Cost Breakdown

| Service | Cost | Details |
|---------|------|---------|
| **ECS Fargate** | ~$15-20/month | 0.25 vCPU, 0.5 GB RAM, always running |
| **Application Load Balancer** | ~$16/month | Always running |
| **CodePipeline** | $1/month | First pipeline free, $1 per additional |
| **CodeBuild** | ~$0.50/month | $0.005/minute × ~100 minutes |
| **ECR Storage** | ~$0.10/month | $0.10 per GB |
| **Data Transfer** | ~$1/month | Minimal for low traffic |
| **S3 Storage** | ~$0.05/month | Artifacts storage |
| **Total** | **~$33-38/month** | For always-running production app |

### Cost Optimization Tips:

1. **Use ECS Scheduled Scaling**: Scale to 0 tasks during off-hours
2. **Use Fargate Spot**: Save up to 70% on compute costs
3. **Delete old Docker images**: Lifecycle policy already configured
4. **Use CloudWatch Logs retention**: Set to 7 days (already configured)

## 🎉 What You've Accomplished

✅ **Complete CI/CD Pipeline** running on AWS  
✅ **Automated Deployments** from Git push to production  
✅ **Infrastructure as Code** - entire stack in CloudFormation  
✅ **Production-Ready Architecture** with load balancing and auto-healing  
✅ **Container Orchestration** with ECS Fargate  
✅ **Security** - IAM roles, security groups, encrypted artifacts  

## 🚀 Next Steps

Now that your pipeline is complete, you can:

1. **Customize the game**: Modify app files and push
2. **Add monitoring**: Set up CloudWatch alarms
3. **Add HTTPS**: Configure ACM certificate and HTTPS listener
4. **Add custom domain**: Route53 + ACM
5. **Add auto-scaling**: Scale ECS tasks based on load
6. **Add staging environment**: Duplicate stack with different parameters

## 📚 Additional Resources

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [Amazon ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Application Load Balancer Guide](https://docs.aws.amazon.com/elasticloadbalancing/)
- [GitHub Integration](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html)

---

**🎮 Congratulations! Your 2048 game now has a production-grade CI/CD pipeline!** 🎉
