# Qualibytes IT Academy Pvt. Limited
### Project 6 — React Website + Shell Script Deployment on AWS EC2

---

## Project Structure

```
qualibytes/
├── public/
│   └── index.html              # Main HTML entry point
├── src/
│   ├── components/
│   │   ├── Navbar.js           # Sticky navbar with mobile menu
│   │   ├── Navbar.css
│   │   ├── Footer.js           # Full footer with links & contact
│   │   └── Footer.css
│   ├── pages/
│   │   ├── Home.js             # Hero, courses, testimonials, CTA
│   │   ├── Home.css
│   │   ├── AboutUs.js          # Mission, timeline, team, stats
│   │   ├── AboutUs.css
│   │   ├── OurServices.js      # Interactive course explorer
│   │   ├── OurServices.css
│   │   ├── Contact.js          # Form with validation & success state
│   │   └── Contact.css
│   ├── App.js                  # React Router setup
│   ├── index.js                # App entry point
│   └── index.css               # Global design system & CSS variables
├── package.json                # Project dependencies
├── server_setup.sh             # Run ONCE on a fresh EC2 instance
└── build_and_deploy.sh         # Run every time you want to deploy
```

---

## Pages

| Page | Route | Description |
|------|-------|-------------|
| Home | `/` | Hero section with terminal animation, stats, course cards, testimonials |
| About Us | `/about` | Mission, vision, team cards, company timeline |
| Our Services | `/services` | Interactive sidebar course explorer with details |
| Contact | `/contact` | Enquiry form with live validation and success state |

---

## Shell Scripts

### `server_setup.sh` — Run Once
Sets up a fresh Ubuntu EC2 instance with everything needed to serve the React app.

**What it does:**
1. Updates system packages (`apt update && apt upgrade`)
2. Installs Node.js v20 LTS via NodeSource
3. Installs Nginx web server
4. Creates web root directory `/var/www/qualibytes`
5. Writes Nginx config with React Router support (`try_files`)
6. Enables and starts Nginx
7. Configures firewall (ports 22 and 80)

### `build_and_deploy.sh` — Run Every Deployment
Builds the React app on the server and serves it via Nginx.

**What it does:**
1. Checks `package.json` exists in current directory
2. Runs `npm install` to install dependencies
3. Runs `npm run build` to compile React app
4. Copies `build/` folder to `/var/www/qualibytes/`
5. Fixes file permissions for Nginx
6. Reloads Nginx
7. Prints the live website URL

---

## How to Run — Step by Step

### Prerequisites
- AWS EC2 instance running Ubuntu 22.04
- Security Group Inbound Rules:
  - Port 22 (SSH)
  - Port 80 (HTTP)
- Your `.pem` key file

---

### Step 1 — Connect to EC2
```bash
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-EC2-PUBLIC-IP
```

### Step 2 — Go to the project folder
```bash
cd ~/Shell-scripting-project-1/qualibytes_project6/qualibytes
```

### Step 3 — Run server setup (only once on a fresh server)
```bash
sudo bash server_setup.sh
```
Wait for it to complete. You will see Node.js version, Nginx status, and a success message.

### Step 4 — Build and deploy the website
```bash
bash build_and_deploy.sh
```
This will install packages, build React, copy files, and reload Nginx automatically.

### Step 5 — Open in browser
```
http://YOUR-EC2-PUBLIC-IP
```

---

## Updating the Website

Whenever you make changes and want to redeploy:

```bash
# Go to project folder on the server
cd ~/Shell-scripting-project-1/qualibytes_project6/qualibytes

# Run deploy script again
bash build_and_deploy.sh
```

---

## Troubleshooting

**Nginx not working?**
```bash
sudo nginx -t                        # Test config
sudo systemctl status nginx          # Check status
sudo tail -f /var/log/nginx/error.log  # View error logs
```

**Build failing?**
```bash
node --version    # Should be v18+
npm --version     # Should be v8+
```

**Port 80 not accessible?**
- Go to AWS Console → EC2 → Security Groups
- Add Inbound Rule: HTTP, Port 80, Source 0.0.0.0/0

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, React Router v6 |
| Styling | CSS3 with custom design system |
| Web Server | Nginx |
| Cloud | AWS EC2 (Ubuntu) |
| Automation | Bash shell scripts |

---

*Qualibytes IT Academy Pvt. Limited*
