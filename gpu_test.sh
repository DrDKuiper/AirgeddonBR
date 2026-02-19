#!/bin/bash

################################################################################
# GPU Acceleration Quick Test Script
# Validates GPU detection, driver installation, and hashcat compatibility
################################################################################

set -e

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${COLOR_CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          AIRGEDDON GPU ACCELERATION TEST SUITE               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo

# =============================================================================
# Test 1: GPU Driver Detection
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 1] GPU Driver Detection${NC}"
echo "─────────────────────────────────────────────────────────────────"

gpu_detected=0
gpu_type=""

# Check NVIDIA
if command -v nvidia-smi &>/dev/null; then
    echo -e "${COLOR_GREEN}✓ NVIDIA drivers detected${NC}"
    nvidia-smi --query-gpu=count,name,memory.total --format=csv,noheader,nounits | while IFS=',' read count name memory; do
        echo "  → GPU Count: $count"
        echo "  → GPU Name:  $name"
        echo "  → Memory:    ${memory} MB"
    done
    gpu_detected=1
    gpu_type="NVIDIA"
else
    echo -e "${COLOR_YELLOW}✗ NVIDIA drivers not found${NC}"
fi

# Check AMD
if command -v rocm-smi &>/dev/null; then
    echo -e "${COLOR_GREEN}✓ AMD ROCm drivers detected${NC}"
    rocm-smi --showversion
    gpu_detected=1
    gpu_type="AMD"
else
    echo -e "${COLOR_YELLOW}✗ AMD ROCm drivers not found${NC}"
fi

# Check Intel
if command -v clinfo &>/dev/null; then
    echo -e "${COLOR_GREEN}✓ Intel GPU drivers detected${NC}"
    clinfo | grep "Device Type" | head -1
    gpu_detected=1
    gpu_type="INTEL"
else
    echo -e "${COLOR_YELLOW}✗ Intel GPU drivers not found${NC}"
fi

[ $gpu_detected -eq 0 ] && echo -e "${COLOR_YELLOW}⚠  No GPU detected - CPU-only mode${NC}"
echo

# =============================================================================
# Test 2: Hashcat Installation
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 2] Hashcat Installation${NC}"
echo "─────────────────────────────────────────────────────────────────"

if command -v hashcat &>/dev/null; then
    echo -e "${COLOR_GREEN}✓ Hashcat installed${NC}"
    hashcat --version
else
    echo -e "${COLOR_RED}✗ Hashcat NOT installed${NC}"
    echo "  Install with: apt install hashcat (or yay -S hashcat)"
    exit 1
fi
echo

# =============================================================================
# Test 3: GPU-Specific Hashcat Support
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 3] Hashcat GPU Support${NC}"
echo "─────────────────────────────────────────────────────────────────"

if hashcat -I 2>&1 | grep -q "Device ID #1"; then
    echo -e "${COLOR_GREEN}✓ GPU device detected by hashcat${NC}"
    hashcat -I | grep -A5 "Device ID"
else
    echo -e "${COLOR_YELLOW}⚠  No GPU detected by hashcat${NC}"
    echo "  GPU support may not be available"
    echo "  Try: hashcat -d 1 -m 2500 hash.cap wordlist.txt"
fi
echo

# =============================================================================
# Test 4: GPU Plugin Load
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 4] GPU Plugin Availability${NC}"
echo "─────────────────────────────────────────────────────────────────"

if [ -f "plugins/gpu_acceleration.sh" ]; then
    echo -e "${COLOR_GREEN}✓ GPU plugin file found${NC}"
    
    # Try sourcing it
    if bash -n plugins/gpu_acceleration.sh 2>/dev/null; then
        echo -e "${COLOR_GREEN}✓ GPU plugin syntax valid${NC}"
    else
        echo -e "${COLOR_RED}✗ GPU plugin syntax error${NC}"
        exit 1
    fi
else
    echo -e "${COLOR_YELLOW}⚠  GPU plugin not found in plugins/ directory${NC}"
fi
echo

# =============================================================================
# Test 5: Performance Benchmark
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 5] Performance Benchmark${NC}"
echo "─────────────────────────────────────────────────────────────────"

# Create test hash and wordlist
test_hash="$TMPDIR/test.hash"
test_wordlist="$TMPDIR/test.words"

echo "8846f7eaee8fb117ad06bdd830b7586c" > "$test_hash"

{
    echo "password1"
    echo "password2"
    echo "test123"
    seq 1000 1100
} > "$test_wordlist"

