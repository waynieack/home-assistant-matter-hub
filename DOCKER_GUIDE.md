# Docker Publishing Guide for Home Assistant Matter Hub

This guide walks you through building, testing, and publishing Docker images for this project.

## Overview

Your project has two Docker images:
1. **standalone.Dockerfile** - Standalone Node.js application (for running independently)
2. **addon.Dockerfile** - Home Assistant Addon format (for Home Assistant addon repository)

Both pull a pre-built package (`package.tgz`) that contains the built application.

## Step 1: Git - Commit Your Changes

First, commit the code changes (the light level fix and copilot instructions):

```bash
cd /home/wayne/dev/home-assistant-matter-hub

# Stage all changes
git add -A

# Commit with a descriptive message
git commit -m "fix: default light brightness to 0 when null to fix Alexa compatibility"

# Push to GitHub
git push origin main
```

**Verification:**
```bash
git log --oneline -5  # Should show your new commit
git status            # Should show "nothing to commit"
```

---

## Step 2: Build the Docker Image Locally

### Prerequisites
- Install Docker: https://docs.docker.com/get-docker/
- Verify: `docker --version`

### Build Process

The build process involves several stages:

**Stage 1: Build the application package**
```bash
cd /home/wayne/dev/home-assistant-matter-hub

# Install dependencies
pnpm install

# Build the project
pnpm run build

# Create the distributable package
pnpm run build:app

# Package it as .tgz for Docker
cd apps/home-assistant-matter-hub
pnpm run bundle
```

After this, you should have `apps/home-assistant-matter-hub/package.tgz`.

**Stage 2: Build Docker Image**

For testing locally, use the **standalone** image:

```bash
cd /home/wayne/dev/home-assistant-matter-hub

# Build the standalone image
docker build \
  -f apps/home-assistant-matter-hub/standalone.Dockerfile \
  -t home-assistant-matter-hub:latest \
  --build-arg PACKAGE_VERSION="0.1.0-local" \
  -c apps/home-assistant-matter-hub/

# Verify the image was created
docker images | grep home-assistant-matter-hub
```

Or use this helper script to automate:

Create a file `build-docker.sh`:

```bash
#!/bin/bash
set -e

echo "📦 Building package..."
pnpm install --frozen-lockfile
pnpm run build
pnpm run build:app
cd apps/home-assistant-matter-hub
pnpm run bundle
cd ../../

VERSION=${1:-0.1.0-local}
DOCKERFILE=${2:-standalone}

echo "🐳 Building Docker image ($DOCKERFILE)..."
docker build \
  -f "apps/home-assistant-matter-hub/${DOCKERFILE}.Dockerfile" \
  -t "home-assistant-matter-hub:$VERSION" \
  --build-arg PACKAGE_VERSION="$VERSION" \
  apps/home-assistant-matter-hub/

echo "✅ Build complete: home-assistant-matter-hub:$VERSION"
docker images | grep home-assistant-matter-hub
```

Usage:
```bash
chmod +x build-docker.sh
./build-docker.sh "0.1.0" "standalone"
```

---

## Step 3: Test Locally

### Quick Container Test

```bash
# Create a data directory for the container
mkdir -p ~/hamh-data

# Run the container
docker run -it --rm \
  -p 8482:8482 \
  -v ~/hamh-data:/data \
  -e HAMH_HOME_ASSISTANT_URL="http://192.168.x.x:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_token_here" \
  home-assistant-matter-hub:latest

# You should see the app starting with log output
# Press Ctrl+C to stop
```

### Full Integration Test (Recommended)

1. **Setup Home Assistant Instance** (if not already running)
   - Need a local Home Assistant instance to connect to
   - Get your API token: http://homeassistant.local:8123/profile/security

