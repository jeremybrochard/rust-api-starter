#!/bin/bash
# DependencyTrack SBOM upload script
# Usage: ./scripts/dtrack-upload.sh
#
# Required environment variables:
#   DTRACK_URL         - DependencyTrack API URL (e.g., https://dtrack.example.com)
#   DTRACK_API_KEY     - DependencyTrack API key
#   DTRACK_PROJECT_UUID - UUID of the project in DependencyTrack
#
# Optional:
#   SBOM_FILE - Path to SBOM file (default: sbom.json)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DependencyTrack Upload ===${NC}"

# Validate required environment variables
if [ -z "$DTRACK_URL" ]; then
    echo -e "${RED}ERROR: DTRACK_URL is not set${NC}"
    exit 1
fi

if [ -z "$DTRACK_API_KEY" ]; then
    echo -e "${RED}ERROR: DTRACK_API_KEY is not set${NC}"
    exit 1
fi

if [ -z "$DTRACK_PROJECT_UUID" ]; then
    echo -e "${RED}ERROR: DTRACK_PROJECT_UUID is not set${NC}"
    exit 1
fi

SBOM_FILE="${SBOM_FILE:-sbom.json}"

# Check if SBOM file exists
if [ ! -f "$SBOM_FILE" ]; then
    echo -e "${RED}ERROR: SBOM file not found: ${SBOM_FILE}${NC}"
    echo "Run ./scripts/sbom-generate.sh first"
    exit 1
fi

echo -e "${YELLOW}Server: ${DTRACK_URL}${NC}"
echo -e "${YELLOW}Project UUID: ${DTRACK_PROJECT_UUID}${NC}"
echo -e "${YELLOW}SBOM file: ${SBOM_FILE}${NC}"

# Base64 encode the SBOM
echo -e "\n${GREEN}[1/2] Encoding SBOM...${NC}"
SBOM_BASE64=$(base64 -w 0 "$SBOM_FILE" 2>/dev/null || base64 -i "$SBOM_FILE")

# Upload to DependencyTrack
echo -e "\n${GREEN}[2/2] Uploading to DependencyTrack...${NC}"

RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
    "${DTRACK_URL}/api/v1/bom" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: ${DTRACK_API_KEY}" \
    -d "{
        \"project\": \"${DTRACK_PROJECT_UUID}\",
        \"bom\": \"${SBOM_BASE64}\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "\n${GREEN}=== Upload Successful ===${NC}"
    echo -e "View results at: ${DTRACK_URL}/projects/${DTRACK_PROJECT_UUID}"
    
    # Extract token if present
    TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")
    if [ -n "$TOKEN" ]; then
        echo -e "Processing token: ${TOKEN}"
    fi
else
    echo -e "${RED}ERROR: Upload failed with HTTP ${HTTP_CODE}${NC}"
    echo -e "Response: ${BODY}"
    exit 1
fi
