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

# Check if sonar-scanner is available
if ! command -v sonar-scanner &> /dev/null; then
    echo -e "${RED}ERROR: sonar-scanner is not installed${NC}"
    exit 1
fi

# Run SonarQube scanner
echo -e "\n${GREEN}Running SonarQube scanner...${NC}"
sonar-scanner \
    -Dsonar.host.url="$SONAR_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    -Dsonar.projectKey="$SONAR_KEY" \
    -Dsonar.projectName="$SONAR_NAME" \
    -Dsonar.projectVersion="$SONAR_VERSION"

echo -e "\n${GREEN}=== SonarQube Analysis Complete ===${NC}"
echo -e "View results at: ${SONAR_URL}/dashboard?id=${SONAR_KEY}"
