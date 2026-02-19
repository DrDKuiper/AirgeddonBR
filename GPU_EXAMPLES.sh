#!/usr/bin/env bash

################################################################################
# GPU Acceleration Integration Examples
# Shows how to properly integrate GPU support into Airgeddon plugins/features
################################################################################

#=============================================================================
# EXAMPLE 1: Simple GPU-Accelerated WPA2 Cracking
#=============================================================================

example_gpu_wpa2_cracking() {
    local hash_file="$1"          # handshake.hc22000
    local wordlist="$2"           # rockyou.txt
    
    # Step 1: Load GPU plugin
    source plugins/gpu_acceleration.sh || return 1
    
    # Step 2: Detect GPU (already done in plugin initialization)
    if [ "$gpu_type" = "NONE" ]; then
        echo "[!] No GPU detected, using CPU"
        hashcat -m 22000 -a 0 "$hash_file" "$wordlist"
    else
        echo "[+] GPU detected: $gpu_type"
        
        # Step 3: Build hashcat command
        local cmd=(
            hashcat
            -m 22000          # WPA2 PMKID mode
            -a 0              # Dictionary attack
            --status          # Show progress
            --status-timer=5  # Update every 5 seconds
        )
        
        # Step 4: Optimize for GPU
        gpu_optimize_hashcat_command cmd
        
        # Step 5: Execute
        echo "[*] Starting GPU-accelerated cracking..."
        "${cmd[@]}" "$hash_file" "$wordlist"
    fi
}

#=============================================================================
# EXAMPLE 2: Custom Plugin with GPU Support
#=============================================================================

# File: plugins/fast_decryption_plugin.sh

cat > /tmp/fast_decryption_plugin.sh <<'EOF'
#!/usr/bin/env bash
#shellcheck disable=SC2034,SC2154

plugin_name="Fast GPU Decryption"
plugin_description="Optimized decryption using GPU acceleration"
plugin_author="dev-team"
plugin_enabled=1
plugin_distros_supported=("*")

# Hook: Override old decrypt menu
fast_decryption_plugin_override_personal_decrypt_menu() {
    # Include GPU support
    source plugins/gpu_acceleration.sh
    
    # Show GPU status if available
    if [ -n "$gpu_type" ] && [ "$gpu_type" != "NONE" ]; then
        gpu_display_status
    fi
    
    # Custom optimized decryption
    fast_gpu_wpa2_decryption
}

fast_gpu_wpa2_decryption() {
    # Menu display
    clear
    language_strings "${language}" 300 "blue"  # "Fast GPU Decryption"
    echo
    
    # Ask for hash file
    read -p "Enter hash file path: " hash_file
    [ ! -f "$hash_file" ] && return
    
    # Ask for wordlist
    read -p "Enter wordlist path: " wordlist
    [ ! -f "$wordlist" ] && return
    
    # Prepare command
    local cmd=(
        hashcat
        -m 22000
        -a 0
        --show          # Stop after first match
        -O              # Optimize
        --remove        # Remove hash after crack
    )
    
    # GPU optimization
    if [ "$hashcat_gpu_enabled" -eq 1 ]; then
        gpu_optimize_hashcat_command cmd
        printf "${green_color}GPU ACCELERATION ENABLED${normal_color}\n"
    else
        printf "${yellow_color}CPU-ONLY MODE${normal_color}\n"
    fi
    
    # Execute
    "${cmd[@]}" "$hash_file" "$wordlist"
}
EOF

#=============================================================================
# EXAMPLE 3: Multi-GPU Distributed Cracking
#=============================================================================

example_multi_gpu_cracking() {
    local hash_file="$1"
    local wordlist="$2"
    
    source plugins/gpu_acceleration.sh
    
    # Check if we have multiple GPUs
    if [ "$gpu_count" -lt 2 ]; then
        echo "[!] Single GPU detected, using standard cracking"
        return 1
    fi
    
    echo "[+] $gpu_count GPUs detected: $gpu_devices"
    
    # Split wordlist into $gpu_count parts
    local wordlist_size=$(wc -l < "$wordlist")
    local words_per_gpu=$((wordlist_size / gpu_count))
    
    local ifs_backup=$IFS
    IFS=',' read -ra gpu_array <<< "$gpu_devices"
    
    local i=0
    for gpu_id in "${gpu_array[@]}"; do
        local start=$((i * words_per_gpu + 1))
        local end=$(((i + 1) * words_per_gpu))
        [ $i -eq $((gpu_count - 1)) ] && end=$wordlist_size
        
        # Extract subset for this GPU
        sed -n "${start},${end}p" "$wordlist" > "/tmp/wordlist_gpu${gpu_id}.txt"
        
        # Run in background on specific GPU
        (
            hashcat -m 22000 -a 0 \
                -d 1 --gpu-devices="$gpu_id" \
                "$hash_file" "/tmp/wordlist_gpu${gpu_id}.txt" &
        ) &
        
        ((i++))
    done
    
    IFS=$ifs_backup
    wait
    echo "[+] Multi-GPU cracking complete"
}

