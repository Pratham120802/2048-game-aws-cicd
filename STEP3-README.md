# Step 3: Create CodeBuild Project

This step creates an AWS CodeBuild project that automatically builds the Docker image from your GitHub repository.

## 🎯 What is CodeBuild?

**AWS CodeBuild** is the **BUILD** stage in your CI/CD pipeline:
- Pulls source code from GitHub
- Runs `docker build` commands
- Pushes the Docker image to ECR
- Runs automatically when triggered by CodePipeline

## 📁 Files Created

```
buildspec.yml                           # Build instructions for CodeBuild
cloudformation/02-codebuild-project.yaml  # Infrastructure template
cloudformation/deploy-step3.bat          # Deployment script
```

## 📋 buildspec.yml Phases

The buildspec defines what CodeBuild does:

1. **pre_build**: Authenticate with ECR
2. **build**: Build the Docker image
3. **post_build**: Push image to ECR and create artifact
4. **artifacts**: Output `imagedefinitions.json` for ECS

## 🚀 Prerequisites

Before deploying Step 3:

1. ✅ **Step 1 completed** - ECR repository exists
2. ✅ **Step 2 completed** - Docker image pushed to ECR
3. ✅ **GitHub repository** created with your code
4. ✅ **buildspec.yml** in the root of your repository

## 📝 Prepare Your GitHub Repository

### Option A: Create a New Repository

1. Go to https://github.com/new
2. Create a repository (e.g., `2048-game-aws`)
3. Make it **public** or **private**
4. **Don't** initialize with README

Then push your code:

```cmd
cd c:\Users\prath\Desktop\aws_p1

# Initialize git (if not already done)
git init

# Add files
git add .

# Commit
git commit -m "Initial commit - 2048 game with AWS CI/CD"

# Add remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/2048-game-aws.git

# Push to GitHub
git push -u origin main
```

### Option B: Use Existing Repository

If you already have a GitHub repository, just push the files:

```cmd
git add .
git commit -m "Add AWS CI/CD pipeline files"
git push
```

## ⚠️ Important: buildspec.yml Location

The `buildspec.yml` file **MUST** be in the **root** of your repository:

```
your-repo/
├── buildspec.yml          ← Must be here
├── app/
│   ├── Dockerfile
│   ├── index.html
│   └── ...
├── cloudformation/
└── README.md
```

## 🚀 Deploy CodeBuild Project

### Step 1: Navigate to cloudformation directory

```cmd
cd c:\Users\prath\Desktop\aws_p1\cloudformation
```

### Step 2: Run the deployment script

```cmd
.\deploy-step3.bat
```

### Step 3: Provide GitHub Information

You'll be prompted for:

```
Enter your GitHub repository URL: https://github.com/YOUR_USERNAME/2048-game-aws
Enter GitHub branch [main]: main
```

### Step 4: Wait for deployment

The script will:
- Create IAM role for CodeBuild
- Create S3 bucket for artifacts
- Create CloudWatch log group
- Create CodeBuild project
- Output the project details

## 🔐 GitHub Authentication

CodeBuild needs access to your GitHub repository. 

### For Public Repositories
No authentication needed! CodeBuild can clone public repos directly.

### For Private Repositories
You'll need to connect GitHub in the AWS Console:

1. Go to **AWS CodeBuild Console**
2. Click **Settings** → **Source providers**
3. Connect to GitHub
4. Authorize AWS CodeBuild

Or use a **GitHub Personal Access Token**:
1. Create token at: https://github.com/settings/tokens
2. Add to CodeBuild environment variables

## ✅ Verify Deployment

After deployment, check:

```cmd
# List CodeBuild projects
aws codebuild list-projects

# Get project details
aws codebuild batch-get-projects --names game2048-build-production
```

## 🧪 Test the Build

Start a manual build to test:

```cmd
aws codebuild start-build --project-name game2048-build-production
```

Monitor the build:

```cmd
# Get build ID from previous command, then:
aws codebuild batch-get-builds --ids <build-id>
```

Or watch in the AWS Console:
https://console.aws.amazon.com/codesuite/codebuild/projects

## 📊 What Gets Created

| Resource | Description |
|----------|-------------|
| **CodeBuild Project** | `game2048-build-production` |
| **IAM Role** | Permissions for ECR, S3, CloudWatch |
| **S3 Bucket** | `game2048-codebuild-artifacts-{account-id}` |
| **CloudWatch Logs** | `/aws/codebuild/game2048-build-production` |

## 🔍 Build Process Flow

```
1. CodeBuild clones GitHub repo
2. Reads buildspec.yml
3. Authenticates with ECR
4. Builds Docker image
5. Pushes to ECR
6. Creates imagedefinitions.json
7. Uploads artifact to S3
```

## 🐛 Troubleshooting

### Build fails with "Access Denied" to ECR

**Solution**: Check IAM role has ECR permissions
```cmd
aws iam get-role --role-name game2048-codebuild-*
```

### Build can't clone GitHub repository

**Solutions**:
- Verify repository URL is correct
- For private repos, set up GitHub authentication
- Check CodeBuild has internet access

### Docker build fails

**Solution**: Check buildspec.yml syntax and Docker commands
```cmd
# View build logs
aws logs tail /aws/codebuild/game2048-build-production --follow
```

### "buildspec.yml not found"

**Solution**: Ensure buildspec.yml is in repository root
```cmd
# Check your repository structure
git ls-files
```

## 📝 Environment Variables

CodeBuild automatically sets these variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `AWS_DEFAULT_REGION` | `us-east-1` | AWS region |
| `AWS_ACCOUNT_ID` | `{aws id}` | Your account |
| `ECR_REPOSITORY_URI` | `{aws id}.dkr.ecr.us-east-1.amazonaws.com/game2048-production` | ECR repo |
| `IMAGE_TAG` | `latest` | Docker tag |

## 💰 Costs

- **CodeBuild**: $0.005 per build minute (first 100 minutes/month free)
  - Expected: ~2-3 minutes per build = $0.01-0.015 per build
- **S3**: $0.023 per GB (artifacts)
  - Expected: < $0.01/month
- **CloudWatch Logs**: $0.50 per GB
  - Expected: < $0.01/month

## 🎯 What's Next - Step 4?

After Step 3, you're ready for:
- **Step 4**: Create ECS Task Definition and Service
- **Step 5**: Set up Application Load Balancer
- **Step 6**: Configure CodePipeline (connects everything!)

---

**Step 3 Status**: Ready to deploy once you have a GitHub repository! 🚀