2. **Run Container with Volume**
   ```bash
   docker run -d \
     --name hamh-test \
     -p 8482:8482 \
     -v ~/hamh-data:/data \
     -e HAMH_HOME_ASSISTANT_URL="http://192.168.x.x:8123" \
     -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="your_long_token" \
     -e HAMH_HOME_ASSISTANT_REFRESH_INTERVAL="5000" \
     home-assistant-matter-hub:latest
   ```

3. **Check Logs**
   ```bash
   docker logs hamh-test          # See startup logs
   docker logs -f hamh-test       # Follow logs in real-time
   docker exec hamh-test ps aux   # Check if process is running
   ```

4. **Test API**
   ```bash
   curl http://localhost:8482/api/bridges
   ```

5. **Stop Container**
   ```bash
   docker stop hamh-test
   docker rm hamh-test
   ```

### Verify the Light Level Fix

Once the container is running and connected to Home Assistant:

1. In Home Assistant, turn OFF a dimmable light
2. Check the Matter device (in Alexa, Apple Home, etc.) - brightness should show **0%** not null
3. Turn the light ON to a specific brightness level
4. Verify it syncs correctly

---

## Step 4: Push Docker Image to Registry

You have two main options for hosting Docker images:

### Option A: Docker Hub (Recommended for Public Use)

1. **Create Docker Hub Account**
   - Go to https://hub.docker.com/
   - Sign up (free account available)

2. **Login to Docker Hub**
   ```bash
   docker login
   # Enter username and password
   ```

3. **Tag Your Image**
   ```bash
   # Format: docker tag LOCAL_IMAGE:TAG USERNAME/REPO_NAME:TAG
   docker tag home-assistant-matter-hub:0.1.0 waynebook/home-assistant-matter-hub:0.1.0
   docker tag home-assistant-matter-hub:0.1.0 waynebook/home-assistant-matter-hub:latest
   ```

4. **Push to Docker Hub**
   ```bash
   docker push waynebook/home-assistant-matter-hub:0.1.0
   docker push waynebook/home-assistant-matter-hub:latest
   ```

5. **Verify**
   - Visit: https://hub.docker.com/r/waynebook/home-assistant-matter-hub

### Option B: GitHub Container Registry (GHCR)

Good if your project is on GitHub (which it is!).

1. **Generate GitHub Token**
   - Go to: https://github.com/settings/tokens
   - Create "Personal access token (classic)"
   - Select scopes: `write:packages`, `read:packages`, `delete:packages`
   - Copy the token

2. **Login to GHCR**
   ```bash
   export CR_PAT="YOUR_TOKEN"
   echo "$CR_PAT" | docker login ghcr.io -u USERNAME --password-stdin
   ```

3. **Tag Your Image**
   ```bash
   docker tag home-assistant-matter-hub:0.1.0 ghcr.io/waynebook/home-assistant-matter-hub:0.1.0
   docker tag home-assistant-matter-hub:0.1.0 ghcr.io/waynebook/home-assistant-matter-hub:latest
   ```

4. **Push to GHCR**
   ```bash
   docker push ghcr.io/waynebook/home-assistant-matter-hub:0.1.0
   docker push ghcr.io/waynebook/home-assistant-matter-hub:latest
   ```

---

## Step 5: Pull from Registry (Test)

After pushing, verify anyone can pull your image:

**From Docker Hub:**
```bash
docker pull waynebook/home-assistant-matter-hub:latest
docker run -it waynebook/home-assistant-matter-hub:latest --help
```

**From GHCR:**
```bash
docker pull ghcr.io/waynebook/home-assistant-matter-hub:latest
docker run -it ghcr.io/waynebook/home-assistant-matter-hub:latest --help
```

---

## Step 6: Home Assistant Addon Setup

### For Standalone Container (Non-Addon)

Users can run directly:
```bash
docker run -d \
  --name hamh \
  -p 8482:8482 \
  -v /path/to/data:/data \
  -e HAMH_HOME_ASSISTANT_URL="http://homeassistant:8123" \
  -e HAMH_HOME_ASSISTANT_ACCESS_TOKEN="token" \
  waynebook/home-assistant-matter-hub:latest
```