#=============================================================================
# EXAMPLE 4: GPU Performance Comparison
#=============================================================================

example_gpu_benchmark() {
    source plugins/gpu_acceleration.sh
    
    echo "[*] GPU Performance Benchmark"
    echo "===================================="
    echo
    
    # Show GPU info
    gpu_display_status
    
    if [ "$hashcat_gpu_enabled" -ne 1 ]; then
        echo "[!] GPU not available for benchmarking"
        return 1
    fi
    
    # Run benchmark
    gpu_benchmark_perfomance
    
    # Show results
    if [ -n "$gpu_benchmark_results" ]; then
        echo "[+] Benchmark Complete"
        echo "    Speed: $gpu_benchmark_results"
        echo
        echo "[*] Time estimates for WPA2 cracking:"
        echo "    rockyou.txt (14M words):  ~2-5 minutes"
        echo "    Custom dict (100M words): ~15-30 minutes"
        echo "    Brute force (8 char):     ~30 minutes - 2 hours"
    fi
}

#=============================================================================
# EXAMPLE 5: GPU-Aware Hashcat Command Builder
#=============================================================================

build_optimized_hashcat_command() {
    local hash_mode=$1    # 2500, 22000, 5500
    local attack_type=$2  # dict, hybrid, mask, brute
    local hash_file=$3
    local wordlist=$4
    
    source plugins/gpu_acceleration.sh
    
    # Base command
    local cmd=(hashcat -m "$hash_mode" -a "$attack_type")
    
    # Add options based on attack type
    case "$attack_type" in
        "0")  # Dictionary
            cmd+=("$hash_file" "$wordlist")
            ;;
        "1")  # Combination
            cmd+=("$hash_file" "$wordlist" "$wordlist")
            ;;
        "3")  # Brute force
            cmd+=("$hash_file" "?u?l?d?s?d?d?d?d")
            ;;
        "6")  # Hybrid dict + mask
            cmd+=("$hash_file" "$wordlist" "?d?d?d?d")
            ;;
    esac
    
    # Add GPU optimization if available
    if [ "$hashcat_gpu_enabled" -eq 1 ]; then
        gpu_optimize_hashcat_command cmd
    else
        # CPU optimization
        cmd+=("-d" "1")  # CPU only
    fi
    
    # Print for execution
    printf '%s\n' "${cmd[@]}"
}

#=============================================================================
# EXAMPLE 6: Integration with Airgeddon Menu System
#=============================================================================

# This would go in airgeddon.sh or a plugin

gpu_info_menu_hook() {
    # Add to main menu
    source plugins/gpu_acceleration.sh
    
    # Only show if GPU detected
    [ "$gpu_type" = "NONE" ] && return
    
    clear
    language_strings "${language}" X "cyan"  # "GPU Information"
    echo
    gpu_display_status
    
    # Show advanced options
    echo "GPU Advanced Options:"
    echo "1) Run Performance Benchmark"
    echo "2) Monitor GPU Usage"
    echo "3) Configure GPU Settings"
    echo "4) Back to Main Menu"
    echo
    read -p "Select option: " gpu_option
    
    case $gpu_option in
        1) gpu_benchmark_perfomance ;;
        2) gpu_get_current_usage ;;
        3) configure_gpu_settings ;;
        4) return ;;
    esac
}

