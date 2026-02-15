# 🚀 START HERE - Docker Publishing Guide

Welcome! You now have everything you need to package and publish your Home Assistant Matter Hub as a Docker container.

## Your Situation

- ✅ You fixed the light brightness bug
- ✅ You want to package it as Docker
- ✅ You want to test it locally
- ✅ You want to publish it so others can use it
- ❓ But you've never done Docker before

**Good news:** Everything is automated. You just follow the steps.

---

## 5 Simple Steps

### Step 1: Commit to Git (3 minutes)

```bash
cd /home/wayne/dev/home-assistant-matter-hub

# Add all files
git add .

# Commit with a message
git commit -m "fix: light brightness null handling + add docker guides"

# Push to GitHub
git push origin main
```

**Expected:** Your changes are on GitHub

---

### Step 2: Check Docker Installation (1 minute)

```bash
docker --version
```

**Expected:** Shows something like `Docker version 24.0.0, build abcdef`

If not installed: https://docs.docker.com/get-docker/

---

### Step 3: Build Docker Image (5 minutes)

```bash
cd /home/wayne/dev/home-assistant-matter-hub

./build-and-push-docker.sh 0.1.0 build
```

This script automatically:
- Downloads dependencies
- Builds your code
- Creates Docker image
- Tests it works

**Expected:** Message saying `✅ All steps completed successfully!`

---

### Step 4: Test Locally (2 minutes)

Quick test:
```bash
docker run -it home-assistant-matter-hub:0.1.0 --help
```

**Expected:** Shows your application's help text

Full test (requires Home Assistant running):
```bash
docker run -d --name hamh-test \
  -p 8482:8482 \
  -e HAMH_HOME_ASSISTANT_URL="http://192.168.1.100:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_long_token_here" \
  home-assistant-matter-hub:0.1.0

# Watch logs
docker logs -f hamh-test

# Stop when done
docker stop hamh-test
docker rm hamh-test
```

**Expected:** Connects to Home Assistant without errors

---

### Step 5: Publish to Registry (5 minutes)

Choose ONE of these:

**OPTION A: Docker Hub (Easiest)**

1. Create account at https://hub.docker.com (free)
2. Login:
   ```bash
   docker login
   # Enter username and password
   ```
3. Publish:
   ```bash
   ./build-and-push-docker.sh 0.1.0 push YOUR_DOCKER_HUB_USERNAME
   ```

Others can then run:
```bash
docker pull YOUR_DOCKER_HUB_USERNAME/home-assistant-matter-hub
```

**OPTION B: GitHub Container Registry**

1. Create token at https://github.com/settings/tokens
   - Scopes needed: write:packages, read:packages, delete:packages
2. Login:
   ```bash
   docker login ghcr.io
   # Enter username and token
   ```
3. Publish:
   ```bash
   ./build-and-push-docker.sh 0.1.0 push ghcr.io/YOUR_GITHUB_USERNAME
   ```

Others can then run:
```bash
docker pull ghcr.io/YOUR_GITHUB_USERNAME/home-assistant-matter-hub
```

**Expected:** You can verify on Docker Hub or GitHub that the image exists

---

## ✅ You're Done!

Your app is now:
- ✅ Packaged as Docker
- ✅ Tested locally
- ✅ Committed to git
- ✅ Published so others can use it

---

## 📚 Documentation

- **This file** - START HERE
- [DOCKER_QUICK_START.md](DOCKER_QUICK_START.md) - 3-step overview
- [DOCKER_CHECKLIST.md](DOCKER_CHECKLIST.md) - Detailed checklist
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Complete reference

---

## ❓ Help

**Build script failed?**
→ Check error message, see [DOCKER_GUIDE.md](DOCKER_GUIDE.md) troubleshooting

**Don't have Docker?**
→ Install from https://docs.docker.com/get-docker/

**Don't have Docker Hub account?**
→ Create free account at https://hub.docker.com

**Need more details?**
→ Read [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

---

## 🎯 Next Steps (After Publishing)

Once published, you can:

1. **Share with others:**
   ```
   docker pull YOUR_USERNAME/home-assistant-matter-hub:latest
   ```

2. **Use in production:**
   ```bash
   docker run -d \
     --name hamh \
     -p 8482:8482 \
     -v /path/to/data:/data \
     -e HAMH_HOME_ASSISTANT_URL="http://homeassistant:8123" \
     -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_token" \
     YOUR_USERNAME/home-assistant-matter-hub:latest
   ```

3. **(Optional) Set up Home Assistant Addon:**
   → See [DOCKER_GUIDE.md](DOCKER_GUIDE.md) Step 6

---

## 🚀 Go!

Ready? Start with **Step 1** above. Copy and paste the commands.

You've got this! 💪
