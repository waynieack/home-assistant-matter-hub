#!/bin/bash
#
# Build and optionally push Docker images for Home Assistant Matter Hub
# 
# Usage:
#   ./build-and-push-docker.sh [VERSION] [ACTION] [REGISTRY]
#
# Arguments:
#   VERSION:  Version tag (e.g., 0.1.0, default: 0.0.1-dev)
#   ACTION:   "build" (build only) or "push" (build and push), default: build
#   REGISTRY: Docker registry (waynebook for Docker Hub, ghcr.io/waynebook for GHCR), default: local
#
# Examples:
#   ./build-and-push-docker.sh                          # Build locally as 0.0.1-dev
#   ./build-and-push-docker.sh 0.1.0 build              # Build 0.1.0 locally
#   ./build-and-push-docker.sh 0.1.0 push waynebook    # Build and push to Docker Hub
#   ./build-and-push-docker.sh 0.1.0 push ghcr.io/waynebook  # Build and push to GHCR
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERSION="${1:-0.0.1-dev}"
ACTION="${2:-build}"
REGISTRY="${3:-}"
DOCKERFILE="${4:-standalone}"

# Validate action
if [[ ! "$ACTION" =~ ^(build|push)$ ]]; then
  echo -e "${RED}❌ Invalid action: $ACTION${NC}"
  echo "   Use 'build' or 'push'"
  exit 1
fi

# Validate Dockerfile
if [[ ! "$DOCKERFILE" =~ ^(standalone|addon)$ ]]; then
  echo -e "${RED}❌ Invalid Dockerfile: $DOCKERFILE${NC}"
  echo "   Use 'standalone' or 'addon'"
  exit 1
fi

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Home Assistant Matter Hub - Docker Build${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "Version:    ${YELLOW}$VERSION${NC}"
echo -e "Action:     ${YELLOW}$ACTION${NC}"
echo -e "Dockerfile: ${YELLOW}$DOCKERFILE${NC}"
echo -e "Registry:   ${YELLOW}${REGISTRY:-local}${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "apps/home-assistant-matter-hub" ]]; then
  echo -e "${RED}❌ Error: Must run from project root directory${NC}"
  exit 1
fi

# Step 1: Build the project package
echo -e "${BLUE}📦 Step 1: Building application package...${NC}"
if command -v pnpm &> /dev/null; then
  PKG_MANAGER="pnpm"
elif command -v npm &> /dev/null; then
  PKG_MANAGER="npm"
else
  echo -e "${RED}❌ Neither pnpm nor npm found. Please install Node.js/npm${NC}"
  exit 1
fi

echo "   Using package manager: $PKG_MANAGER"
$PKG_MANAGER install --frozen-lockfile || {
  echo -e "${RED}❌ Failed to install dependencies${NC}"
  exit 1
}

$PKG_MANAGER run build || {
  echo -e "${RED}❌ Failed to build project${NC}"
  exit 1
}

$PKG_MANAGER run build:app || {
  echo -e "${RED}❌ Failed to build app${NC}"
  exit 1
}

cd apps/home-assistant-matter-hub
$PKG_MANAGER run bundle || {
  echo -e "${RED}❌ Failed to bundle package${NC}"
  exit 1
}
cd ../../

echo -e "${GREEN}✅ Application package built${NC}"
echo ""

# Step 2: Check if package.tgz exists
if [[ ! -f "apps/home-assistant-matter-hub/package.tgz" ]]; then
  echo -e "${RED}❌ Error: package.tgz not found!${NC}"
  exit 1
fi

echo -e "   $(ls -lh apps/home-assistant-matter-hub/package.tgz | awk '{print $5, $9}')"
echo ""

# Step 3: Build Docker image
echo -e "${BLUE}🐳 Step 2: Building Docker image...${NC}"
DOCKERFILE_PATH="apps/home-assistant-matter-hub/${DOCKERFILE}.Dockerfile"
BUILD_CONTEXT="apps/home-assistant-matter-hub"

if [[ ! -f "$DOCKERFILE_PATH" ]]; then
  echo -e "${RED}❌ Error: Dockerfile not found at $DOCKERFILE_PATH${NC}"
  exit 1
fi

if [[ -z "$REGISTRY" ]]; then
  # Build locally only
  IMAGE_TAG="home-assistant-matter-hub:${VERSION}"
else
  # Build with registry
  IMAGE_TAG="${REGISTRY}/home-assistant-matter-hub:${VERSION}"
fi

echo "   Dockerfile: $DOCKERFILE_PATH"
echo "   Image tag:  $IMAGE_TAG"
echo ""

docker build \
  -f "$DOCKERFILE_PATH" \
  -t "$IMAGE_TAG" \
  --build-arg PACKAGE_VERSION="$VERSION" \
  "$BUILD_CONTEXT" || {
  echo -e "${RED}❌ Docker build failed${NC}"
  exit 1
}

echo -e "${GREEN}✅ Docker image built${NC}"
echo ""

# Step 4: Show image info
echo -e "${BLUE}📋 Image Information:${NC}"
docker images | grep "home-assistant-matter-hub" | head -5
echo ""

# Step 5: Test image (quick sanity check)
echo -e "${BLUE}🧪 Step 3: Testing image...${NC}"

# Skip test for addon builds (they expect HA environment)
if [[ "$DOCKERFILE" == "addon" ]]; then
  echo -e "${YELLOW}⚠️  Skipping test for addon build (requires Home Assistant environment)${NC}"
else
  docker run --rm "$IMAGE_TAG" --help > /dev/null && \
    echo -e "${GREEN}✅ Image runs successfully${NC}" || {
    echo -e "${RED}❌ Image test failed${NC}"
    exit 1
  }
fi
echo ""

# Step 6: Push if requested
if [[ "$ACTION" == "push" ]]; then
  if [[ -z "$REGISTRY" ]]; then
    echo -e "${YELLOW}⚠️  No registry specified, skipping push${NC}"
    echo "    Use: ./build-and-push-docker.sh $VERSION push REGISTRY"
  else
    echo -e "${BLUE}🚀 Step 4: Pushing to registry...${NC}"
    echo "   Registry: $REGISTRY"
    
    echo "   Pushing $IMAGE_TAG..."
    docker push "$IMAGE_TAG" || {
      echo -e "${RED}❌ Failed to push image${NC}"
      exit 1
    }
    
    echo -e "${GREEN}✅ Image pushed successfully${NC}"
    echo ""
    
    # Also push 'latest' tag
    LATEST_TAG="${REGISTRY}/home-assistant-matter-hub:latest"
    echo "   Tagging as latest..."
    docker tag "$IMAGE_TAG" "$LATEST_TAG"
    docker push "$LATEST_TAG" || {
      echo -e "${RED}❌ Failed to push latest tag${NC}"
      exit 1
    }
    echo -e "${GREEN}✅ Latest tag pushed${NC}"
  fi
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ All steps completed successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

if [[ -z "$REGISTRY" ]]; then
  echo -e "Run locally:"
  echo -e "  ${YELLOW}docker run -it $IMAGE_TAG${NC}"
  echo ""
else
  echo -e "Pull from registry:"
  echo -e "  ${YELLOW}docker pull $IMAGE_TAG${NC}"
  echo ""
  echo -e "Run the image:"
  echo -e "  ${YELLOW}docker run -it $IMAGE_TAG${NC}"
  echo ""
fi
