#!/bin/bash
# ==========================================================
# COMPLETE PANFROST + VULKAN BUILD FOR REALME 8 (Mali-G76)
# All-in-one script for Termux
# ==========================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PREFIX_PANFROST="$HOME/.panfrost"
MESA_SOURCE="$HOME/mesa-panfork"
BUILD_TYPE="${1:-opengl}"  # opengl or vulkan

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    COMPLETE DRIVER BUILD: Mali-G76 Bifrost (Realme 8)     ║${NC}"
echo -e "${BLUE}║          OpenGL (Panfrost) + Vulkan (PanVK)               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ==========================================================
# STEP 1: Update and install dependencies
# ==========================================================
echo -e "${YELLOW}[STEP 1/5] Installing dependencies...${NC}"
pkg update -y && pkg upgrade -y
pkg install -y git meson ninja build-essential cmake python3 \
    termux-x11 x11-repo glmark2 glxgears glxinfo \
    android-ndk binutils wget curl libglvnd-dev vulkan-tools

# Setup environment variables
export ANDROID_NDK_HOME=$PREFIX/lib/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/bin
export CC=clang
export CXX=clang++
export PKG_CONFIG_PATH=$PREFIX_PANFROST/lib/pkgconfig:$PKG_CONFIG_PATH

# Add to bashrc for persistence
if ! grep -q "PANFROST_SETUP" ~/.bashrc; then
    cat >> ~/.bashrc << 'BASHRC_EOF'

# ===== PANFROST DRIVER SETUP =====
export ANDROID_NDK_HOME=$PREFIX/lib/android-ndk
export PATH=$PATH:$ANDROID_NDK_HOME/bin
export LD_LIBRARY_PATH=$HOME/.panfrost/lib:$LD_LIBRARY_PATH
export LIBGL_DRIVERS_PATH=$HOME/.panfrost/lib/dri
export GALLIUM_DRIVER=panfrost
export PKG_CONFIG_PATH=$HOME/.panfrost/lib/pkgconfig:$PKG_CONFIG_PATH
export DISPLAY=:0
# PANFROST_SETUP
BASHRC_EOF
fi

source ~/.bashrc

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# ==========================================================
# STEP 2: Clone Mesa Panfork repository
# ==========================================================
echo -e "${YELLOW}[STEP 2/5] Cloning Mesa Panfork repository...${NC}"

if [ -d "$MESA_SOURCE" ]; then
    echo "Updating existing repository..."
    cd "$MESA_SOURCE"
    git fetch origin
    git reset --hard origin/Panfrost-G610
    cd -
else
    git clone -b Panfrost-G610 --depth 1 \
        https://github.com/Saikatsaha1996/mesa-Panfrost-G610 "$MESA_SOURCE"
fi

echo -e "${GREEN}✅ Repository ready${NC}"
echo ""

# ==========================================================
# STEP 3: Configure Meson build system
# ==========================================================
echo -e "${YELLOW}[STEP 3/5] Configuring Meson build...${NC}"

cd "$MESA_SOURCE"
rm -rf build 2>/dev/null || true
mkdir -p build
cd build

# Determine Vulkan setting based on parameter
if [ "$BUILD_TYPE" = "vulkan" ]; then
    VULKAN_DRIVERS="panfrost"
    echo "Building with Vulkan support (PanVK)"
else
    VULKAN_DRIVERS=""
    echo "Building OpenGL only (Panfrost)"
fi

# Meson configuration
CFLAGS="-O3 -march=armv8-a" \
CXXFLAGS="-O3 -march=armv8-a" \
meson setup .. \
    --prefix="$PREFIX_PANFROST" \
    -Dgallium-drivers=panfrost,swrast \
    -Dvulkan-drivers="$VULKAN_DRIVERS" \
    -Dbuildtype=release \
    -Dllvm=disabled \
    -Dshared-glapi=enabled \
    -Dglx=disabled \
    -Degl=enabled

echo -e "${GREEN}✅ Meson configured${NC}"
echo ""

# ==========================================================
# STEP 4: Compile driver
# ==========================================================
echo -e "${YELLOW}[STEP 4/5] Compiling driver (this may take 20-30 minutes)...${NC}"

