#!/bin/bash
# ============================================================
# Script Name  : deploy.sh
# Description  : GitHub se React app pull karke EC2 pe deploy
#                karta hai — scp ki zaroorat nahi!
# Author       : Qualibytes IT Academy
# Usage        : bash deploy.sh <EC2_IP> <SSH_KEY> <GITHUB_REPO_URL>
# Example      : bash deploy.sh 13.233.45.67 ~/.ssh/key.pem \
#                  https://github.com/yourname/qualibytes.git
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${RESET}  $1"; }
log_success() { echo -e "${GREEN}[✔ OK]${RESET}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1"; }
check_error() {
  if [ $? -ne 0 ]; then log_error "$1 FAILED. Deployment aborted."; exit 1; fi
}

# ── Arguments ──
EC2_IP="$1"
SSH_KEY="$2"
GITHUB_REPO="$3"

EC2_USER="ubuntu"
APP_NAME="qualibytes"
REMOTE_APP_DIR="/home/$EC2_USER/$APP_NAME"
REMOTE_WEB_DIR="/var/www/qualibytes"
BRANCH="main"

if [ -z "$EC2_IP" ] || [ -z "$SSH_KEY" ] || [ -z "$GITHUB_REPO" ]; then
  log_error "Arguments missing!"
  echo ""
  echo -e "  ${BOLD}Usage:${RESET}   bash deploy.sh <EC2_IP> <SSH_KEY> <GITHUB_REPO_URL>"
  echo -e "  ${BOLD}Example:${RESET} bash deploy.sh 13.233.45.67 ~/.ssh/key.pem https://github.com/yourname/qualibytes.git"
  echo ""
  exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
  log_error "SSH key not found: $SSH_KEY"
  exit 1
fi

echo ""
echo -e "${BOLD}${CYAN}=================================================${RESET}"
echo -e "${BOLD}  Qualibytes — GitHub to EC2 Deploy Script${RESET}"
echo -e "${BOLD}${CYAN}=================================================${RESET}"
echo ""
echo -e "  ${CYAN}EC2 Server:${RESET}  $EC2_USER@$EC2_IP"
echo -e "  ${CYAN}GitHub Repo:${RESET} $GITHUB_REPO"
echo -e "  ${CYAN}Branch:${RESET}      $BRANCH"
echo ""

# ── Step 1: SSH test ──
log_info "Step 1: EC2 se SSH connection test kar raha hai..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    "$EC2_USER@$EC2_IP" "echo ok" > /dev/null 2>&1
check_error "SSH connection"
log_success "EC2 se connection successful."

# ── Step 2: Ensure git is installed on EC2 ──
log_info "Step 2: EC2 pe git check kar raha hai..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
  "command -v git > /dev/null || sudo apt install -y git > /dev/null 2>&1"
check_error "git check on EC2"
log_success "git EC2 pe available hai."

# ── Step 3: Clone ya Pull ──
log_info "Step 3: GitHub se latest code EC2 pe la raha hai..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" bash << REMOTE
set -e
if [ -d "$REMOTE_APP_DIR/.git" ]; then
  echo "[EC2] Repo exist karta hai — git pull kar raha hai..."
  cd $REMOTE_APP_DIR
  git fetch origin
  git reset --hard origin/$BRANCH
else
  echo "[EC2] Pehli baar — git clone kar raha hai..."
  git clone $GITHUB_REPO $REMOTE_APP_DIR
  cd $REMOTE_APP_DIR
  git checkout $BRANCH
fi
echo "[EC2] Latest commit: \$(git log --oneline -1)"
REMOTE

check_error "git clone/pull on EC2"
log_success "Latest code EC2 pe aa gaya."

# ── Step 4: npm install on EC2 ──
log_info "Step 4: EC2 pe npm install chal raha hai..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" bash << REMOTE
set -e
cd $REMOTE_APP_DIR
npm install --silent
echo "[EC2] npm install done."
REMOTE

check_error "npm install on EC2"
log_success "npm packages install ho gaye."

# ── Step 5: npm run build on EC2 ──
log_info "Step 5: EC2 pe React app build ho raha hai (1-2 min)..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" bash << REMOTE
set -e
cd $REMOTE_APP_DIR
export NODE_OPTIONS="--max-old-space-size=512"
npm run build
echo "[EC2] Build size: \$(du -sh build | cut -f1)"
REMOTE

check_error "npm run build on EC2"
log_success "React app build ho gaya."

# ── Step 6: Copy build → web root ──
log_info "Step 6: Build files /var/www/qualibytes me copy kar raha hai..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" bash << REMOTE
set -e
sudo rm -rf $REMOTE_WEB_DIR/*
sudo cp -r $REMOTE_APP_DIR/build/. $REMOTE_WEB_DIR/
sudo chown -R www-data:www-data $REMOTE_WEB_DIR
sudo chmod -R 755 $REMOTE_WEB_DIR
echo "[EC2] Files: \$(find $REMOTE_WEB_DIR -type f | wc -l) files copied."
REMOTE

check_error "Copy build to web root"
log_success "Build files web root pe aa gaye."

# ── Step 7: Nginx reload ──
log_info "Step 7: Nginx reload kar raha hai..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
  "sudo nginx -t && sudo systemctl reload nginx"
check_error "Nginx reload"
log_success "Nginx reload ho gaya."

# ── Step 8: Verify ──
log_info "Step 8: Live site verify kar raha hai..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://$EC2_IP")
if [ "$HTTP_CODE" = "200" ]; then
  log_success "Site live hai! HTTP $HTTP_CODE"
else
  log_warn "HTTP status: $HTTP_CODE — manually check karo: http://$EC2_IP"
fi

# ── Step 9: Deploy log ──
COMMIT_INFO=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
  "cd $REMOTE_APP_DIR && git log --oneline -1" 2>/dev/null)

DEPLOY_LOG="deploy_$(date +%Y%m%d_%H%M%S).log"
{
  echo "========================================"
  echo " Qualibytes Deploy Log"
  echo "========================================"
  echo "Date/Time  : $(date)"
  echo "EC2 Server : $EC2_IP"
  echo "GitHub Repo: $GITHUB_REPO"
  echo "Branch     : $BRANCH"
  echo "Commit     : $COMMIT_INFO"
  echo "HTTP Status: $HTTP_CODE"
  echo "Website    : http://$EC2_IP"
  echo "========================================"
} > "$DEPLOY_LOG"
log_info "Deploy log saved: $DEPLOY_LOG"

echo ""
echo -e "${BOLD}${GREEN}=================================================${RESET}"
echo -e "${BOLD}${GREEN}  Deployment SUCCESSFUL! 🚀${RESET}"
echo -e "${BOLD}${GREEN}=================================================${RESET}"
echo ""
echo -e "  ${CYAN}Website:${RESET} ${BOLD}http://$EC2_IP${RESET}"
echo -e "  ${CYAN}Commit:${RESET}  $COMMIT_INFO"
echo ""
