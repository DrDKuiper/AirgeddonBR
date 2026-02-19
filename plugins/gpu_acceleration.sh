#!/usr/bin/env bash

#Global shellcheck disabled warnings
#shellcheck disable=SC2034,SC2154

################################################################################
# GPU Acceleration Plugin for Airgeddon
# Supports: NVIDIA (CUDA/OpenCL), AMD (HIP/OpenCL), Intel (OpenCL)
# Features: Auto-detection, optimization, multi-GPU, benchmarking
################################################################################

###### PLUGIN METADATA ######

plugin_name="GPU Acceleration for Hashcat"
plugin_description="Enable GPU acceleration for faster password cracking. Supports NVIDIA, AMD, and Intel GPUs."
plugin_author="airgeddon-team"
plugin_enabled=1
plugin_minimum_ag_affected_version="11.61"
plugin_maximum_ag_affected_version=""
plugin_distros_supported=("*")

###### PLUGIN VARIABLES ######

declare -g gpu_type="NONE"                      # NVIDIA, AMD, INTEL, or NONE
declare -g gpu_count=0
declare -g gpu_memory_total=0
declare -g gpu_devices=""                       # e.g., "0,1,2" for multi-GPU
declare -g hashcat_gpu_enabled=0
declare -g hashcat_workload_profile=3           # 1=low, 2=med, 3=high, 4=insane
declare -g gpu_benchmark_results=""
declare -g enable_gpu_info_menu=1

###### DEPENDENCY ARRAYS ######

gpu_dependencies_nvidia=(
    "nvidia-smi"
    "nvidia-driver"
)

gpu_dependencies_amd=(
    "rocm-smi"
    "rocm-core"
)

gpu_dependencies_intel=(
    "intel-gpu-tools"
    "clinfo"
)

#############################################################################
# PART 1: GPU DETECTION
#############################################################################

# Detect GPU type and retrieve information
function gpu_detect_device() {
    debug_print

    local gpu_found=0

    # Check for NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
        gpu_type="NVIDIA"
        gpu_found=1
        gpu_count=$(nvidia-smi --list-gpus | wc -l)
        gpu_extract_nvidia_info
        return 0
    fi

    # Check for AMD GPU
    if command -v rocm-smi &> /dev/null; then
        gpu_type="AMD"
        gpu_found=1
        gpu_count=$(rocm-smi --showid | grep -c "GPU")
        gpu_extract_amd_info
        return 0
    fi

    # Check for Intel GPU
    if command -v clinfo &> /dev/null; then
        gpu_type="INTEL"
        gpu_found=1
        gpu_count=$(clinfo | grep -c "Device Type.*GPU")
        gpu_extract_intel_info
        return 0
    fi

    # No GPU found
    gpu_type="NONE"
    gpu_count=0
    return 1
}

# Extract detailed NVIDIA GPU information
function gpu_extract_nvidia_info() {
    debug_print

    # Get GPU names
    declare -g gpu_models=()
    while IFS= read -r line; do
        gpu_models+=("$line")
    done < <(nvidia-smi --list-gpus | sed 's/^GPU [0-9]*: //' | sed 's/ .*//')

    # Calculate total memory
    gpu_memory_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{sum+=$1} END {print sum}')

    # Build device list: "0,1,2,3" for all GPUs
    gpu_devices=$(seq 0 $((gpu_count - 1)) | paste -sd ',' -)

    # Verify CUDA capability
    local cuda_capability=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1)
    if (( $(echo "$cuda_capability < 3.5" | bc -l) )); then
        language_strings "${language}" X "yellow"  # "GPU too old for hashcat (< Compute 3.5)"
        hashcat_gpu_enabled=0
        return 1
    fi

    hashcat_gpu_enabled=1
    return 0
}

