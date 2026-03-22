#!/bin/bash
# ============================================================
# Script Name  : server_setup.sh
# Description  : EC2 server pe Node.js aur Nginx install karta hai
#                Qualibytes IT Academy ke React app ke liye
# Author       : Qualibytes IT Academy
# Usage        : bash server_setup.sh
# ============================================================

# ── Color codes for pretty output ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Logging functions ──
log_info()    { echo -e "${CYAN}[INFO]${RESET}  $1"; }
log_success() { echo -e "${GREEN}[✔ OK]${RESET}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# ── Check last command succeeded, nahi to exit ──
check_error() {
  if [ $? -ne 0 ]; then
    log_error "$1 FAILED. Exiting."
    exit 1
  fi
}

# ─────────────────────────────────────────────
# Welcome banner
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}============================================${RESET}"
echo -e "${BOLD}  Qualibytes IT Academy — Server Setup Script${RESET}"
echo -e "${BOLD}${CYAN}============================================${RESET}"
echo ""

# ─────────────────────────────────────────────
# Step 1: Root check
# ─────────────────────────────────────────────
log_info "Step 1: Checking if script is running as root..."

if [ "$EUID" -ne 0 ]; then
  log_error "Please run this script as root or with sudo"
  log_warn  "Example: sudo bash server_setup.sh"
  exit 1
fi

log_success "Running as root. Proceeding..."

# ─────────────────────────────────────────────
# Step 2: System update
# ─────────────────────────────────────────────
log_info "Step 2: Updating system packages (apt update)..."

apt update -y > /dev/null 2>&1
check_error "System update"

apt upgrade -y > /dev/null 2>&1
check_error "System upgrade"

log_success "System packages updated successfully."

# ─────────────────────────────────────────────
# Step 3: Install curl (nvm ke liye chahiye)
# ─────────────────────────────────────────────
log_info "Step 3: Installing curl..."

apt install -y curl > /dev/null 2>&1
check_error "curl installation"

log_success "curl installed."

# ─────────────────────────────────────────────
# Step 4: Install Node.js via NodeSource (v20 LTS)
# ─────────────────────────────────────────────
log_info "Step 4: Installing Node.js v20 LTS..."

curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
check_error "NodeSource setup"

apt install -y nodejs > /dev/null 2>&1
check_error "Node.js installation"

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
log_success "Node.js $NODE_VERSION installed."
log_success "npm $NPM_VERSION installed."

# ─────────────────────────────────────────────
# Step 5: Install Nginx
# ─────────────────────────────────────────────
log_info "Step 5: Installing Nginx web server..."

apt install -y nginx > /dev/null 2>&1
check_error "Nginx installation"

log_success "Nginx installed."

# ─────────────────────────────────────────────
# Step 6: Create web root directory
# ─────────────────────────────────────────────
log_info "Step 6: Creating web root directory /var/www/qualibytes..."

mkdir -p /var/www/qualibytes
check_error "mkdir /var/www/qualibytes"

# Ubuntu user ko permission do
chown -R www-data:www-data /var/www/qualibytes
chmod -R 755 /var/www/qualibytes

log_success "Web root directory ready at /var/www/qualibytes"

# ─────────────────────────────────────────────
# Step 7: Write Nginx config file
# ─────────────────────────────────────────────
log_info "Step 7: Writing Nginx configuration for Qualibytes..."

# Cat command se heredoc use karke config file likhte hain
cat > /etc/nginx/sites-available/qualibytes << 'NGINX_CONF'
server {
    listen 80;
    listen [::]:80;

    server_name _;                        # Koi bhi IP ya domain accept karo

    root /var/www/qualibytes;             # React build files yahan hain
    index index.html;

    # React Router ke liye zaroori: har route index.html pe redirect karo
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Static assets ko cache karo (performance ke liye)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression enable karo (faster loading)
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 256;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
}
NGINX_CONF

check_error "Nginx config write"
log_success "Nginx config written to /etc/nginx/sites-available/qualibytes"

# ─────────────────────────────────────────────
# Step 8: Enable the site (symlink banana)
# ─────────────────────────────────────────────
log_info "Step 8: Enabling Qualibytes site in Nginx..."

# Pehle default site disable karo
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
  log_info "Default Nginx site disabled."
fi

# Qualibytes site enable karo (symlink)
ln -sf /etc/nginx/sites-available/qualibytes /etc/nginx/sites-enabled/qualibytes
check_error "Nginx symlink"

log_success "Qualibytes site enabled in Nginx."

# ─────────────────────────────────────────────
# Step 9: Test Nginx config
# ─────────────────────────────────────────────
log_info "Step 9: Testing Nginx configuration..."

nginx -t
check_error "Nginx config test"

log_success "Nginx config is valid."

# ─────────────────────────────────────────────
# Step 10: Start & enable Nginx
# ─────────────────────────────────────────────
log_info "Step 10: Starting Nginx service..."

systemctl start nginx
check_error "Nginx start"

systemctl enable nginx > /dev/null 2>&1
check_error "Nginx enable"

# Check if Nginx is running
if systemctl is-active --quiet nginx; then
  log_success "Nginx is running and enabled on startup."
else
  log_error "Nginx failed to start. Check: journalctl -xe"
  exit 1
fi

# ─────────────────────────────────────────────
# Step 11: Firewall — port 80 open karo
# ─────────────────────────────────────────────
log_info "Step 11: Configuring UFW firewall..."

if command -v ufw &> /dev/null; then
  ufw allow 'Nginx HTTP' > /dev/null 2>&1
  ufw allow 22 > /dev/null 2>&1           # SSH band mat karo!
  log_success "Firewall rules set — ports 22 (SSH) and 80 (HTTP) open."
else
  log_warn "UFW not found. Make sure EC2 Security Group has port 80 open."
fi

# ─────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo -e "${BOLD}${GREEN}  Server Setup COMPLETE! ✔${RESET}"
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo ""
echo -e "  ${CYAN}Node.js version:${RESET}  $(node --version)"
echo -e "  ${CYAN}npm version:${RESET}      $(npm --version)"
echo -e "  ${CYAN}Nginx status:${RESET}     $(systemctl is-active nginx)"
echo -e "  ${CYAN}Web root:${RESET}         /var/www/qualibytes"
echo ""
echo -e "  ${YELLOW}Next step:${RESET} Run ${BOLD}./deploy.sh${RESET} from your local machine to deploy the app!"
echo ""
