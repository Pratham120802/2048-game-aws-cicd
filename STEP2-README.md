# Step 2: Containerize the 2048 Game and Push to ECR

This step creates a Docker container for the 2048 game and pushes it to Amazon ECR.

## 📁 Files Structure

```
app/
├── Dockerfile          # Docker container definition
├── nginx.conf          # Nginx web server configuration
├── index.html          # 2048 game HTML
├── js/                 # JavaScript game logic
├── style/              # CSS styles
└── meta/               # Icons and metadata

build-and-push.bat      # Windows script to build and push
build-and-push.sh       # Linux/Mac script to build and push
```

## 🐳 Dockerfile Overview

The Dockerfile:
- Uses **nginx:alpine** as base image (lightweight)
- Copies the 2048 game files to nginx web root
- Configures nginx to serve the static files
- Exposes port 80
- Includes health check endpoint at `/health`

## 📋 Prerequisites

1. ✅ **Step 1 completed** - ECR repository created
2. ✅ **Docker Desktop installed** and running
   - Download from: https://www.docker.com/products/docker-desktop
3. ✅ **AWS CLI configured** with credentials

## 🚀 Build and Push to ECR

### Windows (PowerShell or CMD):

```cmd
# Make sure you're in the project root
cd c:\Users\prath\Desktop\aws_p1

# Run the build script
.\build-and-push.bat
```

### Linux/Mac:

```bash
# Make the script executable
chmod +x build-and-push.sh

# Run the build script
./build-and-push.sh
```

## 🔧 Manual Build Steps

If you prefer to run commands manually:

### 1. Authenticate Docker with ECR

```cmd
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 825184644172.dkr.ecr.us-east-1.amazonaws.com/game2048-production
```

### 2. Build the Docker Image

```cmd
cd app
docker build -t game2048:latest .
cd ..
```

### 3. Tag the Image

```cmd
docker tag game2048:latest 825184644172.dkr.ecr.us-east-1.amazonaws.com/game2048-production:latest
```

### 4. Push to ECR

```cmd
docker push 825184644172.dkr.ecr.us-east-1.amazonaws.com/game2048-production:latest
```

## ✅ Verify the Push

Check that the image is in ECR:

```cmd
aws ecr describe-images --repository-name game2048-production --region us-east-1
```

You should see output like:

```json
{
    "imageDetails": [
        {
            "imageDigest": "sha256:...",
            "imageTags": ["latest", "build-20260612-..."],
            "imagePushedAt": "2026-06-12T...",
            "imageSizeInBytes": 12345678
        }
    ]
}
```

## 🧪 Test Locally (Optional)

Before pushing to ECR, you can test the container locally:

```cmd
# Run the container
docker run -d -p 8080:80 game2048:latest

# Open browser to http://localhost:8080

# Stop the container when done
docker ps
docker stop <container-id>
```

## 🔍 Troubleshooting

### Docker not running
```
Error: Docker is not running
```
**Solution**: Start Docker Desktop

### Authentication fails
```
Error: Failed to authenticate with ECR
```
**Solution**: 
- Check AWS credentials: `aws sts get-caller-identity`
- Verify ECR repository exists: `aws ecr describe-repositories`

### Build fails
```
Error: Failed to build Docker image
```
**Solution**:
- Ensure you're in the project root directory
- Check that `app/Dockerfile` exists
- Verify all game files are in the `app/` directory

### Push fails
```
Error: Failed to push image to ECR
```
**Solution**:
- Re-authenticate with ECR
- Check network connectivity
- Verify IAM permissions for ECR push

## 📊 Image Details

- **Base Image**: nginx:alpine (~23 MB)
- **Final Image**: ~25-30 MB
- **Port**: 80
- **Health Check**: GET /health

## 🔒 Security Features

The nginx configuration includes:
- Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- Gzip compression for faster loading
- Cache control for static assets
- Health check endpoint for ECS

## 📝 Image Tags

The script creates two tags:
1. **latest** - Always points to the most recent build
2. **build-YYYYMMDD-HHMMSS** - Timestamped for version tracking

Example:
- `825184644172.dkr.ecr.us-east-1.amazonaws.com/game2048-production:latest`
- `825184644172.dkr.ecr.us-east-1.amazonaws.com/game2048-production:build-20260612-143022`

## 🎯 What's Next?

After completing Step 2, you're ready for:
- **Step 3**: Create ECS Task Definition and Service to run the container
- **Step 4**: Set up Application Load Balancer
- **Step 5**: Configure CodeBuild and CodePipeline for CI/CD

## 💰 Costs

- **ECR Storage**: $0.10 per GB-month
  - Expected: ~$0.003/month for one image (~30 MB)
- **Data Transfer**: Free for uploads to ECR
- **Docker Desktop**: Free for personal use

---

**Step 2 Status**: ✅ Ready to deploy

Once you run the build script successfully, the Docker image will be in ECR and ready to be deployed to ECS!
