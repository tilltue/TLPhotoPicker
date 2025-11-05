#!/bin/bash

# TLPhotoPicker Release Script
# Automates version bumping and deployment for CocoaPods and SPM

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

# Files to update
PODSPEC_FILE="TLPhotoPicker.podspec"
CHANGELOG_FILE="CHANGELOG.md"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}TLPhotoPicker Release Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if working directory is clean
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}Error: Working directory is not clean. Please commit or stash your changes.${NC}"
    exit 1
fi

# Get current version from podspec
CURRENT_VERSION=$(grep -E "s.version\s*=\s*'[0-9]+\.[0-9]+\.[0-9]+'" $PODSPEC_FILE | sed -E "s/.*'([0-9]+\.[0-9]+\.[0-9]+)'.*/\1/")
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"

# Parse version numbers
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Calculate new version (increment patch by default)
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

echo -e "New version will be: ${GREEN}$NEW_VERSION${NC}"
echo ""

# Ask for confirmation with retry loop
while true; do
    read -p "Do you want to proceed with version $NEW_VERSION? [Y/n] " -r
    # Default to 'y' if empty (just Enter pressed)
    REPLY=${REPLY:-y}

    case $REPLY in
        [Yy]* )
            echo -e "${GREEN}Proceeding with release...${NC}"
            break
            ;;
        [Nn]* )
            echo -e "${RED}Release cancelled.${NC}"
            exit 1
            ;;
        * )
            echo -e "${YELLOW}Please answer 'y' (yes) or 'n' (no), or just press Enter to proceed.${NC}"
            ;;
    esac
done
echo ""

# Update podspec version
echo -e "${YELLOW}Updating $PODSPEC_FILE...${NC}"
sed -i '' "s/s\.version[[:space:]]*=[[:space:]]*'$CURRENT_VERSION'/s.version          = '$NEW_VERSION'/" $PODSPEC_FILE

# Verify the change
UPDATED_VERSION=$(grep -E "s.version\s*=\s*'[0-9]+\.[0-9]+\.[0-9]+'" $PODSPEC_FILE | sed -E "s/.*'([0-9]+\.[0-9]+\.[0-9]+)'.*/\1/")
if [[ "$UPDATED_VERSION" != "$NEW_VERSION" ]]; then
    echo -e "${RED}Error: Failed to update version in $PODSPEC_FILE${NC}"
    exit 1
fi

# Update CHANGELOG if it exists
if [[ -f "$CHANGELOG_FILE" ]]; then
    echo -e "${YELLOW}Updating $CHANGELOG_FILE...${NC}"
    TODAY=$(date +%Y-%m-%d)
    # Add new version header at the top (after the main title)
    sed -i '' "/^# /a\\
\\
## [$NEW_VERSION] - $TODAY\\
### Changed\\
- Version bump to $NEW_VERSION\\
" $CHANGELOG_FILE
fi

# Validate podspec
echo -e "${YELLOW}Validating podspec...${NC}"
pod lib lint --allow-warnings

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Podspec validation failed!${NC}"
    echo -e "${YELLOW}Reverting changes...${NC}"
    git checkout $PODSPEC_FILE
    [[ -f "$CHANGELOG_FILE" ]] && git checkout $CHANGELOG_FILE
    exit 1
fi

# Commit changes
echo -e "${YELLOW}Committing changes...${NC}"
git add $PODSPEC_FILE
[[ -f "$CHANGELOG_FILE" ]] && git add $CHANGELOG_FILE
git commit -m "chore: bump version to $NEW_VERSION"

# Create git tag
echo -e "${YELLOW}Creating git tag $NEW_VERSION...${NC}"
git tag -a "$NEW_VERSION" -m "Release version $NEW_VERSION"

# Push changes and tags
echo -e "${YELLOW}Pushing to remote...${NC}"
git push origin master
git push origin "$NEW_VERSION"

# Deploy to CocoaPods
echo -e "${YELLOW}Publishing to CocoaPods...${NC}"
pod trunk push $PODSPEC_FILE --allow-warnings

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to publish to CocoaPods!${NC}"
    echo -e "${YELLOW}Note: Git tag and commit have been pushed. You may need to manually publish to CocoaPods.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Release completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Version: ${GREEN}$NEW_VERSION${NC}"
echo -e "CocoaPods: ${GREEN}Published${NC}"
echo -e "SPM: ${GREEN}Available via git tag${NC}"
echo ""
echo -e "${YELLOW}Note: SPM users can now use version $NEW_VERSION by updating their Package.swift dependency.${NC}"
