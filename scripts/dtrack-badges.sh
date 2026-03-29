#!/bin/bash
# DependencyTrack Badge Update Script for GitLab
# Usage: ./scripts/dtrack-badges.sh
#
# Required environment variables:
#   DTRACK_URL            - DependencyTrack API URL (e.g., https://dtrack.example.com)
#   DTRACK_BADGE_API_KEY  - DependencyTrack Badge API key
#   DTRACK_PROJECT_NAME   - Name of the project in DependencyTrack
#   GITLAB_URL            - GitLab instance URL (e.g., https://gitlab.example.com)
#   GITLAB_PROJECT_ID     - GitLab project ID
#   GITLAB_TOKEN          - GitLab API token with api scope
#
# Optional:
#   DTRACK_PROJECT_VERSION - Project version (default: latest)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DependencyTrack Badge Update for GitLab ===${NC}"

# Validate required environment variables
if [ -z "$DTRACK_URL" ]; then
    echo -e "${RED}ERROR: DTRACK_URL is not set${NC}"
    exit 1
fi

if [ -z "$DTRACK_BADGE_API_KEY" ]; then
    echo -e "${RED}ERROR: DTRACK_BADGE_API_KEY is not set${NC}"
    exit 1
fi

if [ -z "$DTRACK_PROJECT_NAME" ]; then
    echo -e "${RED}ERROR: DTRACK_PROJECT_NAME is not set${NC}"
    exit 1
fi

if [ -z "$GITLAB_URL" ]; then
    echo -e "${RED}ERROR: GITLAB_URL is not set${NC}"
    exit 1
fi

if [ -z "$GITLAB_PROJECT_ID" ]; then
    echo -e "${RED}ERROR: GITLAB_PROJECT_ID is not set${NC}"
    exit 1
fi

if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "${RED}ERROR: GITLAB_TOKEN is not set${NC}"
    exit 1
fi

DTRACK_PROJECT_VERSION="${DTRACK_PROJECT_VERSION:-latest}"

echo -e "${YELLOW}DependencyTrack: ${DTRACK_URL}${NC}"
echo -e "${YELLOW}Project: ${DTRACK_PROJECT_NAME} (${DTRACK_PROJECT_VERSION})${NC}"
echo -e "${YELLOW}GitLab: ${GITLAB_URL}${NC}"
echo -e "${YELLOW}GitLab Project ID: ${GITLAB_PROJECT_ID}${NC}"

# URL encode project name and version
PROJECT_NAME_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${DTRACK_PROJECT_NAME}', safe=''))")
PROJECT_VERSION_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${DTRACK_PROJECT_VERSION}', safe=''))")

# DependencyTrack badge URLs
VULNERABILITIES_BADGE_URL="${DTRACK_URL}/api/v1/badge/vulns/project/${PROJECT_NAME_ENCODED}/${PROJECT_VERSION_ENCODED}"
POLICY_BADGE_URL="${DTRACK_URL}/api/v1/badge/violations/project/${PROJECT_NAME_ENCODED}/${PROJECT_VERSION_ENCODED}"

# Function to create or update GitLab badge
update_gitlab_badge() {
    local badge_name="$1"
    local badge_link="$2"
    local badge_image="$3"
    
    echo -e "\n${GREEN}Updating badge: ${badge_name}${NC}"
    
    # Check if badge exists
    EXISTING_BADGES=$(curl -s \
        -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/badges")
    
    BADGE_ID=$(echo "$EXISTING_BADGES" | python3 -c "
import sys, json
badges = json.load(sys.stdin)
for b in badges:
    if b.get('name') == '${badge_name}':
        print(b['id'])
        break
" 2>/dev/null || echo "")
    
    if [ -n "$BADGE_ID" ]; then
        # Update existing badge
        echo -e "${YELLOW}Updating existing badge (ID: ${BADGE_ID})${NC}"
        RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
            -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            -H "Content-Type: application/json" \
            "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/badges/${BADGE_ID}" \
            -d "{
                \"link_url\": \"${badge_link}\",
                \"image_url\": \"${badge_image}\"
            }")
    else
        # Create new badge
        echo -e "${YELLOW}Creating new badge${NC}"
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
            -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
            -H "Content-Type: application/json" \
            "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/badges" \
            -d "{
                \"name\": \"${badge_name}\",
                \"link_url\": \"${badge_link}\",
                \"image_url\": \"${badge_image}\"
            }")
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        echo -e "${GREEN}Badge '${badge_name}' updated successfully${NC}"
    else
        echo -e "${RED}ERROR: Failed to update badge '${badge_name}' (HTTP ${HTTP_CODE})${NC}"
        echo -e "Response: ${BODY}"
        return 1
    fi
}

# DependencyTrack project link
DTRACK_PROJECT_LINK="${DTRACK_URL}/projects/?name=${PROJECT_NAME_ENCODED}&version=${PROJECT_VERSION_ENCODED}"

# Update badges
echo -e "\n${GREEN}[1/2] Updating Vulnerabilities badge...${NC}"
update_gitlab_badge \
    "DependencyTrack Vulnerabilities" \
    "${DTRACK_PROJECT_LINK}" \
    "${VULNERABILITIES_BADGE_URL}"

echo -e "\n${GREEN}[2/2] Updating Policy Violations badge...${NC}"
update_gitlab_badge \
    "DependencyTrack Policy" \
    "${DTRACK_PROJECT_LINK}" \
    "${POLICY_BADGE_URL}"

echo -e "\n${GREEN}=== Badge Update Complete ===${NC}"
echo -e "View badges at: ${GITLAB_URL}/projects/${GITLAB_PROJECT_ID}/-/badges"
