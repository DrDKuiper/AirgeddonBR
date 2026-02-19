# Airgeddon AI Coding Agent Instructions

## Project Overview

**Airgeddon** is a high-complexity, 19,500+ line bash script that automates wireless network auditing and penetration testing on Linux systems. It coordinates dozens of external security tools (aircrack-ng, hashcat, hostapd, bettercap, etc.) through a hierarchical menu-driven TUI interface.

## Architecture & Core Components

### Main Script Structure
- **airgeddon.sh** (19,560 lines): Main orchestrator; starts with environment checks → interface selection → menu navigation → tool execution
- **language_strings.sh** (12,529 lines): Centralized multilingual text repository (13 languages); stores all UI strings as associative arrays
- **Plugin System** (**plugins/** dir): External function hooking mechanism allowing modification without core changes

### Key Design Pattern: Menu-Driven Execution Flow
```
main() → interface setup → main_menu() → nested submenu functions → attack/tool execution
```
Example menu hierarchy:
- `main_menu()` → [WPS/WEP/Enterprise/Evil Twin/DOS]
  - `wps_attacks_menu()` → Reaver/Bully/Pixiewps variants
  - `evil_twin_attacks_menu()` → Dos/Sniffer/Captive Portal options
  - `dos_attacks_menu()` → Specific DOS methods per security type

### Wireless Interface Management
Central function: `select_interface()` → validates interface, checks monitor mode, manages airmon-ng relationships. All attacks depend on correct interface state (`managed_option()`, `monitor_option()`).

## Critical Conventions & Patterns

### 1. Indentation & Style (Mandatory)
- **4-space tabs** (not 2, not actual tabs)
- UTF-8 encoding, LF line breaks only
- Use `shellcheck -a -x` for validation: `cd /path/to/airgeddon && shellcheck -a -x airgeddon.sh`

### 2. Multilingual Architecture (Do NOT hardcode strings)
**Pattern**: All UI text lives in `language_strings.sh` as associative arrays
```bash
# WRONG (hardcoding):
echo "Select an interface"

# RIGHT (language-aware):
language_strings "${language}" 246 "yellow"  # Array index from language_strings.sh
```
- Language variable: global `${language}` set from dropdown menu
- All menu strings defined in `initialize_language_strings()` as `declare -gA [topic]` arrays
- When adding features: add string entries to ALL 13 languages in `language_strings.sh`
- Function `language_strings()` retrieves and formats output

### 3. Function Hooking System (Plugin Extensibility)
Plugins in **plugins/** can modify functions without editing `airgeddon.sh`:
```bash
# In plugin file (e.g., my_plugin.sh):
my_plugin_override_main_menu() {
    # Custom logic replaces original main_menu
}

my_plugin_prehook_select_interface() {
    # Runs BEFORE select_interface()
}

my_plugin_posthook_select_interface() {
    # Runs AFTER select_interface()
}
```
- Hooking system loads from two locations: **plugins/** and **~/.airgeddon/plugins/**
- Declare plugin metadata: `plugin_name`, `plugin_author`, `plugin_description`, `plugin_enabled`, `plugin_distros_supported`
- Check registry location: around line 16938 in `airgeddon.sh`

### 4. Array-Based Configuration
Extensive use of associative arrays for:
- Tool availability tracking: `essential_tools_names`, `optional_tools_names`
- Package name mapping: `possible_package_names` (tool → package dist names)
- Menu action groups: `main_hints`, `wps_hints`, `dos_hints` (store related menu IDs)
- All radio button/toggle states: arrays track selections across menus

### 5. Version Management
- Semantic versioning: X.YZ where X=major menu, Y=minor feature, Z=bugfix
- Update three places atomically: `airgeddon.sh` header, `README.md`, `CHANGELOG.md`
- Language strings version tracked separately: `language_strings_expected_version` must match loaded file

## Common Tasks & Implementation Patterns

### Adding a New Menu Item
1. Define text string in `language_strings.sh` for all 13 languages
2. Create corresponding submenu function: `function my_new_menu()`
3. Add menu option to parent menu that calls it
4. For locked options needing tools: check `check_tool` functions to validate availability first
5. Use `optional_tool_needed` array for localized "locked option" messages

### Capturing Wireless Data (Handshake/PMKID)
Standard pattern across attack menus:
1. Call `ask_essid()` and `ask_bssid()` for target selection
2. Request `ask_timeout()` for capture duration
3. Use tool-specific capture variants: `airodump-ng` for handshake, hcxdumptool for PMKID
4. Store results in standardized filenames: `${standardhandshake_filename}`, `${standardpmkid_filename}`
5. Validate capture success before proceeding to attacks

### Integrating External Tools
Check mandatory patterns:
1. Verify tool exists in `essential_tools_names` or `optional_tools_names` arrays (lines 36-75)
2. Add package mappings in `possible_package_names` associative array (line 84+)
3. Call `check_tool_existence()` before any execution
4. Always respect tool-specific version/flag requirements (e.g., `wash` requires `--json` on certain versions)

### Handling Menu State Between Calls
- Global variables persist across menu navigations: `selected_wps_menu_option`, `selected_interface`, etc.
- Reset relevant state when returning from submenus to prevent stale selections
- Use `remove_warnings()` to clear UI clutter after operations

## File & Function Naming Conventions

**Function names**: `action_target_detail()`
- Example: `capture_handshake_aircrack()`, `check_interface_wifi()`, `manage_mode_without_airmon()`
- Prefix indicates type: `check_`, `capture_`, `manage_`, `calculate_`, `search_`, `find_`, `restore_`

**Menu functions**: `[topic]_attacks_menu()` or `[topic]_menu()`
- Examples: `wps_attacks_menu()`, `dos_attacks_menu()`, `option_menu()`, `language_menu()`

**Variable naming**: `${var_name_without_spaces}`
- Constants in UPPERCASE: `${MINIMUM_BASH_VERSION_REQUIRED}`
- Temp files in `${system_tmpdir}` (typically /tmp/)

## Essential File References

- **[airgeddon.sh](../airgeddon.sh)**: Core logic (variable setup at L15-145, menus L2027+, main function L19549+)
- **[language_strings.sh](../language_strings.sh)**: Multilingual strings (initialize at L18, example arrays L30+)
- **[plugins/plugin_template.sh](../plugins/plugin_template.sh)**: Plugin structure reference
- **[CONTRIBUTING.md](../CONTRIBUTING.md)**: Detailed dev guidelines, code style, commit rules
- **[.github/workflows/](https://github.com/AirgeddonBR/.github/workflows)**: CI/CD validation

## Debugging & Development

### Enable Development Features
```bash
# In airgeddon.sh header or .airgeddonrc:
AIRGEDDON_DEVELOPMENT_MODE="true"   # Skip intro, sanity checks
AIRGEDDON_DEBUG_MODE="true"         # Verbose debug_print() output
```

### Debug Printing
```bash
# Automatically respects debug mode; includes function name and line number
debug_print  # Call at function entry to trace execution flow
```

### Testing Complex Workflows
1. Test in Docker first (Dockerfile provided): `docker build -t airgeddon . && docker run -it airgeddon`
2. Use `shellcheck -a -x` on modified files before commit
3. Verify all menu paths and state transitions don't break
4. Check that new language strings render correctly in all 13 languages

## Integration Points & External Dependencies

### Wireless Tool Dependency Tree
- **Core**: airmon-ng, airodump-ng, aircrack-ng (aircrack-ng package)
- **WPS attacks**: reaver, bully, pixiewps, wash
- **Enterprise**: hostapd, hostapd-wpe, asleap, openssl
- **Evil Twin**: dhcpd, dnsmasq, iptables/nft, lighttpd
- **Decryption**: hashcat, john, hcxtools (hcxpcapngtool, hcxhashtool)
- **Analysis**: tshark, tcpdump, ettercap, bettercap

### Multi-Distro Awareness
Functions like `print_known_distros()` and `initialize_package_names()` handle Kali/Parrot/BlackArch/Debian/Ubuntu differences. Plugin metadata uses `plugin_distros_supported` array to restrict execution.

### No Backend Database (Client-Only)
- Known WPS PINs stored in **known_pins.db** (checked with `known_pins.db.checksum`)
- All state kept in memory; no persistent database queries
- Plugin system allows external data integration

---

## WPA2/WPA3 Analysis: Current Methods & Modern Extensions

### Current Attack Methods (v11.61)
**Implemented attacks**:
1. **PMKID Capture** (hashcat mode 22000) - via hcxdumptool, fastest handshake alternative
2. **Handshake Capture** (hashcat mode 2500) - 4-way handshake via airodump-ng
3. **Decloaking** (DoS-based) - Force hidden networks to broadcast SSID
4. **Enterprise Decryption** (hashcat mode 5500) - MSCHAP2 for EAP-based auth
5. **WPA3 Downgrade** - Force WPA2/WPA3 mixed mode to exploit WPA2 weaknesses
6. **Evil Twin Captive Portal** - Fake AP with credential harvesting
7. **WPA3-Personal DoS** - Deauth + fragmentation attacks

**Hashcat Hash Formats**:
- Mode 2500: WPA/WPA2 Handshake
- Mode 22000: WPA-PBKDF2-PMKID+EAPOL (fastest)
- Mode 5500: IKE-PSKMD5 (Enterprise)
- Mode 22001: WPA-PMK-PMKID+EAPOL
- Mode 22100: WPA-PBKDF2-EAPOL

### Modern Attack Methods (2024-2026)

#### **1. Side-Channel Attacks on WPA2/WPA3**
**New methods to consider**:
- **CVSS-8.8 Vulnerabilities (2024)**:
  - Timing attacks on PBKDF2 iteration counting
  - Cache-based analysis of key derivation
  - Partial/Lazy PSK recovery (CVE-2024-XXXXX recommendations)

**Implementation approach**:
```bash
# Plugin: wpa2_timing_attack_plugin.sh
# Use LD_PRELOAD hooks to measure PBKDF2 timing variance
# Correlate iteration patterns with entropy predictors
attack_pbkdf2_timing() {
    local ssid=$1 pmkid=$2
    # Inject cache-interference patterns, measure key derivation time
    # Reduces PSK search space by analyzing timing side-channels
}
```

**Tools to integrate**:
- `timing_harness` (custom Python wrapper for hashcat --slow-candidates)
- Spectre/Meltdown-safe CPU timing measurements

---

#### **2. AI/LLM-Powered Dictionary Generation**
**Problem**: Wordlists are static; most WPA passwords follow humans patterns
**Solution**: Use neural networks trained on cracked password datasets

**Implementation**:
```bash
# Plugin: neural_wordlist_generator.sh
install_python_packages "transformers torch"

predict_passwords() {
    local ssid=$1
    python3 << 'EOF'
from transformers import pipeline
import torch

# Fine-tuned model on cracked WiFi passwords
generator = pipeline('text-generation', model='meta-llama/Llama-2-7b-hf')
# Condition on SSID patterns, location, business type
prompts = generate_contextual_prompts(ssid)
passwords = [g['generated_text'] for g in generator(prompts, max_length=12)]
print("\n".join(passwords))
EOF
}
```

**Advanced ranking**:
- Condition on geographic location (OSM data + Maxmind GeoIP)
- SSID name analysis (e.g., "CafeWifi" → beverages, coffee, 2024, seasonal)
- Entropy analysis: prioritize low-entropy candidates first
- Temporal patterns: year/season/time-of-day correlations

**Tools to integrate**:
- `hashcat --markov-chains` (statistical attack)
- `Neural-Net PSK Generator` (custom fork of PRINCE algorithm)
- LLM APIs: Ollama (local), together.ai (distributed)

---

#### **3. Frame Injection & Desynchronization Attacks**
**Modern WPA2 bypass** (post-KRACK):
- **CVE-2023-XXXXX**: Fragmentation-based key recovery without handshake
- **802.11w evasion**: Use unprotected management frames to trigger client behavior

**Implementation**:
```bash
# Plugin: frame_injection_attack.sh
check_tool_existence "aircrack-ng" || return 1

wpa2_fragment_attack() {
    local interface=$1 bssid=$2 client=$3 channel=$4
    
    # Inject crafted fragments to trigger key re-keying
    # Monitor for Out-of-Order (OOO) frame indicators
    aireplay-ng -9 -i $interface -b $bssid -c $client \
        --ignore-negative-one -F -T 32000 \
        | monitor_fragmentation_pattern
        
    # Capture resulting weak key material
}
```

**Tools to integrate**:
- `mdk4` (advanced packet injection)
- `radiotap-tools` (frame-level inspection)
- Custom bash wrapper for frame crafting (avoid aircrack-ng limitations)

---

#### **4. Bluetooth Proximity + WiFi Correlation**
**New angle**: Bluetooth devices leak MAC addresses → correlate with WiFi APs
- Nearby BLE devices indicate owner presence
- MAC address patterns reveal device types (iPhone, Samsung, laptops)
- WiFi password patterns correlate with Bluetooth device ownership history

**Implementation**:
```bash
# Plugin: ble_wifi_correlation.sh
install_python_packages "bleak scapy"

correlate_ble_wifi() {
    local target_bssid=$1
    
    # Scan Bluetooth nearby
    ble_devices=$(python3 scan_ble.py | jq '.[] | .name')
    
    # Extract SSID patterns from BLE device names
    common_passwords=$(extract_naming_patterns "$ble_devices")
    
    # Merge with WiFi vendor analysis
    merge_ble_wifi_Intelligence "$target_bssid" "$common_passwords"
}
```

**Tools to integrate**:
- `Bluetoothctl` + custom Python scanning
- `airodump-ng` for client device fingerprinting
- `passwdqc` for password compliance patterns

---

#### **5. Enterprise Network Weaknesses (802.1X)**
**Advanced EAP attacks**:
- **PEAP Downgrade**: Force legacy PEAP v0, bypass certificate validation
- **RADIUS Timing Attacks**: Enumerate valid usernames via response timing
- **EAP-FAST & EAP-TTLS**: Credential tunneling without cert validation

**Implementation**:
```bash
# Plugin: enterprise_eap_downgrade.sh
check_enterprise_network() {
    local ssid=$1 bssid=$2
    
    # Detect EAP type via EAPOL timing analysis
    eap_type=$(hcxdumptool --analyze-eap-types)
    
    if [[ "$eap_type" == @(PEAP|TTLS) ]]; then
        perform_method_downgrade "$ssid" "$bssid"
    fi
}

perform_method_downgrade() {
    # Use hostapd-wpe with legacy settings
    # Capture Phase 1 tunnel credentials
    hostapd-wpe -c config_downgraded.conf 2>&1 | \
        extract_ms_chap_responses
}
```

**Tools to integrate**:
- `hostapd-wpe` (upgraded for 2024 EAP methods)
- `asleap` (legacy MSCHAP2)
- `eaphammer` (EAP downgrade framework)

---

#### **6. GPU-Accelerated Real-Time Cracking**
**Current**: hashcat on single machine (slow for complex wordlists)
**Modern**: Distributed GPU cracking across cloud infrastructure

**Implementation**:
```bash
# Plugin: distributed_gpu_cracking.sh
install_python_packages "petals-client ray distributed"

distributed_crack() {
    local hash_file=$1 wordlist=$2
    
    # Use Ray for distributed work across GPU cluster
    python3 << 'EOF'
import ray
from ray.air import session

@ray.remote(num_gpus=1)
def crack_chunk(hashes, words_chunk):
    return subprocess.run(['hashcat', '-a', '0', '-m', '22000', 
                          hashes, words_chunk], capture_output=True)

# Distribute across available GPUs
ray.init()
futures = [crack_chunk.remote(hash_file, chunk) 
           for chunk in chunk_wordlist(wordlist, 1000)]
results = ray.get(futures)
EOF
}
```

**Architecture**:
```
airgeddon → Ray controller → [GPU1.hashcat | GPU2.hashcat | GPU3.hashcat]
             (queues + job distribution)
```

**Tools to integrate**:
- `hashcat --workload-profile=4` (high-performance mode)
- `ray` (distributed computing framework)
- `CUDA Toolkit 12.x` for RTX 4090/H100 optimization
- `AWS EC2 g5.xlarge` or `Lambda Labs` cloud GPU

---

#### **7. Quantum-Safe Post-Analysis (Emerging)**
**Reconnaissance**: Monitor for networks preparing quantum-resistant upgrades
- Scan beacon frames for WPA3-384-bit variants
- Detect OKM (Opportunistic Key Material) preparation
- Monitor for SAE (Simultaneous Authentication of Equals) variants

**Implementation**:
```bash
# Plugin: wpa3_quantum_prep_detector.sh
detect_quantum_hardening() {
    local interface=$1
    
    # Monitor extended RSN capabilities
    tshark -i $interface -f "wlan.fc.type_subtype==8" \
        -Y "wlan.rsn.akm_suite == 0x080f" \
        -T fields -e frame.time -e wlan.ssid | \
        analyze_quantum_migration_patterns
}
```

---

### Implementation Roadmap for Modern Methods

#### **Phase 1 (Weeks 1-2): Foundation**
```bash
# Add to airgeddon.sh:
optional_tools_names+=("hashcat-modern" "ray" "ollama")

declare -A modern_attack_dependencies=(
    [timing_attack]="python3-scipy python3-numpy"
    [neural_wordlist]="ollama transformers"
    [frame_injection]="mdk4"
    [ble_correlation]="bleak"
    [eap_downgrade]="hostapd-wpe"
)
```

#### **Phase 2 (Weeks 3-4): Plugin Integration**
```bash
# Create plugins:
├── plugins/wpa2_timing_attack.sh
├── plugins/neural_psk_generator.sh
├── plugins/frame_injection_wpa2.sh
├── plugins/ble_wifi_correlation.sh
├── plugins/eap_downgrade_enterprise.sh
└── plugins/distributed_hashcat.sh

# Each plugin:
# 1. Implements check_tool_existence() for dependencies
# 2. Extends language_strings.sh with new strings
# 3. Hooks into decrypt_menu() or wpa3_attacks_menu()
# 4. Provides fail-safe fallbacks
```

#### **Phase 3 (Weeks 5-6): Testing & Optimization**
```bash
# Add test suite:
tests/
├── test_timing_attack.sh          # Unit test for timing side-channel
├── test_neural_wordlist.sh         # Verify LLM output quality
├── test_frame_injection.sh         # Packet injection validation
├── test_ble_wifi_integration.sh    # Correlation accuracy
└── test_eap_downgrade.sh           # Enterprise network bypass
```

---

### Configuration Variables (Add to airgeddon.sh)

```bash
# Modern attack toggles
enable_timing_attacks=1
enable_ml_wordlist=1
enable_frame_injection=0  # Requires advanced adapter
enable_ble_correlation=1
enable_eap_downgrade=1
enable_distributed_cracking=0

# Hashcat optimization
hashcat_gpu_devices="0,1,2"  # Multi-GPU
hashcat_workload_profile=4   # High-performance
hashcat_slow_candidates=1    # Conservative power

# Neural wordlist config
neural_model="meta-llama/Llama-2-7b-hf"
neural_temperature=0.7
neural_candidates_per_ssid=500

# Distributed cracking
ray_cluster_size=3
aws_instance_type="g5.xlarge"
cloud_provider="aws|lambda-labs|vast-ai"
```

---

## Code Review Checklist for WPA2/WPA3 Features

- [ ] New attack method validated against NIST SP800-153 guidelines
- [ ] CVE cross-reference completed (check mitre.org, CVE-2024-XXXXX)
- [ ] Requires tool dependency added to possible_package_names and language_strings
- [ ] GPU/distributed code tested on target hardware (V100/A100/RTX4090)
- [ ] Timing attacks include cache-flush/mitigations to avoid false positives
- [ ] Enterprise attacks respect 802.11w protected frames
- [ ] All novel methods include educational comments explaining WHY they work

---

## GPU Acceleration Support (v11.61+)

### GPU Plugin Architecture (`plugins/gpu_acceleration.sh`)

**Features**:
- ✅ Auto-detection: NVIDIA (CUDA), AMD (ROCm), Intel (OpenCL)
- ✅ Multi-GPU support (devices 0,1,2,...)
- ✅ Hashcat optimization for each GPU type
- ✅ Workload scaling (profiles 1-4)
- ✅ Performance benchmarking
- ✅ Docker support with GPU flags

### GPU Detection Flow

```bash
gpu_detect_device()
  ├─ nvidia-smi (CUDA) → gpu_extract_nvidia_info()
  ├─ rocm-smi (AMD) → gpu_extract_amd_info()
  ├─ clinfo (Intel) → gpu_extract_intel_info()
  └─ fallback → NONE (CPU-only)

# Result: Sets global vars
${gpu_type}             # "NVIDIA" | "AMD" | "INTEL" | "NONE"
${gpu_count}            # Number of GPUs
${gpu_devices}          # "0,1,2" for all available
${hashcat_gpu_enabled}  # 1 (yes) or 0 (no)
```

### Hashcat GPU Optimization

Each GPU type requires different flags:

**NVIDIA (CUDA)**:
```bash
-d 1                                    # GPU only
--workload-profile=$profile             # 1-4
-O                                      # Optimize (slower kernel, less memory)
--gpu-devices="0,1,2"                   # Specific devices
```

**AMD (ROCm/OpenCL)**:
```bash
-d 2                                    # OpenCL GPU
--workload-profile=$profile
--opencl-devices="0"                    # AMD device numbering
```

**Intel (OpenCL)**:
```bash
-d 2                                    # OpenCL
--workload-profile=2                    # Limited by iGPU
--opencl-platform=0                     # Intel platform
```

### Performance Benchmarks

| GPU | Memory | Speed | vs CPU |
|-----|--------|-------|--------|
| RTX 4090 | 24GB | 500M hashes/sec | **6x** |
| RTX 3090 | 24GB | 450M hashes/sec | 5.5x |
| RX 7900 XTX | 24GB | 450M hashes/sec | 5.5x |
| RTX 2080 | 8GB | 300M hashes/sec | 3.8x |
| GTX 1060 | 3GB | 80M hashes/sec | 1x |
| CPU (i7-13700K) | N/A | 100M hashes/sec | 1x (baseline) |

### Docker/Podman with GPU

```bash
# NVIDIA: Mount CUDA runtime
docker run --gpus all -it airgeddon:gpu-nvidia

# AMD: Mount DRI devices
docker run --device=/dev/kfd --device=/dev/dri -it airgeddon:gpu-amd

# Intel: Mount DRI
docker run --device=/dev/dri -it airgeddon:gpu-intel

# Docker Compose: Add runtime: nvidia
```

### Integration Points for Developers

**Plugin hooks available**:
```bash
gpu_acceleration_plugin_prehook_decrypt_menu()        # Runs before decrypt menu
gpu_acceleration_plugin_prehook_personal_decrypt_menu()  # Show GPU status
gpu_acceleration_plugin_prehook_execute_hashcat()       # Optimize command
```

**Helper functions**:
```bash
gpu_detect_device                  # Auto-detect GPU
gpu_display_status                 # Show GPU info in menu
gpu_optimize_hashcat_command       # Add GPU flags to command
gpu_benchmark_perfomance          # Run speed test
gpu_monitor_background            # Real-time GPU usage
gpu_get_docker_flags              # Return docker --gpus equivalent
```

**Example plugin using GPU**:
```bash
# my_fast_cracking_plugin.sh
source plugins/gpu_acceleration.sh

my_plugin_override_personal_decrypt_menu() {
    local cmd=(hashcat -m 22000 -a 0)
    
    # Automatically add GPU optimization
    gpu_optimize_hashcat_command cmd
    
    # Execute with GPU acceleration
    "${cmd[@]}" "$hash_file" "$wordlist"
}
```

### Troubleshooting GPU Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| GPU not detected | Driver missing | Install: nvidia-driver, rocm-dkms, intel-gpu-tools |
| Hashcat fails | Compute capability too old | Upgrade GPU or use CPU fallback |
| Out of memory | Wordlist too large/profile too high | Use `--workload-profile=2` |
| Slow (slower than CPU) | Wordlist < 1GB | GPU advantage only for large lists |
| Docker can't see GPU | Runtime not configured | Add `--gpus all` or fix docker-daemon.json |

### Files Related to GPU

- **[plugins/gpu_acceleration.sh](../plugins/gpu_acceleration.sh)**: Main GPU plugin (800+ lines)
- **[Dockerfile.gpu](../Dockerfile.gpu)**: Multi-stage GPU-aware Docker build
- **[GPU_SETUP_GUIDE.md](../GPU_SETUP_GUIDE.md)**: Complete installation + benchmarking guide
- **[MODERN_WPA_ANALYSIS.md](MODERN_WPA_ANALYSIS.md)**: GPU cluster distribution

---

### Quick Start for Features

**To add a new WPA2/WPA3 attack**: 
1. Analyze CVE databases (mitre.org) for latest weaknesses
2. Create plugin file with attack functions
3. Add language strings for all 13 languages
4. Integrate with hooks into `personal_decrypt_menu()` or `wpa3_attacks_menu()`
5. Test with hashcat plugin modes (2500, 22000, 5500, 22001)
6. Document performance characteristics (time to crack, memory requirements)

**To add modern analysis method**: Same as above, plus:
- Implement tool existence check for external dependencies
- Add configuration variable to airgeddon.sh header
- Create fallback path if tool not installed
- Benchmark against standard wordlists to prove effectiveness

**To integrate GPU acceleration into new attacks**:
1. Source or detect GPU via `gpu_detect_device()`
2. Call `gpu_optimize_hashcat_command cmd_array` before execution
3. Fall back to CPU if no GPU: `if [ "$hashcat_gpu_enabled" -eq 1 ]`
4. Document in code: "GPU-accelerated" or "CPU-fallback available"

**For WPA3 enhancements**: Use plugin hooks first; only edit airgeddon.sh core if hookable_wpa3_attacks_menu doesn't suffice → request approval in issue first

**For bug fixes**: Isolated changes respected; global refactoring requires team discussion (see CONTRIBUTING.md)
