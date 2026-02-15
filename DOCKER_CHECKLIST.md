# Docker Publishing Checklist

Quick checklist to follow when publishing your Docker images.

## ✅ Pre-Publishing Checklist

### 1. Code Changes (COMPLETE ✓)
- [x] Fixed light brightness null handling
- [x] Created copilot-instructions.md
- [ ] Run any final tests to verify your changes work

### 2. Git Commit & Push
- [ ] Review all changes: `git status`
- [ ] Stage changes: `git add .`
- [ ] Commit: `git commit -m "fix: light brightness null handling + add docker guide"`
- [ ] Push: `git push origin main`
- [ ] Verify on GitHub: https://github.com/waynebook/home-assistant-matter-hub

**Commands:**
```bash
cd /home/wayne/dev/home-assistant-matter-hub
git add .
git commit -m "fix: light brightness null handling; docs: add docker guide"
git push origin main
```

---

## 🐳 Docker Build & Test Checklist

### 3. Setup (First Time Only)
- [ ] Install Docker: https://docs.docker.com/get-docker/
- [ ] Verify: `docker --version` (should show v20+)

### 4. Build Docker Image Locally
- [ ] Run build script:
  ```bash
  cd /home/wayne/dev/home-assistant-matter-hub
  ./build-and-push-docker.sh 0.1.0 build
  ```
  
  Expected output: `✅ All steps completed successfully!`

- [ ] Verify image was created:
  ```bash
  docker images | grep home-assistant-matter-hub
  ```

### 5. Test Image Locally
- [ ] Quick test (should show help):
  ```bash
  docker run --rm home-assistant-matter-hub:0.1.0 --help
  ```

- [ ] Full integration test:
  ```bash
  # Get your Home Assistant details first
  # URL: http://192.168.x.x:8123 (or homeassistant.local)
  # Token: Settings → Developer Tools → Personal Access Tokens
  
  docker run -d \
    --name hamh-test \
    -p 8482:8482 \
    -e HAMH_HOME_ASSISTANT_URL="http://192.168.x.x:8123" \
    -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_token" \
    home-assistant-matter-hub:0.1.0
  
  # Check logs
  docker logs -f hamh-test
  
  # Test API
  curl http://localhost:8482/api/bridges
  
  # Stop when done
  docker stop hamh-test
  docker rm hamh-test
  ```

- [ ] Verify light brightness fix works:
  - Turn off a dimmable light in HA
  - Check brightness shows 0% (not null) in Matter controller

---

## 📤 Registry Setup & Push (Choose One)

### Option A: Docker Hub (Simplest)

#### Setup (First Time Only)
- [ ] Create account: https://hub.docker.com/
- [ ] Login locally:
  ```bash
  docker login
  # Enter username and password
  ```

#### Push Image
- [ ] Tag image:
  ```bash
  docker tag home-assistant-matter-hub:0.1.0 YOURUSERNAME/home-assistant-matter-hub:0.1.0
  docker tag home-assistant-matter-hub:0.1.0 YOURUSERNAME/home-assistant-matter-hub:latest
  ```

- [ ] Push:
  ```bash
  docker push YOURUSERNAME/home-assistant-matter-hub:0.1.0
  docker push YOURUSERNAME/home-assistant-matter-hub:latest
  ```
  
  Or use the automated script:
  ```bash
  ./build-and-push-docker.sh 0.1.0 push YOURUSERNAME
  ```

- [ ] Verify on Docker Hub: https://hub.docker.com/r/YOURUSERNAME/home-assistant-matter-hub

### Option B: GitHub Container Registry (GHCR)

#### Setup (First Time Only)
- [ ] Create GitHub Personal Access Token:
  - Go to: https://github.com/settings/tokens
  - Click "Generate new token" → "Generate new token (classic)"
  - Name: `Docker Build Token`
  - Scopes: `write:packages`, `read:packages`, `delete:packages`
  - Click "Generate token" and copy it

- [ ] Login locally:
  ```bash
  export CR_PAT="your_copied_token"
  echo "$CR_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
  ```

#### Push Image
- [ ] Tag image:
  ```bash
  docker tag home-assistant-matter-hub:0.1.0 ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:0.1.0
  docker tag home-assistant-matter-hub:0.1.0 ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:latest
  ```

- [ ] Push:
  ```bash
  docker push ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:0.1.0
  docker push ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:latest
  ```
  
  Or use the automated script:
  ```bash
  ./build-and-push-docker.sh 0.1.0 push ghcr.io/YOUR_USERNAME
  ```

- [ ] Verify on GitHub: https://github.com/YOUR_USERNAME?tab=packages

---

## ✅ Verification

### After Publishing
- [ ] Pull and run from registry (verify others can use it):
  ```bash
  # Docker Hub
  docker pull YOURUSERNAME/home-assistant-matter-hub:latest
  docker run -it YOURUSERNAME/home-assistant-matter-hub:latest --help
  
  # Or GHCR
  docker pull ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:latest
  docker run -it ghcr.io/YOUR_USERNAME/home-assistant-matter-hub:latest --help
  ```

- [ ] Share the pull command with others:
  ```
  Docker Hub: docker pull YOURUSERNAME/home-assistant-matter-hub
  GHCR: docker pull ghcr.io/YOUR_USERNAME/home-assistant-matter-hub
  ```

---

## 📋 Complete Quick Command Reference

```bash
# 1. Commit and push code
cd /home/wayne/dev/home-assistant-matter-hub
git add .
git commit -m "fix: light brightness null handling"
git push origin main

# 2. Build Docker image locally
./build-and-push-docker.sh 0.1.0 build

# 3. Test the image
docker run -it home-assistant-matter-hub:0.1.0 --help

# 4. Push to Docker Hub (if using)
./build-and-push-docker.sh 0.1.0 push YOURUSERNAME

# 5. Verify it works
docker pull YOURUSERNAME/home-assistant-matter-hub:0.1.0
docker run -it YOURUSERNAME/home-assistant-matter-hub:0.1.0 --help
```

---

## 🆘 Troubleshooting

### Issue: `docker: command not found`
**Solution:** Install Docker from https://docs.docker.com/get-docker/

### Issue: `permission denied while trying to connect to Docker daemon`
**Solution:** 
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

### Issue: `denied: requested access to the resource is denied`
**Solution:** You're not logged in to the registry
```bash
docker login          # For Docker Hub
docker login ghcr.io  # For GitHub Container Registry
```

### Issue: Build script fails - `pnpm: command not found`
**Solution:** Install Node.js and pnpm
```bash
# With npm
npm install -g pnpm

# Or use npm directly in script
export PKG_MANAGER=npm
./build-and-push-docker.sh 0.1.0 build
```

### Issue: Container won't connect to Home Assistant
**Solution:** 
- Use internal IP address, not localhost or hostname
- Check firewall allows port 8123
- Verify access token is correct
- Logs: `docker logs container_name`

---

## 📚 Next Steps

1. ✅ Follow checklist items 1-5 (complete locally)
2. ✅ Push to registry (choose Docker Hub or GHCR)
3. ✅ Document the image for others to use
4. (Optional) Set up Home Assistant addon repository
5. (Optional) Configure GitHub Actions for automated builds

For detailed information, see `DOCKER_GUIDE.md` in the project root.
