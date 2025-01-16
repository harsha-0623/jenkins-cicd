#!/bin/bash

# Specify the full path to repo.txt file
repo_txt_path="/home/user/repos/repo_list.txt"

# Check if repo.txt file exists
if [ ! -f "$repo_txt_path" ]; then
    echo "Error: repo.txt file not found at $repo_txt_path."
    exit 1
fi

# Create config file if it doesn't exist
touch config.txt

# Initialize counter if not already set
counter=${counter:-1000}

# Loop through each repo in repo.txt
while IFS= read -r repo_url; do
    # Extract repository name from the URL
    repo_name=$(basename -s .git "$repo_url")

    # Check if the repo entry already exists in config.txt
    if grep -q "Repo: $repo_name," config.txt; then
        echo "Repo: $repo_name already exists in config.txt"
    else
        # Create a subdomain as "randomsubdomain.nextcx.ai"
        subdomain="randomsubdomain"

        # Append to the config file with the current counter value
        echo "Repo: $repo_name, Subdomain: $subdomain.demo.ai, Port: $counter" >> config.txt
        echo "Repo: $repo_name, Subdomain: $subdomain.demo.ai, Port: $counter added to config.txt"

        # Increment the counter for the next iteration
        ((counter++))
    fi
done < "$repo_txt_path"

echo "Config file updated successfully: config.txt"
