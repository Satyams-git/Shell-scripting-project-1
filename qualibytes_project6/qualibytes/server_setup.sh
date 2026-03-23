#!/bin/bash

log_info()    { echo "[INFO] $1"; }
log_success() { echo "[OK] $1"; }
log_error()   { echo "[ERROR] $1"; }

check_error() {
  if [ $? -ne 0 ]; then
    log_error "$1 failed. Exiting."
    exit 1
  fi
}

# Root check
if [ "$EUID" -ne 0 ]; then
  log_error "Run with sudo"
  exit 1
fi

# Update system
log_info "Updating system..."
apt update -y > /dev/null 2>&1
check_error "apt update"

# Install required tools
log_info "Installing curl..."
apt install -y curl ca-certificates gnupg > /dev/null 2>&1
check_error "curl install"

# -------- FULL CLEAN NODE (IMPORTANT) --------
log_info "Removing old Node and repos..."

apt purge -y nodejs > /dev/null 2>&1
apt autoremove -y > /dev/null 2>&1

# remove nodesource repos (fix main issue)
rm -f /etc/apt/sources.list.d/nodesource*.list

apt clean
apt update > /dev/null 2>&1

# -------- INSTALL NODE 18 ONLY --------
log_info "Installing Node.js 18..."

curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
check_error "NodeSource setup"

apt install -y nodejs > /dev/null 2>&1
check_error "Node install"

# Verify
NODE_VERSION=$(node -v)
log_success "Installed Node $NODE_VERSION"

# -------- INSTALL NGINX --------
log_info "Installing Nginx..."
apt install -y nginx > /dev/null 2>&1
check_error "Nginx install"

# Web root
mkdir -p /var/www/qualibytes
chown -R www-data:www-data /var/www/qualibytes
chmod -R 755 /var/www/qualibytes

# Nginx config
cat > /etc/nginx/sites-available/qualibytes << 'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/qualibytes;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
}
EOF

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/qualibytes /etc/nginx/sites-enabled/

# Start Nginx
nginx -t
check_error "nginx test"

systemctl start nginx
systemctl enable nginx > /dev/null 2>&1

log_success "Server setup complete!"
echo "Node: $(node -v)"
echo "Nginx: $(systemctl is-active nginx)"
