#!/bin/bash

set -e

# repository configuration
REPO_URL="https://github.com/Satyams-git/Shell-scripting-project-1.git"
REPO_NAME="Shell-scripting-project-1"

# base and project directory
BASE_DIR="$(pwd)"
PROJECT_DIR="$BASE_DIR/$REPO_NAME/qualibytes_project6/qualibytes"

echo "Starting deployment..."

# clone or update repository
if [ ! -d "$REPO_NAME" ]; then
  git clone "$REPO_URL"
else
  cd "$REPO_NAME"
  git pull
  cd "$BASE_DIR"
fi

# move to project directory
cd "$PROJECT_DIR"

# install dependencies
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps #> /dev/null 2>&1

# fix ajv dependency issue
npm install ajv@6 ajv-keywords@3 --legacy-peer-deps > /dev/null 2>&1

# build project
export NODE_OPTIONS="--max-old-space-size=512"
npm run build

# deploy build files
sudo rm -rf /var/www/qualibytes/*
sudo cp -r build/. /var/www/qualibytes/

# set permissions
sudo chown -R www-data:www-data /var/www/qualibytes
sudo chmod -R 755 /var/www/qualibytes

# reload nginx
sudo nginx -t
sudo systemctl reload nginx

echo "Deployment completed"