# Use Nginx to serve the static 2048 game.
# Pulled from Amazon ECR Public Gallery instead of Docker Hub to avoid
# Docker Hub's anonymous pull rate limits (429 Too Many Requests) in CodeBuild.
FROM public.ecr.aws/docker/library/nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy the 2048 game files
COPY . /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