# Calculate number of jobs (limit to 4 to avoid OOM)
NJOBS=$(nproc)
if [ $NJOBS -gt 4 ]; then
    NJOBS=4
fi

ninja -j$NJOBS

echo -e "${GREEN}✅ Compilation successful${NC}"
echo ""

# ==========================================================
# STEP 5: Install and test
# ==========================================================
echo -e "${YELLOW}[STEP 5/5] Installing driver...${NC}"

ninja install

# Create DRI directory and copy drivers
mkdir -p "$PREFIX_PANFROST/lib/dri"

echo -e "${GREEN}✅ Driver installed to: $PREFIX_PANFROST${NC}"
echo ""

# ==========================================================
# VERIFICATION
# ==========================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    DRIVER INSTALLED                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Driver location:${NC}"
ls -lah "$PREFIX_PANFROST/lib/" 2>/dev/null | grep -E "\.so|dri" || echo "Check manually:"
echo "  $PREFIX_PANFROST/lib/"
echo ""

# Test OpenGL
if [ "$BUILD_TYPE" != "vulkan" ]; then
    echo -e "${YELLOW}Testing OpenGL driver:${NC}"
    if command -v glxinfo &> /dev/null; then
        glxinfo -B 2>/dev/null | head -10 || echo "glxinfo test skipped"
    else
        echo "glxinfo not available, install with: pkg install glxinfo"
    fi
    echo ""
fi

# Test Vulkan
if [ "$BUILD_TYPE" = "vulkan" ]; then
    echo -e "${YELLOW}Testing Vulkan driver:${NC}"
    
    # Create ICD file for Vulkan
    cat > "$HOME/panfrost.icd" << 'ICD_EOF'
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "$HOME/.panfrost/lib/libvulkan_panfrost.so",
        "api_version": "1.0.0"
    }
}
ICD_EOF
    
    export VK_ICD_FILENAMES="$HOME/panfrost.icd"
    
    if command -v vulkaninfo &> /dev/null; then
        vulkaninfo --summary 2>/dev/null | head -10 || echo "vulkaninfo test skipped"
    else
        echo "vulkaninfo not available, install with: pkg install vulkan-tools"
    fi
    echo ""
fi

# ==========================================================
# SETUP INSTRUCTIONS
# ==========================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               ✅ BUILD COMPLETE - NEXT STEPS               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$BUILD_TYPE" != "vulkan" ]; then
    echo -e "${YELLOW}1. Test the driver with:${NC}"
    echo "   glxgears -info"
    echo "   glmark2"
    echo ""
    
    echo -e "${YELLOW}2. To build with Vulkan support (for shadPS4):${NC}"
    echo "   $0 vulkan"
    echo ""
else
    echo -e "${YELLOW}1. Run shadPS4 with Vulkan:${NC}"
    echo "   export VK_ICD_FILENAMES=\$HOME/panfrost.icd"
    echo "   export LD_LIBRARY_PATH=\$HOME/.panfrost/lib:\$LD_LIBRARY_PATH"
    echo "   ./shadPS4"
    echo ""
fi

echo -e "${YELLOW}3. Environment variables (already in ~/.bashrc):${NC}"
echo "   export LD_LIBRARY_PATH=\$HOME/.panfrost/lib:\$LD_LIBRARY_PATH"
echo "   export LIBGL_DRIVERS_PATH=\$HOME/.panfrost/lib/dri"
echo "   export GALLIUM_DRIVER=panfrost"
echo ""

echo -e "${YELLOW}4. Troubleshooting:${NC}"
echo "   - Low FPS (~1 FPS): This is normal on Bifrost (Mali-G76)"
echo "   - Black screen: Check VK_ICD_FILENAMES and library paths"
echo "   - syncobj timeout: Use increased timeout from bifrost-v7-compat.patch"
echo ""

echo -e "${YELLOW}5. Debug mode:${NC}"
echo "   export PANFROST_DEBUG=all"
echo "   export MESA_DEBUG=all"
echo "   glxgears  # or your app"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Build system ready! Driver is in: $PREFIX_PANFROST${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
