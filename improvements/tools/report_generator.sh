#!/usr/bin/env bash

################################################################################
# Airgeddon Report Generator
# Generates comprehensive security reports in JSON and HTML formats
# Version: 1.0
# Usage: source report_generator.sh
################################################################################

source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"

# Report metadata
REPORT_VERSION="1.0"
REPORT_TOOL="Airgeddon Report Generator"

###############################################################################
# Initialize report structure
# Arguments: $1 - Report title
###############################################################################
initialize_report() {
    local title="${1:-Airgeddon Security Report}"
    
    declare -gA REPORT=(
        [title]="${title}"
        [timestamp]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        [hostname]="$(hostname)"
        [user]="$(whoami)"
        [version]="${REPORT_VERSION}"
    )
    
    declare -ga NETWORKS_FOUND=()
    declare -ga VULNERABILITIES_FOUND=()
    declare -ga RECOMMENDATIONS=()
    
    log_info "Report initialized: ${title}"
}

###############################################################################
# Add network information to report
# Arguments:
#   $1 - BSSID
#   $2 - ESSID
#   $3 - Encryption
#   $4 - Signal Strength
#   $5 - Channel
###############################################################################
add_network_to_report() {
    local bssid="$1"
    local essid="$2"
    local encryption="$3"
    local signal_strength="$4"
    local channel="$5"
    
    local network_entry=$(cat <<EOF
{
    "bssid": "${bssid}",
    "essid": "${essid}",
    "encryption": "${encryption}",
    "signal_strength": ${signal_strength},
    "channel": ${channel},
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    )
    
    NETWORKS_FOUND+=("${network_entry}")
    log_debug "Network added: ${essid} (${bssid})"
}

###############################################################################
# Add vulnerability finding to report
# Arguments:
#   $1 - Network BSSID
#   $2 - Vulnerability type
#   $3 - Severity (LOW|MEDIUM|HIGH|CRITICAL)
#   $4 - Description
#   $5 - Recommendation
###############################################################################
add_vulnerability() {
    local bssid="$1"
    local vuln_type="$2"
    local severity="$3"
    local description="$4"
    local recommendation="$5"
    
    local vuln_entry=$(cat <<EOF
{
    "bssid": "${bssid}",
    "type": "${vuln_type}",
    "severity": "${severity}",
    "description": "${description}",
    "recommendation": "${recommendation}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    )
    
    VULNERABILITIES_FOUND+=("${vuln_entry}")
    RECOMMENDATIONS+=("${recommendation}")
    log_warn "Vulnerability found: ${vuln_type} (${severity}) on ${bssid}"
}

###############################################################################
# Generate JSON report
# Arguments: $1 - Output file path
###############################################################################
generate_json_report() {
    local output_file="$1"
    
    if [[ -z "${output_file}" ]]; then
        log_error "Output file path required for JSON report"
        return 1
    fi
    
    log_info "Generating JSON report: ${output_file}"
    
    # Build JSON structure
    local json_content='{'
    
    # Add metadata
    json_content+=$'\\n  "metadata": {'
    json_content+=$'\\n    "title": "'${REPORT[title]}'",'
    json_content+=$'\\n    "timestamp": "'${REPORT[timestamp]}'",'
    json_content+=$'\\n    "hostname": "'${REPORT[hostname]}'",'
    json_content+=$'\\n    "user": "'${REPORT[user]}'",'
    json_content+=$'\\n    "tool": "'${REPORT_TOOL}'",'
    json_content+=$'\\n    "version": "'${REPORT[version]}'"'
    json_content+=$'\\n  },'
    
    # Add networks
    json_content+=$'\\n  "networks": ['
    local first=true
    for network in "${NETWORKS_FOUND[@]}"; do
        if [[ "${first}" == "true" ]]; then
            json_content+=$'\\n    '"${network}"
            first=false
        else
            json_content+=$',\\n    '"${network}"
        fi
    done
    json_content+=$'\\n  ],'
    
    # Add vulnerabilities
    json_content+=$'\\n  "vulnerabilities": ['
    first=true
    for vuln in "${VULNERABILITIES_FOUND[@]}"; do
        if [[ "${first}" == "true" ]]; then
            json_content+=$'\\n    '"${vuln}"
            first=false
        else
            json_content+=$',\\n    '"${vuln}"
        fi
    done
    json_content+=$'\\n  ],'
    
    # Add statistics
    local total_networks=${#NETWORKS_FOUND[@]}
    local total_vulns=${#VULNERABILITIES_FOUND[@]}
    json_content+=$'\\n  "statistics": {'
    json_content+=$'\\n    "total_networks": '${total_networks}','
    json_content+=$'\\n    "total_vulnerabilities": '${total_vulns}','
    json_content+=$'\\n    "report_generated_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"'
    json_content+=$'\\n  }'
    
    json_content+=$'\\n}'
    
    # Write to file
    echo -e "${json_content}" > "${output_file}"
    
    log_info "✓ JSON report generated successfully: ${output_file}"
    return 0
}

###############################################################################
# Generate HTML report
# Arguments: $1 - Output file path
###############################################################################
generate_html_report() {
    local output_file="$1"
    
    if [[ -z "${output_file}" ]]; then
        log_error "Output file path required for HTML report"
        return 1
    fi
    
    log_info "Generating HTML report: ${output_file}"
    
    # Count statistics
    local total_networks=${#NETWORKS_FOUND[@]}
    local total_vulns=${#VULNERABILITIES_FOUND[@]}
    local critical=0 high=0 medium=0 low=0
    
    # Count vulnerabilities by severity
    for vuln in "${VULNERABILITIES_FOUND[@]}"; do
        [[ "${vuln}" =~ \"severity\":[[:space:]]*\"CRITICAL\" ]] && ((critical++))
        [[ "${vuln}" =~ \"severity\":[[:space:]]*\"HIGH\" ]] && ((high++))
        [[ "${vuln}" =~ \"severity\":[[:space:]]*\"MEDIUM\" ]] && ((medium++))
        [[ "${vuln}" =~ \"severity\":[[:space:]]*\"LOW\" ]] && ((low++))
    done
    
    # Create HTML document
    cat > "${output_file}" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Airgeddon Security Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        header p {
            opacity: 0.9;
        }
        
        .metadata {
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 1px solid #dee2e6;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .metadata-item {
            padding: 10px;
        }
        
        .metadata-item label {
            font-weight: 600;
            color: #667eea;
            display: block;
            margin-bottom: 5px;
        }
        
        .metadata-item value {
            color: #333;
        }
        
        .statistics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
        }
        
        .stat-card {
            background: white;
            border-left: 4px solid #667eea;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .stat-card.critical {
            border-left-color: #dc3545;
            background: #fff5f5;
        }
        
        .stat-card.high {
            border-left-color: #fd7e14;
            background: #fff8f5;
        }
        
        .stat-card.medium {
            border-left-color: #ffc107;
            background: #fffdf5;
        }
        
        .stat-card.low {
            border-left-color: #28a745;
            background: #f5fff5;
        }
        
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        
        section {
            padding: 30px;
            border-top: 2px solid #f8f9fa;
        }
        
        section h2 {
            color: #667eea;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #dee2e6;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .severity-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 0.85em;
            font-weight: 600;
        }
        
        .severity-critical {
            background: #dc3545;
            color: white;
        }
        
        .severity-high {
            background: #fd7e14;
            color: white;
        }
        
        .severity-medium {
            background: #ffc107;
            color: #333;
        }
        
        .severity-low {
            background: #28a745;
            color: white;
        }
        
        .vulnerability-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
            border-left: 4px solid #dc3545;
        }
        
        .vulnerability-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .vulnerability-type {
            font-weight: 600;
            color: #333;
        }
        
        .vulnerability-description {
            color: #666;
            margin: 10px 0;
            line-height: 1.6;
        }
        
        .recommendation-box {
            background: #e7f3ff;
            border-left: 3px solid #2196F3;
            padding: 12px;
            margin-top: 10px;
            border-radius: 3px;
        }
        
        .recommendation-box strong {
            color: #2196F3;
        }
        
        footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
            border-top: 1px solid #dee2e6;
        }
        
        .no-data {
            text-align: center;
            color: #999;
            padding: 30px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔒 Airgeddon Security Report</h1>
            <p>Comprehensive WiFi Security Analysis</p>
        </header>
        
        <div class="metadata">
            <div class="metadata-item">
                <label>Report Title</label>
                <value id="report-title"></value>
            </div>
            <div class="metadata-item">
                <label>Generated At</label>
                <value id="report-timestamp"></value>
            </div>
            <div class="metadata-item">
                <label>Hostname</label>
                <value id="report-hostname"></value>
            </div>
            <div class="metadata-item">
                <label>User</label>
                <value id="report-user"></value>
            </div>
            <div class="metadata-item">
                <label>Tool Version</label>
                <value id="report-version"></value>
            </div>
        </div>
        
        <section>
            <h2>📊 Statistics</h2>
            <div class="statistics">
                <div class="stat-card">
                    <div class="stat-number" id="total-networks">0</div>
                    <div class="stat-label">Networks Found</div>
                </div>
                <div class="stat-card critical">
                    <div class="stat-number" id="critical-count">0</div>
                    <div class="stat-label">Critical Vulnerabilities</div>
                </div>
                <div class="stat-card high">
                    <div class="stat-number" id="high-count">0</div>
                    <div class="stat-label">High Severity</div>
                </div>
                <div class="stat-card medium">
                    <div class="stat-number" id="medium-count">0</div>
                    <div class="stat-label">Medium Severity</div>
                </div>
                <div class="stat-card low">
                    <div class="stat-number" id="low-count">0</div>
                    <div class="stat-label">Low Severity</div>
                </div>
            </div>
        </section>
        
        <section id="networks-section" style="display: none;">
            <h2>📡 Networks Found</h2>
            <table>
                <thead>
                    <tr>
                        <th>ESSID</th>
                        <th>BSSID</th>
                        <th>Encryption</th>
                        <th>Signal Strength</th>
                        <th>Channel</th>
                    </tr>
                </thead>
                <tbody id="networks-table"></tbody>
            </table>
        </section>
        
        <section id="vulnerabilities-section" style="display: none;">
            <h2>⚠️  Vulnerabilities Found</h2>
            <div id="vulnerabilities-list"></div>
        </section>
        
        <section>
            <h2>💡 Recommendations</h2>
            <div id="recommendations-list" class="no-data">No vulnerabilities found - Your WiFi networks appear secure!</div>
        </section>
        
        <footer>
            <p>Generated by Airgeddon Report Generator v1.0 | © 2025 Airgeddon Project</p>
            <p>This report contains sensitive security information. Handle with care.</p>
        </footer>
    </div>
    
    <script>
        // Placeholder for report data to be populated by bash
        const reportData = {
            metadata: {},
            networks: [],
            vulnerabilities: [],
            statistics: { total_networks: 0, total_vulnerabilities: 0 }
        };
        
        // Populate metadata
        if (reportData.metadata.title) {
            document.getElementById('report-title').textContent = reportData.metadata.title;
            document.getElementById('report-timestamp').textContent = reportData.metadata.timestamp;
            document.getElementById('report-hostname').textContent = reportData.metadata.hostname;
            document.getElementById('report-user').textContent = reportData.metadata.user;
            document.getElementById('report-version').textContent = reportData.metadata.version;
        }
    </script>
</body>
</html>
HTMLEOF
    
    log_info "✓ HTML report template generated: ${output_file}"
    return 0
}

###############################################################################
# Generate CSV report
# Arguments: $1 - Output file path
###############################################################################
generate_csv_report() {
    local output_file="$1"
    
    if [[ -z "${output_file}" ]]; then
        log_error "Output file path required for CSV report"
        return 1
    fi
    
    log_info "Generating CSV report: ${output_file}"
    
    # CSV Header
    {
        echo "BSSID,ESSID,Encryption,Signal_Strength,Channel,Timestamp"
        
        # Add network entries
        for network in "${NETWORKS_FOUND[@]}"; do
            # Extract values from JSON
            local bssid=$(echo "${network}" | grep -o '"bssid": "[^"]*"' | cut -d'"' -f4)
            local essid=$(echo "${network}" | grep -o '"essid": "[^"]*"' | cut -d'"' -f4)
            local encryption=$(echo "${network}" | grep -o '"encryption": "[^"]*"' | cut -d'"' -f4)
            local signal=$(echo "${network}" | grep -o '"signal_strength": [^,}]*' | cut -d':' -f2 | tr -d ' ')
            local channel=$(echo "${network}" | grep -o '"channel": [^,}]*' | cut -d':' -f2 | tr -d ' ')
            local timestamp=$(echo "${network}" | grep -o '"timestamp": "[^"]*"' | cut -d'"' -f4)
            
            echo "\"${bssid}\",\"${essid}\",\"${encryption}\",${signal},${channel},\"${timestamp}\""
        done
    } > "${output_file}"
    
    log_info "✓ CSV report generated successfully: ${output_file}"
    return 0
}

###############################################################################
# Display report summary
###############################################################################
display_report_summary() {
    local total_networks=${#NETWORKS_FOUND[@]}
    local total_vulns=${#VULNERABILITIES_FOUND[@]}
    
    cat <<EOF
╔═══════════════════════════════════════════╗
║      AIRGEDDON REPORT SUMMARY             ║
╠═══════════════════════════════════════════╣
║ Title:           ${REPORT[title]:0:30}
║ Generated:       ${REPORT[timestamp]:0:30}
║ Networks Found:  ${total_networks:0:30}
║ Vulnerabilities: ${total_vulns:0:30}
╚═══════════════════════════════════════════╝
EOF
}

return 0 2>/dev/null || true
