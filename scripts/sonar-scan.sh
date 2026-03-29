#!/bin/bash
# SonarQube analysis script for Rust projects
# Usage: ./scripts/sonar-scan.sh
#
# Required environment variables:
#   SONAR_URL     - SonarQube server URL (e.g., https://sonar.example.com)
#   SONAR_NAME    - Project name
#   SONAR_KEY     - Project key
#   SONAR_VERSION - Project version
#   SONAR_TOKEN   - SonarQube authentication token

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== SonarQube Analysis ===${NC}"

# Validate required environment variables
if [ -z "$SONAR_URL" ]; then
    echo -e "${RED}ERROR: SONAR_URL is not set${NC}"
    exit 1
fi

if [ -z "$SONAR_TOKEN" ]; then
    echo -e "${RED}ERROR: SONAR_TOKEN is not set${NC}"
    exit 1
fi

if [ -z "$SONAR_KEY" ]; then
    echo -e "${RED}ERROR: SONAR_KEY is not set${NC}"
    exit 1
fi

echo -e "${YELLOW}Project: ${SONAR_NAME} (${SONAR_KEY})${NC}"
echo -e "${YELLOW}Version: ${SONAR_VERSION}${NC}"
echo -e "${YELLOW}Server: ${SONAR_URL}${NC}"

# Step 1: Run Clippy and generate JSON report
echo -e "\n${GREEN}[1/3] Running Clippy analysis...${NC}"
cargo clippy --message-format=json 2>&1 | tee clippy-output.json || true

# Step 2: Convert Clippy output to SonarQube format
echo -e "\n${GREEN}[2/3] Converting Clippy report to SonarQube format...${NC}"

# Create SonarQube external issues report
python3 - << 'EOF'
import json
import sys

sonar_issues = {"issues": []}

try:
    with open("clippy-output.json", "r") as f:
        for line in f:
            try:
                msg = json.loads(line)
                if msg.get("reason") == "compiler-message":
                    message = msg.get("message", {})
                    level = message.get("level", "")
                    
                    if level in ["warning", "error"]:
                        spans = message.get("spans", [])
                        if spans:
                            primary_span = spans[0]
                            file_name = primary_span.get("file_name", "")
                            
                            # Skip external files
                            if file_name.startswith("/") or "/.cargo/" in file_name:
                                continue
                            
                            issue = {
                                "engineId": "clippy",
                                "ruleId": message.get("code", {}).get("code", "unknown") if message.get("code") else "unknown",
                                "severity": "MAJOR" if level == "error" else "MINOR",
                                "type": "CODE_SMELL",
                                "primaryLocation": {
                                    "message": message.get("message", "No message"),
                                    "filePath": file_name,
                                    "textRange": {
                                        "startLine": primary_span.get("line_start", 1),
                                        "endLine": primary_span.get("line_end", 1),
                                        "startColumn": primary_span.get("column_start", 0) - 1,
                                        "endColumn": primary_span.get("column_end", 0) - 1
                                    }
                                }
                            }
                            sonar_issues["issues"].append(issue)
            except json.JSONDecodeError:
                continue

    with open("clippy-report.json", "w") as f:
        json.dump(sonar_issues, f, indent=2)
    
    print(f"Generated report with {len(sonar_issues['issues'])} issues")

except Exception as e:
    print(f"Error processing clippy output: {e}", file=sys.stderr)
    # Create empty report on error
    with open("clippy-report.json", "w") as f:
        json.dump({"issues": []}, f)
EOF

# Step 3: Run SonarQube scanner
echo -e "\n${GREEN}[3/3] Running SonarQube scanner...${NC}"

# Check if sonar-scanner is available
if command -v sonar-scanner &> /dev/null; then
    sonar-scanner \
        -Dsonar.host.url="$SONAR_URL" \
        -Dsonar.token="$SONAR_TOKEN" \
        -Dsonar.projectKey="$SONAR_KEY" \
        -Dsonar.projectName="$SONAR_NAME" \
        -Dsonar.projectVersion="$SONAR_VERSION"
else
    echo -e "${YELLOW}sonar-scanner not found, using curl to upload report...${NC}"
    
    # Alternative: Use SonarQube Web API directly
    curl -s -u "$SONAR_TOKEN:" \
        -F "report=@clippy-report.json" \
        "$SONAR_URL/api/issues/import_external_issues?projectKey=$SONAR_KEY" || {
        echo -e "${RED}Failed to upload report. Please install sonar-scanner.${NC}"
        echo "Download from: https://docs.sonarqube.org/latest/analyzing-source-code/scanners/sonarscanner/"
        exit 1
    }
fi

# Cleanup
rm -f clippy-output.json

echo -e "\n${GREEN}=== SonarQube Analysis Complete ===${NC}"
echo -e "View results at: ${SONAR_URL}/dashboard?id=${SONAR_KEY}"
