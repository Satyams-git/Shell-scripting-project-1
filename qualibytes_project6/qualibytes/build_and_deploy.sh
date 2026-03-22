#!/bin/bash
# ============================================================
# Script Name  : build_and_deploy.sh
# Description  : React app build karke Nginx pe deploy karta hai
#                Server pe hi run hota hai — koi scp nahi
# Author       : Qualibytes IT Academy
# Usage        : bash build_and_deploy.sh
# ============================================================

# ── Color codes ──
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
  if [ $? -ne 0 ]; then
    log_error "$1 FAILED. Script rok raha hai."
    exit 1
  fi
}

# ─────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}============================================${RESET}"
echo -e "${BOLD}  Qualibytes — Build & Deploy Script${RESET}"
echo -e "${BOLD}${CYAN}============================================${RESET}"
echo ""

# ─────────────────────────────────────────────
# Step 1: Check — package.json hai?
# ─────────────────────────────────────────────
log_info "Step 1: Project folder check kar raha hai..."

if [ ! -f "package.json" ]; then
  log_error "package.json nahi mila!"
  log_warn  "Script ko React project folder se chalao:"
  log_warn  "cd ~/Shell-scripting-project-1/qualibytes_project6/qualibytes"
  log_warn  "bash build_and_deploy.sh"
  exit 1
fi

log_success "package.json mila — sahi folder hai."

# ─────────────────────────────────────────────
# Step 2: npm install
# ─────────────────────────────────────────────
log_info "Step 2: npm install chal raha hai..."

npm install --silent
check_error "npm install"

log_success "npm packages install ho gaye."

# ─────────────────────────────────────────────
# Step 3: npm run build
# ─────────────────────────────────────────────
log_info "Step 3: React app build ho raha hai (1-2 min)..."

export NODE_OPTIONS="--max-old-space-size=512"
npm run build
check_error "npm run build"

BUILD_SIZE=$(du -sh build | cut -f1)
log_success "React app build ho gaya! Size: $BUILD_SIZE"

# ─────────────────────────────────────────────
# Step 4: Build files web root pe copy karo
# ─────────────────────────────────────────────
log_info "Step 4: Build files /var/www/qualibytes me copy kar raha hai..."

sudo rm -rf /var/www/qualibytes/*
sudo cp -r build/. /var/www/qualibytes/
check_error "Copy to web root"

sudo chown -R www-data:www-data /var/www/qualibytes
sudo chmod -R 755 /var/www/qualibytes

FILE_COUNT=$(find /var/www/qualibytes -type f | wc -l)
log_success "$FILE_COUNT files copy ho gayi — /var/www/qualibytes me."

# ─────────────────────────────────────────────
# Step 5: Nginx reload
# ─────────────────────────────────────────────
log_info "Step 5: Nginx reload kar raha hai..."

sudo nginx -t
check_error "Nginx config test"

sudo systemctl reload nginx
check_error "Nginx reload"

log_success "Nginx reload ho gaya."

# ─────────────────────────────────────────────
# Step 6: Nginx status check
# ─────────────────────────────────────────────
log_info "Step 6: Nginx status check kar raha hai..."

if systemctl is-active --quiet nginx; then
  log_success "Nginx chal raha hai."
else
  log_error "Nginx nahi chal raha — check karo: sudo journalctl -xe"
  exit 1
fi

# ─────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────
EC2_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

echo ""
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo -e "${BOLD}${GREEN}  Build & Deploy COMPLETE! 🚀${RESET}"
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo ""
if [ -n "$EC2_IP" ]; then
  echo -e "  ${CYAN}Website live hai:${RESET} ${BOLD}http://$EC2_IP${RESET}"
else
  echo -e "  ${CYAN}Website live hai:${RESET} ${BOLD}http://YOUR-EC2-PUBLIC-IP${RESET}"
fi
echo -e "  ${CYAN}Files at:${RESET}        /var/www/qualibytes ($FILE_COUNT files)"
echo -e "  ${CYAN}Nginx:${RESET}           $(systemctl is-active nginx)"
echo ""