### For Home Assistant Addon Repository

If you want it as an official Home Assistant addon:

1. **Create addon repository** (separate from main project)
   ```bash
   # Create structure like https://github.com/t0bst4r/home-assistant-addons
   addons/
   └── home-assistant-matter-hub/
       ├── addon.yml (addon metadata)
       ├── CHANGELOG.md
       ├── icon.png
       └── logo.png
   ```

2. **addon.yml format**:
   ```yaml
   name: Home Assistant Matter Hub
   description: Bridge Home Assistant entities to Matter controllers
   version: 0.1.0
   slug: home-assistant-matter-hub
   image: waynebook/home-assistant-matter-hub:{arch}-{version}
   arch:
     - aarch64
     - amd64
     - armhf
     - i386
   ports:
     5580/tcp: 5580
   config:
     app_log_level: info
     disable_log_colors: false
     mdns_network_interface: ""
   ```

3. **Add addon repository in Home Assistant**:
   - Go to: Settings → Add-ons → Repositories
   - Add: `https://github.com/waynebook/home-assistant-addons`

---

## Automation: GitHub Actions (Already Set Up)

Your project already has GitHub Actions workflows configured!

The `.github/workflows/release.yml` does:
1. ✅ Runs tests
2. ✅ Builds the project
3. ✅ Creates releases
4. ✅ Builds Docker images
5. ✅ Pushes to container registry

**To use it:**
1. Configure Docker credentials in GitHub Secrets
2. Trigger workflow manually: `Actions → Release → Run workflow`

---

## Quick Reference: Complete Build & Publish

```bash
#!/bin/bash
set -e

VERSION="0.1.0"
REGISTRY="waynebook"  # Docker Hub username

# Step 1: Commit changes
git add -A
git commit -m "fix: light brightness null handling"
git push origin main

# Step 2: Build package
pnpm install --frozen-lockfile
pnpm run build
pnpm run build:app
cd apps/home-assistant-matter-hub && pnpm run bundle && cd ../../

# Step 3: Build Docker
docker build \
  -f apps/home-assistant-matter-hub/standalone.Dockerfile \
  -t "$REGISTRY/home-assistant-matter-hub:$VERSION" \
  -t "$REGISTRY/home-assistant-matter-hub:latest" \
  --build-arg PACKAGE_VERSION="$VERSION" \
  apps/home-assistant-matter-hub/

# Step 4: Test locally
docker run -it --rm "$REGISTRY/home-assistant-matter-hub:latest" --help

# Step 5: Push to registry
docker login
docker push "$REGISTRY/home-assistant-matter-hub:$VERSION"
docker push "$REGISTRY/home-assistant-matter-hub:latest"

echo "✅ Done! Pull with: docker pull $REGISTRY/home-assistant-matter-hub:latest"
```

---

## Troubleshooting

### Build Fails: "Cannot find package.tgz"
**Solution:** Make sure you ran `pnpm run bundle` in the apps/home-assistant-matter-hub directory

### Container Won't Connect to Home Assistant
- Check Home Assistant URL is correct (use internal IP for docker)
- Verify access token is valid
- Check firewall allows connection

### Port Already in Use
```bash
# Find what's using port 8482
lsof -i :8482

# Or use different port
docker run -p 9000:8482 home-assistant-matter-hub:latest
```

### View Container Logs
```bash
docker logs -f container_name
docker logs --tail 100 container_name
```

---

## Next Steps

1. ✅ Commit your fixes to git
2. ✅ Build and test Docker image locally
3. ✅ Push to Docker Hub or GHCR
4. ✅ Share the image with others: `docker pull waynebook/home-assistant-matter-hub`
5. (Optional) Create Home Assistant addon repository

For questions about Docker concepts:
- Docker docs: https://docs.docker.com/
- Container registries: https://docs.docker.com/docker-hub/ or https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