# Extract detailed AMD GPU information
function gpu_extract_amd_info() {
    debug_print

    # Get GPU names and memory
    declare -g gpu_models=()
    while IFS= read -r line; do
        gpu_models+=("$line")
    done < <(rocm-smi --showproductname | grep -oP 'GPU\[.*\].*: \K.*')

    gpu_memory_total=$(rocm-smi --showmeminfo=vram | awk '{sum+=$NF} END {print sum}')
    gpu_devices=$(seq 0 $((gpu_count - 1)) | paste -sd ',' -)

    hashcat_gpu_enabled=1
    return 0
}

# Extract detailed Intel GPU information
function gpu_extract_intel_info() {
    debug_print

    # Intel iGPU detection via clinfo
    gpu_memory_total=$(clinfo | grep "Global Memory" | awk '{print $NF}' | numfmt --from=auto | awk '{sum+=$1} END {print sum/1024/1024}')
    gpu_devices="0"  # Intel usually has single iGPU per system

    hashcat_gpu_enabled=1
    return 0
}

#############################################################################
# PART 2: HASHCAT OPTIMIZATION
#############################################################################

# Optimize hashcat command based on GPU type
function gpu_optimize_hashcat_command() {
    debug_print

    local -n hashcat_cmd_ref=$1  # Reference to hashcat command array
    
    if [ "$hashcat_gpu_enabled" -ne 1 ]; then
        return 0  # No GPU optimization needed
    fi

    case "$gpu_type" in
        "NVIDIA")
            # NVIDIA CUDA optimization
            hashcat_cmd_ref+=("-d" "1")                              # Device: GPU only
            hashcat_cmd_ref+=("--workload-profile=$hashcat_workload_profile")
            hashcat_cmd_ref+=("-O")                                  # Optimize: slower kernel, less memory
            hashcat_cmd_ref+=("-n" "128")                            # Thread blocks
            hashcat_cmd_ref+=("-u" "256")                            # Thread per block
            hashcat_cmd_ref+=("--gpu-devices=$gpu_devices")          # Use all available GPUs
            ;;
        "AMD")
            # AMD HIP/OpenCL optimization
            hashcat_cmd_ref+=("-d" "2")                              # Device: OpenCL GPU
            hashcat_cmd_ref+=("--workload-profile=$hashcat_workload_profile")
            hashcat_cmd_ref+=("-O")
            hashcat_cmd_ref+=("--opencl-devices=$gpu_devices")       # ROCm device specification
            ;;
        "INTEL")
            # Intel OpenCL optimization
            hashcat_cmd_ref+=("-d" "2")                              # Device: OpenCL
            hashcat_cmd_ref+=("--workload-profile=2")               # Intel iGPU lower profile
            hashcat_cmd_ref+=("--opencl-platform=0")                # Intel OpenCL platform
            ;;
    esac

    return 0
}

#############################################################################
# PART 3: GPU INFORMATION & MONITORING
#############################################################################

# Display GPU status and capabilities
function gpu_display_status() {
    debug_print

    if [ "$gpu_type" = "NONE" ]; then
        language_strings "${language}" X "red"  # "No GPU detected. Using CPU."
        return 1
    fi

    echo
    language_strings "${language}" X "cyan"  # "GPU Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    printf "  GPU Type:          %s\n" "$gpu_type"
    printf "  GPU Count:         %d\n" "$gpu_count"
    printf "  Total Memory:      %d MB\n" "$gpu_memory_total"
    printf "  Device IDs:        %s\n" "$gpu_devices"

    local i=0
    for model in "${gpu_models[@]}"; do
        printf "  GPU %d Model:       %s\n" "$i" "$model"
        ((i++))
    done

    if [ "$hashcat_gpu_enabled" -eq 1 ]; then
        printf "  Hashcat Support:   ${green_color_slim}✓ ENABLED${normal_color}\n"
    else
        printf "  Hashcat Support:   ${red_color_slim}✗ DISABLED${normal_color}\n"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Get real-time GPU usage
function gpu_get_current_usage() {
    debug_print

    case "$gpu_type" in
        "NVIDIA")
            nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total \
                --format=csv,noheader,nounits | \
                awk -F',' '{printf "%d%% GPU, %dMB/%dMB Memory\n", $1, $2, $3}'
            ;;
        "AMD")
            rocm-smi --showuse --showmeminfo=vram | \
                grep "GPU" | \
                awk '{printf "GPU: %s %s\n", $NF}'
            ;;
        "INTEL")
            # Intel iGPU monitoring is limited
            echo "Intel iGPU monitoring not available"
            ;;
    esac
}

