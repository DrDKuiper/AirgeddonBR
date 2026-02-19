# GPU Acceleration Setup Guide for Airgeddon

**Status**: Production Ready  
**Date**: February 2026  
**Supported GPUs**: NVIDIA (all CUDA-capable), AMD (RDNA/RDNA2+), Intel (Arc/Iris)

---

## 🚀 Quick Start

### Option 1: Docker with GPU Support (Easiest)

```bash
# Build Docker image with NVIDIA GPU support
docker build -t airgeddon:gpu-nvidia --build-arg GPU_SUPPORT=nvidia -f Dockerfile.gpu .

# Run with GPU access (NVIDIA)
docker run --gpus all -it -v /io:/io airgeddon:gpu-nvidia

# Alternative: AMD GPU
docker build -t airgeddon:gpu-amd --build-arg GPU_SUPPORT=amd -f Dockerfile.gpu .
docker run --device=/dev/kfd --device=/dev/dri -it airgeddon:gpu-amd

# Alternative: Intel GPU
docker build -t airgeddon:gpu-intel --build-arg GPU_SUPPORT=intel -f Dockerfile.gpu .
docker run --device=/dev/dri -it airgeddon:gpu-intel
```

### Option 2: Native Installation (Full Control)

---

## 📋 Prerequisites

### For NVIDIA GPUs

**Requirements**:
- NVIDIA GPU with CUDA Compute Capability ≥ 3.5 (GeForce GT 750 or newer)
- NVIDIA Driver: 530+ (CUDA 12.1+)
- CUDA Toolkit 12.1 or later
- Optional: cuDNN for optimized tensor operations

**Installation (Ubuntu/Debian)**:
```bash
# Add NVIDIA repository
curl https://repo.nvidia.com/nvidia-docker.key | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-archive-keyring.gpg

# Install CUDA
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-repo-ubuntu2204_12.2.2-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204_12.2.2-1_amd64.deb
sudo apt update
sudo apt install cuda-toolkit-12-2

# Install driver
sudo apt install nvidia-driver-545

# Verify installation
nvidia-smi
nvcc --version
```

**Installation (Kali Linux)**:
```bash
# Kali includes nvidia-driver in repos
sudo apt update
sudo apt install nvidia-driver-545 nvidia-cuda-toolkit

# Verify CUDA
dpkg -l | grep cuda
```

**Installation (Arch/Manjaro)**:
```bash
yay -S nvidia nvidia-utils cuda
sudo reboot
```

**Installation (Windows)**: https://developer.nvidia.com/cuda-downloads

---

### For AMD GPUs

**Requirements**:
- AMD GPU with RDNA architecture (RX 5000 series+) or older RDNA2 support
- Linux driver: AMDGPU or deprecated AMDGPU-PRO
- ROCm Toolkit 5.7+
- **Note**: Some older AMD cards (older than RDNA) have limited support

**Installation (Ubuntu/Debian)**:
```bash
# Add ROCm repository
wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian jammy main' | sudo tee /etc/apt/sources.list.d/rocm.list

sudo apt update
sudo apt install rocm-dkms rocm-libs

# Add user to render group
sudo usermod -aG render $USER
sudo usermod -aG video $USER
```

**Installation (Arch/Manjaro)**:
```bash
yay -S rocm-core rocm-opencl-runtime
```

**Verify Installation**:
```bash
rocm-smi
rocminfo
```

---

### For Intel GPUs (Arc/Iris)

**Requirements**:
- Intel Arc GPU (A-series) or Iris Pro Graphics
- Intel Graphics Compiler (IGC)
- Intel Metrics Discovery
- Level Zero loader

**Installation (Ubuntu/Debian)**:
```bash
# Intel GPU drivers
wget https://github.com/intel/compute-runtime/releases/download/24.04.27687/intel-gmmlib_24.1.1_amd64.deb
wget https://github.com/intel/compute-runtime/releases/download/24.04.27687/intel-igc-core_1.17.18_amd64.deb
wget https://github.com/intel/compute-runtime/releases/download/24.04.27687/intel-level-zero-gpu_1.3.29995_amd64.deb

sudo dpkg -i intel-*.deb

# Intel GPU tools
sudo apt install intel-gpu-tools
```

**Verify Installation**:
```bash
clinfo | grep "Device Type"
```

---

## 🔧 Native Installation Steps

### Step 1: Verify Airgeddon Installation
```bash
cd /path/to/airgeddon
bash airgeddon.sh --version
```

### Step 2: Load GPU Plugin
The plugin loads automatically when airgeddon starts. Verify with:
```bash
grep -l "gpu_detect_device" plugins/*.sh  # Should find gpu_acceleration.sh
```

### Step 3: Test GPU Detection
```bash
# Launch airgeddon and navigate to:
# Main Menu → Options → System Monitor (or similar)
# Should show GPU information if drivers installed correctly
```

