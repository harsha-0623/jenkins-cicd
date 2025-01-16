#!/bin/bash

bitbucket_path="/home/user/repos"

# Move to the specified path
cd "$bitbucket_path"

# List all folders in the directory
folders=($(ls -d */))

# Iterate through folders and create scripts
for folder in "${folders[@]}"; do
    # Remove trailing slash from folder name
    folder_name=$(echo "$folder" | sed 's|/$||')

    # Create a new script file with 'dev-' prefix
    script_file="dev-${folder_name}.sh"
    script_content="#!/bin/bash

cd ${bitbucket_path}/${folder_name}/
git branch
git checkout dev-01
git status
git pull

       bash docker_dev_run.sh
# fi"

    # Save the content to the script file
    echo "$script_content" > "$script_file"

    # Make the script executable
    chmod +x "$script_file"

    echo "Script $script_file created."
done
