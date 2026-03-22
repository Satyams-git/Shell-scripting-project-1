# GitHub se Deploy karna — Step by Step Guide

## Pehle ek baar setup karo (sirf ek baar)

### 1. GitHub pe repo banao
```bash
# GitHub.com pe jao → New Repository
# Name: qualibytes
# Visibility: Public (free me)
# README: unchecked (already hai hamare paas)
```

### 2. Local project ko GitHub se connect karo
```bash
# Project folder ke andar jao
cd qualibytes/

# Git initialize karo
git init

# Sari files stage karo
git add .

# Pehla commit
git commit -m "Initial commit: Qualibytes IT Academy website"

# GitHub repo se connect karo (apna username daalo)
git remote add origin https://github.com/YOUR_USERNAME/qualibytes.git

# Push karo
git push -u origin main
```

### 3. EC2 pe server_setup.sh ek baar chalao (pehle wali tarah)
```bash
sudo bash server_setup.sh
```

---

## Har deployment ke liye (sirf ye 2 steps)

### Step 1 — Local changes GitHub pe push karo
```bash
git add .
git commit -m "Update: homepage content changed"
git push origin main
```

### Step 2 — Deploy script chalao apni local machine se
```bash
bash deploy.sh 13.233.45.67 ~/.ssh/my-key.pem \
  https://github.com/YOUR_USERNAME/qualibytes.git
```

**Script automatically EC2 pe:**
1. `git pull` karta hai — latest code laata hai
2. `npm install` karta hai
3. `npm run build` karta hai
4. `/var/www/qualibytes/` me copy karta hai
5. Nginx reload karta hai
6. HTTP check karta hai — site live hai ya nahi

---

## Purane deploy.sh se kya fark hai?

| | Purana (scp wala) | Naya (GitHub wala) |
|--|--|--|
| Build kahan hota hai | Local machine pe | EC2 server pe |
| Files kaise jaati hain | scp se copy | git pull se |
| Internet speed matter karta hai | Haan (upload) | Nahi |
| Git history | Nahi | Haan |
| Rollback possible | Nahi | Haan — `git reset` |

---

## Rollback kaise karo (agar kuch galat ho jaye)

```bash
# EC2 pe jao
ssh -i ~/.ssh/key.pem ubuntu@YOUR_EC2_IP

# Project folder me jao
cd ~/qualibytes

# Pichle commits dekho
git log --oneline -5

# Purane commit pe wapas jao
git reset --hard <COMMIT_HASH>

# Rebuild karo
npm run build
sudo cp -r build/. /var/www/qualibytes/
sudo systemctl reload nginx
```

---

## Private GitHub repo ke liye (optional)

Agar repo private hai, to EC2 ko GitHub access dena hoga:

```bash
# EC2 pe SSH key banao
ssh-keygen -t ed25519 -C "qualibytes-ec2" -f ~/.ssh/github_deploy

# Public key copy karo
cat ~/.ssh/github_deploy.pub

# GitHub → Settings → Deploy Keys → Add Key me paste karo
# Title: "Qualibytes EC2"
# Allow write access: NO (read-only kaafi hai)
```

Phir GITHUB_REPO URL SSH format me use karo:
```bash
bash deploy.sh 13.x.x.x ~/.ssh/key.pem \
  git@github.com:YOUR_USERNAME/qualibytes.git
```