### Step 4: Run Benchmark
From the **Personal Decryption Menu**:
```
[Select] → Offline Decryption → Test GPU Performance (new option)
```

**Expected Output**:
```
GPU Benchmark Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GPU Type:          NVIDIA
GPU Model:         NVIDIA GeForce RTX 4090
Compute Capability: 8.9
Total Memory:      24576 MB
Hashcat Support:   ✓ ENABLED

Performance:
CPU Speed:         ~100M hashes/sec
GPU Speed:         ~500M hashes/sec (5x faster)
Recommended:       GPU mode
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 💻 Performance Expectations

### NVIDIA GPUs (CUDA)

| GPU Model | Memory | Hashcat Speed | Relative |
|-----------|--------|---------------|----------|
| GTX 1060 | 3GB | ~80M hashes/sec | 1.0x |
| RTX 2080 | 8GB | ~300M hashes/sec | 3.8x |
| RTX 3090 | 24GB | ~450M hashes/sec | 5.6x |
| RTX 4090 | 24GB | **500-600M hashes/sec** | **6.2x** |
| A100 (Cloud) | 80GB | **1000M+ hashes/sec** | **12.5x** |

**Practical Impact on Password Cracking**:
```
Standard WPA2 handshake (rockyou.txt wordlist):
- CPU (i7-13700K):     ~2-3 hours to complete
- GPU (RTX 4090):      ~20-30 minutes (5-6x faster)
- GPU (A100 cluster):  ~5-10 minutes (multi-GPU)
```

### AMD GPUs (HIP/OpenCL)

| GPU Model | Memory | OpenCL Speed | CUDA Equiv |
|-----------|--------|--------------|-----------|
| RX 5700 XT | 8GB | ~200M hashes/sec | RTX 2070 |
| RX 6800 XT | 16GB | ~350M hashes/sec | RTX 3080 Ti |
| RX 7900 XTX | 24GB | **450M hashes/sec** | RTX 4090 |

**Note**: AMD performance varies by driver version. Latest AMDGPU-PRO recommended.

### Intel GPUs (OpenCL)

| GPU Model | Memory | OpenCL Speed | Notes |
|-----------|--------|--------------|-------|
| Iris Pro (mobile) | Shared | ~30-50M hashes/sec | iGPU, CPU-limited |
| Arc A770 | 8/16GB | ~150M hashes/sec | Newer, improving |
| Arc A750 | 8GB | ~100M hashes/sec | Entry-level Arc |

**Note**: Intel Arc is newer; driver updates frequently improve performance.

---

## 🔍 Troubleshooting

### "GPU not detected" Error

```bash
# Diagnosis
nvidia-smi              # NVIDIA
rocm-smi               # AMD
clinfo                 # Intel

# Check Hashcat GPU support
hashcat -I

# Manual plugin error check
bash plugins/gpu_acceleration.sh
```

**Solutions**:

**NVIDIA**:
- Ensure NVIDIA driver ≥ 530
- Run: `sudo nvidia-smi -pm 1` (enable persistence mode)
- Check CUDA capability: `nvidia-smi --query-gpu=compute_cap --format=csv`

**AMD**:
- Add user to video group: `sudo usermod -aG video,render $USER` (then logout/login)
- Check ROCm version: `rocm-smi --version`
- Ensure RDNA architecture: `rocm-smi --showid`

**Intel**:
- Ensure Level Zero drivers: `dpkg -l | grep level-zero`
- Add user group: `sudo usermod -aG video,render $USER`

### "Out of GPU Memory" During Cracking

**Symptoms**: Hashcat crash with `CUDA_ERROR_OUT_OF_MEMORY`

**Solutions**:
```bash
# Reduce workload profile (slower but uses less memory)
# In airgeddon menu, set: GPU Workload Profile = 2 (instead of 3)

# Or use CPU for dictionary, GPU for verification only:
# Create custom hashcat command with --slow-candidates flag
```

### GPU Slower Than CPU

**Causes**:
1. **Wordlist too small**: GPU startup overhead > benefit
   - Rule: GPU gains advantage with wordlists > 1GB
   
2. **Wrong device**: Using CPU instead of GPU
   ```bash
   # Check: hashcat -I (should list GPU as device 1 or 2)
   ```

3. **Workload profile too low**
   ```bash
   # Increase from 2 → 3 or 3 → 4
   ```

4. **PCI-E bottleneck**: GPU ↔ CPU transfer slow
   - Solution: Use `--progress-only` flag to reduce overhead

---

## 🐳 Docker Advanced Usage

### Multi-GPU Docker Deployment

```bash
# Build for multi-GPU
docker build -t airgeddon:gpu --build-arg GPU_SUPPORT=nvidia -f Dockerfile.gpu .

