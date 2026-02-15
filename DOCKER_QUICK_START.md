# Docker Publishing Quick Start

## TL;DR - Three Main Steps

### 1️⃣ Commit Your Changes
```bash
cd /home/wayne/dev/home-assistant-matter-hub
git add .
git commit -m "fix: light brightness null handling"
git push origin main
```

### 2️⃣ Build & Test Docker Locally
```bash
./build-and-push-docker.sh 0.1.0 build

# Quick test
docker run -it home-assistant-matter-hub:0.1.0 --help

# Full test with Home Assistant
docker run -d --name hamh-test \
  -p 8482:8482 \
  -e HAMH_HOME_ASSISTANT_URL="http://192.168.x.x:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_token" \
  home-assistant-matter-hub:0.1.0

docker logs -f hamh-test        # Watch logs
docker stop hamh-test hamh-test # Stop when done
```

### 3️⃣ Publish to Registry (Choose One)

**Docker Hub (Easiest):**
```bash
# First time: create account at https://hub.docker.com and login
docker login

# Then:
./build-and-push-docker.sh 0.1.0 push YOUR_DOCKER_HUB_USERNAME

# Others can then use:
docker pull YOUR_DOCKER_HUB_USERNAME/home-assistant-matter-hub
```

**GitHub Container Registry:**
```bash
# First time: create token at https://github.com/settings/tokens
# Then login: docker login ghcr.io

# Then:
./build-and-push-docker.sh 0.1.0 push ghcr.io/YOUR_GITHUB_USERNAME

# Others can then use:
docker pull ghcr.io/YOUR_GITHUB_USERNAME/home-assistant-matter-hub
```

---

## What Each Step Does

### Build Script (`build-and-push-docker.sh`)
The automated script handles:
1. ✅ Install dependencies (`pnpm install`)
2. ✅ Build project (`pnpm run build`)
3. ✅ Build app (`pnpm run build:app`)
4. ✅ Bundle package (`pnpm run bundle`)
5. ✅ Build Docker image (`docker build`)
6. ✅ Test image (`docker run --help`)
7. ✅ Push to registry (if requested)

### Docker Image Includes
- Node.js 22 (Alpine Linux)
- Your packaged application
- Ready to connect to Home Assistant

---

## Files Created for You

| File | Purpose |
|------|---------|
| `DOCKER_GUIDE.md` | Complete Docker guide with detailed explanations |
| `DOCKER_CHECKLIST.md` | Step-by-step checklist to follow |
| `build-and-push-docker.sh` | Automated build and push script |
| `.github/copilot-instructions.md` | AI agent instructions (for development) |

---

## Environment Variables for Container

When running the container, pass these environment variables:

```bash
docker run -e VARIABLE=value home-assistant-matter-hub:latest
```

Common variables:
- `HAMH_HOME_ASSISTANT_URL` - URL to Home Assistant (e.g., `http://192.168.1.100:8123`)
- `HAMH_HOME_ASSISTANT_ACCESS_TOKEN` - Long-lived access token from Home Assistant
- `HAMH_STORAGE_LOCATION` - Where to store data (default: `/data`)
- `HAMH_HTTP_PORT` - Web server port (default: 8482)
- `HAMH_LOG_LEVEL` - Logging level (debug, info, warn, error)

Example full run:
```bash
docker run -d \
  --name hamh \
  -p 8482:8482 \
  -v /path/to/data:/data \
  -e HAMH_HOME_ASSISTANT_URL="http://homeassistant.local:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  home-assistant-matter-hub:0.1.0
```

---

## Docker Commands Reference

```bash
# Build images
docker build -f Dockerfile -t myimage:1.0 .

# Run container
docker run -it myimage:1.0

# Run in background
docker run -d --name mycontainer myimage:1.0

# View logs
docker logs mycontainer
docker logs -f mycontainer  # Follow live

# Stop container
docker stop mycontainer

# Remove container
docker rm mycontainer

# Remove image
docker rmi myimage:1.0

# Tag image for registry
docker tag myimage:1.0 registry.com/username/myimage:1.0

# Push to registry
docker push registry.com/username/myimage:1.0

# Pull from registry
docker pull registry.com/username/myimage:1.0

# List images
docker images

# List running containers
docker ps

# List all containers
docker ps -a

# Execute command in running container
docker exec mycontainer ls -la
```

---

## Docker Registries Compared

| Registry | Setup | Cost | Limit | Best For |
|----------|-------|------|-------|----------|
| **Docker Hub** | Easiest | Free + paid | 1 free repo | Public projects |
| **GitHub Container Registry** | GitHub token | Free | Unlimited | GitHub-hosted projects |
| **Private Registry** | Self-hosted | Cost | Custom | Enterprise |

---

## What Should I Choose?

### Docker Hub
✅ **Best if:**
- Project is public
- Want maximum discoverability
- Want simple sharing

❌ **Downside:**
- Limited free tier (can create multiple free repos)
- Slower to set up first time

### GitHub Container Registry
✅ **Best if:**
- Project is on GitHub
- Want to keep everything in GitHub
- Prefer GitHub integration

❌ **Downside:**
- Requires GitHub account
- Less discoverable than Docker Hub

**Recommendation for you:** Docker Hub is easier for first time. Switch to GHCR later if desired.

---

## After Publishing: Sharing with Others

Once published, share the command:

```
Pull and run:
  docker pull waynebook/home-assistant-matter-hub
  docker run -e HAMH_HOME_ASSISTANT_URL=... home-assistant-matter-hub
```

Or for GitHub Pages/documentation:
```markdown
## Installation

```bash
docker run -d \
  --name hamh \
  -p 8482:8482 \
  -e HAMH_HOME_ASSISTANT_URL="http://homeassistant.local:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_token" \
  waynebook/home-assistant-matter-hub:latest
```
```

---

## Still Confused About Something?

- **Docker basics:** https://docs.docker.com/get-started/
- **Docker Hub:** https://docs.docker.com/docker-hub/
- **GitHub Container Registry:** https://docs.github.com/en/packages/working-with-a-github-packages-registry
- **Home Assistant:** https://www.home-assistant.io/

---

## Next: Home Assistant Addon (Optional)

If you want this available as a Home Assistant addon (for easy installation in the UI):

1. Create separate repository with addon metadata
2. Register it as addon repository in HA
3. Users add your repo → addon appears in UI

See `DOCKER_GUIDE.md` Step 6 for details.

---

Happy containerizing! 🐳