configure_gpu_settings() {
    source plugins/gpu_acceleration.sh
    
    clear
    echo "GPU Configuration:"
    echo "═══════════════════════════════════"
    echo
    printf "Current Settings:\n"
    printf "  GPU Type:              %s\n" "$gpu_type"
    printf "  GPU Count:             %d\n" "$gpu_count"
    printf "  Active Devices:        %s\n" "$gpu_devices"
    printf "  Workload Profile:      %d\n" "$hashcat_workload_profile"
    echo
    
    echo "1) Change Workload Profile (1-4)"
    echo "   Profile 1: Low workload (slow GPU, low memory)"
    echo "   Profile 2: Medium workload"
    echo "   Profile 3: High workload (fast)"
    echo "   Profile 4: Insane workload (very fast, high memory)"
    echo
    read -p "Select profile (1-4): " new_profile
    
    if [[ $new_profile =~ ^[1-4]$ ]]; then
        hashcat_workload_profile="$new_profile"
        gpu_save_configuration
        echo "[+] Workload profile updated to $new_profile"
    else
        echo "[!] Invalid profile"
    fi
}

#=============================================================================
# EXAMPLE 7: Docker GPU Integration
#=============================================================================

# Build GPU-enabled Docker image
example_docker_gpu_build() {
    echo "Building Docker image with GPU support..."
    
    # NVIDIA
    docker build -t airgeddon:gpu-nvidia \
        --build-arg GPU_SUPPORT=nvidia \
        -f Dockerfile.gpu .
    
    # AMD
    docker build -t airgeddon:gpu-amd \
        --build-arg GPU_SUPPORT=amd \
        -f Dockerfile.gpu .
    
    # Intel
    docker build -t airgeddon:gpu-intel \
        --build-arg GPU_SUPPORT=intel \
        -f Dockerfile.gpu .
}

# Run GPU-accelerated Docker
example_docker_gpu_run() {
    local gpu_type="${1:-nvidia}"
    
    case "$gpu_type" in
        "nvidia")
            docker run --gpus all -it \
                -v /io:/io \
                -e DISPLAY=$DISPLAY \
                -v /tmp/.X11-unix:/tmp/.X11-unix \
                airgeddon:gpu-nvidia
            ;;
        "amd")
            docker run --device=/dev/kfd --device=/dev/dri -it \
                -v /io:/io \
                airgeddon:gpu-amd
            ;;
        "intel")
            docker run --device=/dev/dri -it \
                -v /io:/io \
                airgeddon:gpu-intel
            ;;
    esac
}

#=============================================================================
# EXAMPLE 8: Error Handling & Graceful Fallback
#=============================================================================

safe_gpu_crack() {
    local hash_file="$1"
    local wordlist="$2"
    local mode="${3:-22000}"
    
    source plugins/gpu_acceleration.sh || {
        # Plugin load failed, fallback to CPU
        echo "[!] GPU plugin not found, using CPU"
        hashcat -m "$mode" -a 0 "$hash_file" "$wordlist"
        return
    }
    
    # Check GPU availability
    if [ "$hashcat_gpu_enabled" -ne 1 ]; then
        echo "[!] GPU not available or unsupported"
        echo "    Reason: Check drivers (nvidia-smi, rocm-smi, intel-gpu-tools)"
        echo "[*] Falling back to CPU cracking"
    fi
    
    # Prepare command
    local cmd=(hashcat -m "$mode" -a 0)
    
    # Optimize (GPU or CPU)
    if [ "$hashcat_gpu_enabled" -eq 1 ]; then
        gpu_optimize_hashcat_command cmd
    else
        cmd+=("-d" "1")  # CPU fallback
    fi
    
    # Execute with error handling
    if ! "${cmd[@]}" "$hash_file" "$wordlist"; then
        echo "[!] Hashcat failed with exit code $?"
        return 1
    fi
    
    echo "[+] Cracking completed successfully"
    return 0
}

#=============================================================================
# EXECUTION EXAMPLES (Testing)
#=============================================================================

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script was executed directly
    
    echo "GPU Acceleration Integration Examples"
    echo "======================================"
    echo
    echo "Available examples:"
    echo "  source GPU_EXAMPLES.sh"
    echo "  example_gpu_benchmark                    # Run GPU benchmark"
    echo "  example_gpu_wpa2_cracking <hash> <dict>  # Simple cracking"
    echo "  example_multi_gpu_cracking <hash> <dict> # Multi-GPU"
    echo "  build_optimized_hashcat_command 22000 0 <h> <w>  # Build command"
    echo "  example_docker_gpu_build                 # Build Docker images"
    echo
fi