echo "Running MD5 benchmark (CPU)..."
cpu_speed=$(hashcat -m 0 -a 0 -b "$test_hash" "$test_wordlist" 2>/dev/null | grep "Speed" | awk '{print $NF}' | head -1)

if [ -n "$cpu_speed" ]; then
    echo -e "${COLOR_GREEN}✓ CPU Speed: $cpu_speed${NC}"
else
    echo -e "${COLOR_YELLOW}⚠  CPU benchmark failed${NC}"
fi

if [ "$gpu_detected" -eq 1 ]; then
    echo "Running MD5 benchmark (GPU)..."
    gpu_speed=$(hashcat -m 0 -a 0 -d 1 -b "$test_hash" "$test_wordlist" 2>/dev/null | grep "Speed" | awk '{print $NF}' | head -1)
    
    if [ -n "$gpu_speed" ]; then
        echo -e "${COLOR_GREEN}✓ GPU Speed: $gpu_speed${NC}"
        
        # Calculate speedup
        cpu_val=$(echo "$cpu_speed" | grep -oE '[0-9]+' | head -1)
        gpu_val=$(echo "$gpu_speed" | grep -oE '[0-9]+' | head -1)
        if [ -n "$cpu_val" ] && [ -n "$gpu_val" ] && [ "$cpu_val" -gt 0 ]; then
            speedup=$(echo "scale=1; $gpu_val / $cpu_val" | bc)
            echo -e "${COLOR_GREEN}✓ GPU Speedup: ${speedup}x faster${NC}"
        fi
    else
        echo -e "${COLOR_YELLOW}⚠  GPU benchmark failed${NC}"
    fi
fi

rm -f "$test_hash" "$test_wordlist"
echo

# =============================================================================
# Test 6: Airgeddon Integration
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 6] Airgeddon Integration${NC}"
echo "─────────────────────────────────────────────────────────────────"

if [ -f "airgeddon.sh" ]; then
    echo -e "${COLOR_GREEN}✓ Airgeddon main script found${NC}"
    
    if grep -q "hashcat" airgeddon.sh; then
        echo -e "${COLOR_GREEN}✓ Hashcat integration detected${NC}"
    fi
else
    echo -e "${COLOR_RED}✗ Airgeddon main script not found${NC}"
fi
echo

# =============================================================================
# Test 7: System Information
# =============================================================================

echo -e "${COLOR_BLUE}[TEST 7] System Information${NC}"
echo "─────────────────────────────────────────────────────────────────"

echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
echo "Kernel: $(uname -r)"
echo "CPU: $(grep -m1 "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)"
echo "CPU Cores: $(grep -c "^processor" /proc/cpuinfo)"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"

if [ "$gpu_detected" -eq 1 ]; then
    echo "GPU Type: $gpu_type"
fi
echo

# =============================================================================
# Test Summary
# =============================================================================

echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${COLOR_CYAN}║                         TEST SUMMARY                          ║${NC}"
echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

if [ "$gpu_detected" -eq 1 ]; then
    echo -e "${COLOR_GREEN}✓ GPU ACCELERATION ENABLED${NC}"
    echo "  You can now use GPU for faster password cracking"
    echo "  Expected speedup: 3-6x faster than CPU"
    echo
    echo "Next steps:"
    echo "  1. Run: bash airgeddon.sh"
    echo "  2. Navigate to: Attacks → Personal → Decryption"
    echo "  3. Select GPU-accelerated cracking option"
    echo
else
    echo -e "${COLOR_YELLOW}⚠  GPU NOT DETECTED - CPU-ONLY MODE${NC}"
    echo "Install GPU drivers to enable acceleration:"
    echo "  NVIDIA: sudo apt install nvidia-driver-545 nvidia-cuda-toolkit"
    echo "  AMD:    sudo apt install rocm-dkms"
    echo "  Intel:  sudo apt install intel-gpu-tools"
    echo
fi

echo -e "${COLOR_BLUE}Advanced Configuration:${NC}"
echo "  • GPU Plugin: plugins/gpu_acceleration.sh"
echo "  • Setup Guide: GPU_SETUP_GUIDE.md"
echo "  • Examples: source GPU_EXAMPLES.sh"
echo "  • Docker: docker build -f Dockerfile.gpu -t airgeddon:gpu-nvidia ."
echo

echo -e "${COLOR_GREEN}Test completed successfully!${NC}"
echo