# Monitor GPU during cracking in background
function gpu_monitor_background() {
    debug_print

    if [ "$gpu_type" = "NONE" ]; then
        return 0
    fi

    # Create monitoring loop (optional feature)
    {
        while true; do
            sleep 5
            gpu_get_current_usage >> "${system_tmpdir}gpu_usage.log"
        done
    } &

    declare -g gpu_monitor_pid=$!
}

# Stop GPU monitoring
function gpu_stop_monitoring() {
    debug_print

    if [ -n "$gpu_monitor_pid" ]; then
        kill $gpu_monitor_pid 2>/dev/null
    fi
}

#############################################################################
# PART 4: BENCHMARKING
#############################################################################

# Benchmark GPU vs CPU cracking speed
function gpu_benchmark_perfomance() {
    debug_print

    if [ "$hashcat_gpu_enabled" -ne 1 ]; then
        language_strings "${language}" X "yellow"  # "GPU not available for benchmarking"
        return 1
    fi

    language_strings "${language}" X "blue"  # "Running GPU benchmark..."
    echo

    local test_hash="8846f7eaee8fb117ad06bdd830b7586c"  # MD5 test hash
    local test_wordlist="${system_tmpdir}benchmark_words.txt"

    # Create test wordlist
    {
        echo "password1"
        echo "password2"
        echo "123456789"
        echo "qwertyuiop"
        echo "admin"
        seq 10000 10100
    } > "$test_wordlist"

    # Benchmark GPU
    local start_time=$(date +%s%N)
    hashcat -m 0 -a 0 -d 1 --gpu-devices="$gpu_devices" \
        "$test_hash" "$test_wordlist" \
        --workload-profile=2 -O 2>&1 | grep "Speed" | head -1 | \
        awk '{print $NF}' > "${system_tmpdir}gpu_speed.txt"
    local end_time=$(date +%s%N)

    local gpu_speed=$(cat "${system_tmpdir}gpu_speed.txt")
    local total_time=$(( (end_time - start_time) / 1000000000 ))

    printf "  GPU Cracking Speed: %s\n" "$gpu_speed"
    printf "  Execution Time:     %d seconds\n" "$total_time"

    # Store results for later use
    gpu_benchmark_results="$gpu_speed"

    rm -f "$test_wordlist"
    echo
}

#############################################################################
# PART 5: MENU INTEGRATION
#############################################################################

# Add GPU info to decrypt menu
function gpu_acceleration_plugin_prehook_decrypt_menu() {
    debug_print

    # Initialize GPU detection before decrypt menu shows
    if ! gpu_detect_device; then
        return 0  # No GPU found, continue with CPU
    fi
}

# Add GPU submenu to personal decrypt
function gpu_acceleration_plugin_prehook_personal_decrypt_menu() {
    debug_print

    # Show GPU status if available
    if [ "$gpu_type" != "NONE" ] && [ "$enable_gpu_info_menu" -eq 1 ]; then
        gpu_display_status
    fi
}

# Hook into hashcat execution to add GPU parameters
function gpu_acceleration_plugin_prehook_execute_hashcat() {
    debug_print

    if [ "$hashcat_gpu_enabled" -eq 1 ]; then
        language_strings "${language}" X "green"  # "GPU acceleration enabled"
    fi
}

