#!/bin/bash
# SBOM (Software Bill of Materials) generation script
# Generates a CycloneDX SBOM from Cargo.lock
# Usage: ./scripts/sbom-generate.sh
#
# Output: sbom.json (CycloneDX format)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== SBOM Generation ===${NC}"

# Check if cargo-cyclonedx is installed
if ! command -v cargo-cyclonedx &> /dev/null; then
    echo -e "${YELLOW}cargo-cyclonedx not found, installing...${NC}"
    cargo install cargo-cyclonedx
fi

# Generate SBOM
echo -e "\n${GREEN}Generating CycloneDX SBOM...${NC}"
cargo cyclonedx --format json --output-path sbom.json

# Validate output
if [ -f "sbom.json" ]; then
    COMPONENT_COUNT=$(python3 -c "import json; data=json.load(open('sbom.json')); print(len(data.get('components', [])))" 2>/dev/null || echo "unknown")
    echo -e "\n${GREEN}=== SBOM Generation Complete ===${NC}"
    echo -e "Output: sbom.json"
    echo -e "Components: ${COMPONENT_COUNT}"
else
    echo -e "${RED}ERROR: Failed to generate SBOM${NC}"
    exit 1
fi
