#!/bin/bash

set -e  # Exit on errors

# Path to your nginx.conf file
nginx_conf_path="/random/nginx/location/nginx.conf"

# Path to your config.txt file
config_file_path="/home/user/myconfigs/config.txt"

# Backup the original nginx.conf file
cp "$nginx_conf_path" "$nginx_conf_path.bak"

# Pull the latest changes from the Git repository
echo "Pulling latest changes from Git..."
cd /code/myrepo
if [[ $(git status --porcelain) ]]; then
    echo "Unstaged changes detected. Stashing changes..."
    git stash
fi
git pull origin main

# Initialize changes_made flag
changes_made=false

# Read config.txt and update nginx.conf
while IFS=, read -r repo subdomain port; do
    subdomain=$(echo "$subdomain" | cut -d ' ' -f 3 | sed 's/;//')
    port=$(echo "$port" | cut -d ' ' -f 3 | sed 's/;//')

    if grep -q "server_name $subdomain;" "$nginx_conf_path" && grep -q "proxy_pass http://localhost:$port;" "$nginx_conf_path"; then
        echo "Configuration for server_name $subdomain and proxy_pass http://localhost:$port already exists. Skipping..."
    else
        last_brace_pos=$(grep -n '}' "$nginx_conf_path" | tail -n 1 | cut -d: -f1)
        sed -i "${last_brace_pos}i \
server { \n\
    listen 80; \n\
    server_name $subdomain; \n\
    client_max_body_size 1000M; \n\
    client_body_buffer_size 1000M; \n\
    large_client_header_buffers 200 100M; \n\
    location / { \n\
        proxy_pass http://localhost:$port; \n\
        proxy_redirect off; \n\
        proxy_set_header Host \$host; \n\
        proxy_set_header X-Real-IP \$remote_addr; \n\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \n\
        proxy_set_header X-Forwarded-Host \$server_name; \n\
        proxy_http_version 1.1; \n\
        proxy_set_header Upgrade \$http_upgrade; \n\
        proxy_set_header Connection \"upgrade\"; \n\
        proxy_set_header X-Forwarded-Proto \$scheme; \n\
        proxy_read_timeout 86400; \n\
    } \n\
} \n" "$nginx_conf_path"
        echo "Configuration added for server_name $subdomain and proxy_pass http://localhost:$port."
        changes_made=true
    fi
done < "$config_file_path"

# Ensure script has execution permissions and deploy Docker containers
echo "Setting execution permissions for docker_run.sh..."
chmod +x /scripts/docker_run.sh
echo "Deploying Docker containers..."
/scripts/docker_run.sh

echo "Script execution completed successfully."

# If changes were made, commit and push the changes
if $changes_made; then
    echo "Changes detected. Committing and pushing changes to Git..."
    cd /code/myrepo
    git add .
    git commit -m "Updated nginx.conf with new proxy configurations"
    git push origin main  # Replace with the appropriate branch if necessary
    echo "Changes pushed successfully."
else
    echo "No changes detected. Skipping commit and push."
fi