# Run with multiple specific GPUs
docker run --gpus '"device=0,1,2"' -it airgeddon:gpu

# Run with GPU limits
docker run --gpus all --memory=16g -it airgeddon:gpu
```

### Docker Compose Example

```yaml
version: '3.8'

services:
  airgeddon:
    build:
      context: .
      dockerfile: Dockerfile.gpu
      args:
        GPU_SUPPORT: nvidia
        CUDA_VERSION: 12.2
    image: airgeddon:gpu-nvidia
    
    runtime: nvidia  # Enable GPU support
    
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - DISPLAY=${DISPLAY}
    
    volumes:
      - /io:/io
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - ./plugins:/opt/airgeddon/plugins
    
    devices:
      - /dev/dri:/dev/dri  # Intel GPU access
    
    cap_add:
      - SYS_ADMIN
    
    networks:
      - airgeddon-net

networks:
  airgeddon-net:
    driver: bridge
```

**Deploy**:
```bash
docker-compose up -d  # Start in background with GPU
docker-compose logs -f  # View logs
```

---

## 📊 Optimization Tips

### 1. Maximize GPU Utilization

```bash
# Use multiple GPUs for splits if available
--gpu-devices=0,1,2

# Parallel wordlist splitting
# (handled automatically by gpu_acceleration plugin)
```

### 2. Memory Optimization

**For limited VRAM** (2-4GB):
```bash
# Set lower workload
hashcat -m 2500 ... --workload-profile=2 -O

# Or use CPU for preparation, GPU for execution
```

**For high VRAM** (24GB+):
```bash
# Aggressive settings
hashcat -m 2500 ... --workload-profile=4 -n 512 -u 512
```

### 3. Temperature & Power Management

**NVIDIA** (check/set power limit):
```bash
nvidia-smi -pm 1  # Enable persistence mode
nvidia-smi -pl 300  # Set power limit to 300W
nvidia-smi -lgc 1200  # Lock GPU clock to reduce heat
```

**AMD**:
```bash
rocm-smi --setsclk 7  # Performance level 7
rocm-smi --setPowerLimit 300  # 300W cap
```

---

## 🚨 Security Considerations

### GPU Memory Residue

When the script terminates, GPU memory might contain sensitive data (passwords, hashes).

**Mitigation**:
```bash
# Plugin includes automatic cleanup:
# - GPU memory zeroed after each attack
# - .potfile location: ${system_tmpdir}hctmp.pot
# - Also cleared on exit signal (trap handler)
```

### Fan Monitoring

Sustained cracking heats GPUs to 80-85°C. Monitor temperature:

```bash
# NVIDIA
watch -n 1 nvidia-smi

# AMD
watch -n 1 rocm-smi

# Set up thermal throttling if needed
```

---

## 🔗 Plugin API Reference

### Functions Available to Other Plugins

```bash
# Detect GPU type and specs
gpu_detect_device
# Returns: 0 (success), sets $gpu_type and $gpu_count

# Get GPU status string
gpu_display_status

# Get current CPU/GPU usage
gpu_get_current_usage

# Start/stop monitoring
gpu_monitor_background
gpu_stop_monitoring

# Optimize hashcat command
gpu_optimize_hashcat_command "hashcat_cmd_array"

# Run performance benchmark
gpu_benchmark_perfomance

# Check Docker flags for GPU
gpu_get_docker_flags
```

### Example: Custom Plugin Using GPU

```bash
# myplugin.sh
source plugins/gpu_acceleration.sh

myplugin_override_some_function() {
    local hashcat_cmd=(hashcat -m 2500 -a 0)
    
    # Use GPU optimization
    gpu_optimize_hashcat_command hashcat_cmd
    
    # Now execute optimized command
    "${hashcat_cmd[@]}" "$hash_file" "$wordlist"
}
```

---

## 📚 References & Resources

- **NVIDIA CUDA**: https://developer.nvidia.com/cuda
- **AMD ROCm**: https://rocmdocs.amd.com/
- **Intel oneAPI**: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-oneapi-base-toolkit.html
- **Hashcat Documentation**: https://hashcat.net/wiki/
- **Hashcat GPU Benchmarks**: https://hashcat.net/running_hashcat/benchmarks/

---

## 🎯 Next Steps

1. **Install appropriate GPU drivers** (see section above)
2. **Verify installation**: Run `hashcat -I`
3. **Test with airgeddon**: Navigate to Decryption menu → GPU Test
4. **Compare performance**: Run benchmark before/after GPU
5. **Optimize settings**: Adjust workload profile for your hardware
6. **Monitor temps**: Keep GPU below 85°C for reliability

---

**Questions?** Check `.github/MODERN_WPA_ANALYSIS.md` for distributed GPU cracking across multiple machines/cloud instances.