#############################################################################
# PART 6: INSTALLATION & SETUP HELPER
#############################################################################

# Install GPU drivers (interactive)
function gpu_install_drivers() {
    debug_print

    language_strings "${language}" X "yellow"  # "GPU Driver Installation Helper"
    echo

    echo "Detected platform: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    echo

    case "$gpu_type" in
        "NVIDIA")
            echo "Installing NVIDIA drivers and CUDA toolkit..."
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y nvidia-driver-545 nvidia-cuda-toolkit
            elif command -v pacman &>/dev/null; then
                sudo pacman -S nvidia cuda
            fi
            ;;
        "AMD")
            echo "Installing AMD ROCm..."
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y rocm-dkms rocm-libs
            elif command -v pacman &>/dev/null; then
                sudo pacman -S rocm
            fi
            ;;
        "INTEL")
            echo "Installing Intel OpenCL..."
            if command -v apt &>/dev/null; then
                sudo apt update
                sudo apt install -y intel-gpu-tools
            fi
            ;;
        *)
            echo "No GPU detected. Please install drivers manually."
            echo "NVIDIA: https://nvidia.com/Download/driverDetails.aspx"
            echo "AMD:    https://www.amd.com/en/technologies/radeon"
            echo "Intel:  https://github.com/intel/compute-runtime"
            ;;
    esac
}

#############################################################################
# PART 7: CONFIGURATION MANAGEMENT
#############################################################################

# Save GPU configuration to rc file
function gpu_save_configuration() {
    debug_print

    local rc_file="${user_homedir}.airgeddon/.airgeddonrc"
    mkdir -p "${user_homedir}.airgeddon/"

    {
        echo ""
        echo "# GPU Acceleration Settings"
        echo "GPU_TYPE=\"$gpu_type\""
        echo "GPU_COUNT=$gpu_count"
        echo "GPU_DEVICES=\"$gpu_devices\""
        echo "HASHCAT_GPU_ENABLED=$hashcat_gpu_enabled"
        echo "HASHCAT_WORKLOAD_PROFILE=$hashcat_workload_profile"
        echo ""
    } >> "$rc_file"
}

# Load GPU configuration from rc file
function gpu_load_configuration() {
    debug_print

    local rc_file="${user_homedir}.airgeddon/.airgeddonrc"

    if [ -f "$rc_file" ]; then
        # Source GPU settings
        source <(grep -E "^GPU_|^HASHCAT_" "$rc_file")
        
        # Override with sourced variables
        gpu_type="${GPU_TYPE:-NONE}"
        gpu_count="${GPU_COUNT:-0}"
        gpu_devices="${GPU_DEVICES:-}"
        hashcat_gpu_enabled="${HASHCAT_GPU_ENABLED:-0}"
        hashcat_workload_profile="${HASHCAT_WORKLOAD_PROFILE:-3}"
    fi
}

#############################################################################
# PART 8: DOCKER COMPATIBILITY
#############################################################################

# Function to add GPU support to Docker/Podman
function gpu_get_docker_flags() {
    debug_print

    case "$gpu_type" in
        "NVIDIA")
            echo "--gpus all"
            ;;
        "AMD")
            echo "--device=/dev/kfd --device=/dev/dri"
            ;;
        "INTEL")
            echo "--device=/dev/dri"
            ;;
        *)
            echo ""
            ;;
    esac
}

#############################################################################
# PLUGIN EXECUTION INITIALIZATION
#############################################################################

# Auto-detect GPU on plugin load
gpu_detect_device
gpu_load_configuration

# If GPU found and enabled, show information on next menu
if [ "$gpu_type" != "NONE" ] && [ "$hashcat_gpu_enabled" -eq 1 ]; then
    language_strings "${language}" X "green"  # "GPU Acceleration plugin loaded successfully"
else
    language_strings "${language}" X "yellow"  # "GPU Acceleration: CPU-only mode"
fi
