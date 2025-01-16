#!/bin/bash

# Set the base path for Repo
base_path="/home/user/repos/"

# Read config.txt line by line
while IFS= read -r line; do
    # Extract Repo, Subdomain, and Port from the line
    repo_name=$(echo "$line" | awk -F', ' '{print $1}' | cut -d' ' -f2)
    subdomain=$(echo "$line" | awk -F', ' '{print $2}' | cut -d' ' -f2)
    port=$(echo "$line" | awk -F', ' '{print $3}' | cut -d' ' -f2)

    # Create Repo directory if it doesn't exist
    repo_dir="$base_path/$repo_name"
    mkdir -p "$repo_dir"

    # Create Dockerfile content
    dockerfile_content="FROM nginx:latest\n\
    
    COPY . /usr/share/nginx/html\n\
    WORKDIR /usr/share/nginx/html\n\
    CMD [\"nginx\", \"-g\", \"daemon off;\"]"

    # Create Dockerfile if it doesn't exist
    dockerfile_path="$repo_dir/Dockerfile-new"
    echo -e "$dockerfile_content" > "$dockerfile_path"

    # Create Docker run script content
    docker_run_content="#!/bin/sh\n\
    git checkout dev-01\n\
    git pull origin dev-01\n\
    docker stop dev-$repo_name || true && docker rm dev-$repo_name || true\n\
    docker build -t dev-$repo_name -f Dockerfile-new .\n\
    docker run --net=host -e PORT=$port -d -p $port:$port --name dev-$repo_name dev-$repo_name\n\
    sleep 5\n\
    docker ps -a\n\
    docker logs --tail 100 dev-$repo_name"

    # Create Docker run script if it doesn't exist
    docker_run_path="$repo_dir/docker_dev_run.sh"
    echo -e "$docker_run_content" > "$docker_run_path"

done < config.txt

# Set permissions for Dockerfile-new and docker.sh
find "$base_path" -name Dockerfile-new -exec chmod 777 {} \;
find "$base_path" -name docker_dev_run.sh -exec chmod 777 {} \;

echo "Dockerfiles and Docker run scripts generated successfully."
