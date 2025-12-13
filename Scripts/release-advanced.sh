#!/bin/bash

# TLPhotoPicker Advanced Release Script
# Supports custom version bumping (major, minor, patch) or specific version

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

# Files to update
PODSPEC_FILE="TLPhotoPicker.podspec"
CHANGELOG_FILE="CHANGELOG.md"

# Functions
print_usage() {
    echo "Usage: $0 [patch|minor|major|VERSION]"
    echo ""
    echo "Arguments:"
    echo "  patch       Increment patch version (x.y.Z) - default"
    echo "  minor       Increment minor version (x.Y.0)"
    echo "  major       Increment major version (X.0.0)"
    echo "  VERSION     Specify exact version (e.g., 3.0.0)"
    echo ""
    echo "Examples:"
    echo "  $0              # Increment patch: 2.1.12 -> 2.1.13"
    echo "  $0 patch        # Increment patch: 2.1.12 -> 2.1.13"
    echo "  $0 minor        # Increment minor: 2.1.12 -> 2.2.0"
    echo "  $0 major        # Increment major: 2.1.12 -> 3.0.0"
    echo "  $0 2.5.0        # Set to specific version: 2.5.0"
}

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}TLPhotoPicker Release Script${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

validate_version() {
    if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid version format. Expected: x.y.z${NC}"
        return 1
    fi
    return 0
}

# Parse arguments
BUMP_TYPE="${1:-patch}"

print_header

# Check if help is requested
if [[ "$BUMP_TYPE" == "-h" ]] || [[ "$BUMP_TYPE" == "--help" ]]; then
    print_usage
    exit 0
fi

# Check if working directory is clean
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}Error: Working directory is not clean. Please commit or stash your changes.${NC}"
    exit 1
fi

# Check if on master branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "master" ]]; then
    echo -e "${YELLOW}Warning: You are not on the master branch (current: $CURRENT_BRANCH)${NC}"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Release cancelled.${NC}"
        exit 1
    fi
fi

# Get current version from podspec
CURRENT_VERSION=$(grep -E "s.version\s*=\s*'[0-9]+\.[0-9]+\.[0-9]+'" $PODSPEC_FILE | sed -E "s/.*'([0-9]+\.[0-9]+\.[0-9]+)'.*/\1/")
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"

# Parse version numbers
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Calculate new version based on bump type
case "$BUMP_TYPE" in
    patch)
        NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
        ;;
    minor)
        NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
        ;;
    major)
        NEW_VERSION="$((MAJOR + 1)).0.0"
        ;;
    *)
        # Assume it's a specific version
        NEW_VERSION="$BUMP_TYPE"
        if ! validate_version "$NEW_VERSION"; then
            echo ""
            print_usage
            exit 1
        fi
        ;;
esac

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

# Optional: Ask for changelog entry
echo ""
echo -e "${BLUE}Enter a brief description of changes (or press Enter to skip):${NC}"
read -r CHANGELOG_ENTRY

# Update podspec version
echo ""
echo -e "${YELLOW}[1/7] Updating $PODSPEC_FILE...${NC}"
sed -i '' "s/s\.version[[:space:]]*=[[:space:]]*'$CURRENT_VERSION'/s.version          = '$NEW_VERSION'/" $PODSPEC_FILE

# Verify the change
UPDATED_VERSION=$(grep -E "s.version\s*=\s*'[0-9]+\.[0-9]+\.[0-9]+'" $PODSPEC_FILE | sed -E "s/.*'([0-9]+\.[0-9]+\.[0-9]+)'.*/\1/")
if [[ "$UPDATED_VERSION" != "$NEW_VERSION" ]]; then
    echo -e "${RED}Error: Failed to update version in $PODSPEC_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Podspec updated${NC}"

# Update CHANGELOG if it exists
if [[ -f "$CHANGELOG_FILE" ]]; then
    echo -e "${YELLOW}[2/7] Updating $CHANGELOG_FILE...${NC}"
    TODAY=$(date +%Y-%m-%d)

    if [[ -n "$CHANGELOG_ENTRY" ]]; then
        # Add new version with custom entry
        sed -i '' "/^# /a\\
\\
## [$NEW_VERSION] - $TODAY\\
### Changed\\
- $CHANGELOG_ENTRY\\
" $CHANGELOG_FILE
    else
        # Add new version with default entry
        sed -i '' "/^# /a\\
\\
## [$NEW_VERSION] - $TODAY\\
### Changed\\
- Version bump to $NEW_VERSION\\
" $CHANGELOG_FILE
    fi
    echo -e "${GREEN}✓ Changelog updated${NC}"
else
    echo -e "${YELLOW}[2/7] No CHANGELOG.md found, skipping...${NC}"
fi

# Validate podspec
echo -e "${YELLOW}[3/7] Validating podspec...${NC}"
pod lib lint --allow-warnings

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Podspec validation failed!${NC}"
    echo -e "${YELLOW}Reverting changes...${NC}"
    git checkout $PODSPEC_FILE
    [[ -f "$CHANGELOG_FILE" ]] && git checkout $CHANGELOG_FILE
    exit 1
fi
echo -e "${GREEN}✓ Podspec validation passed${NC}"

# Commit changes
echo -e "${YELLOW}[4/7] Committing changes...${NC}"
git add $PODSPEC_FILE
[[ -f "$CHANGELOG_FILE" ]] && git add $CHANGELOG_FILE

if [[ -n "$CHANGELOG_ENTRY" ]]; then
    git commit -m "chore: bump version to $NEW_VERSION

$CHANGELOG_ENTRY"
else
    git commit -m "chore: bump version to $NEW_VERSION"
fi
echo -e "${GREEN}✓ Changes committed${NC}"

# Create git tag
echo -e "${YELLOW}[5/7] Creating git tag $NEW_VERSION...${NC}"
if [[ -n "$CHANGELOG_ENTRY" ]]; then
    git tag -a "$NEW_VERSION" -m "Release version $NEW_VERSION

$CHANGELOG_ENTRY"
else
    git tag -a "$NEW_VERSION" -m "Release version $NEW_VERSION"
fi
echo -e "${GREEN}✓ Git tag created${NC}"

# Push changes and tags
echo -e "${YELLOW}[6/7] Pushing to remote...${NC}"
git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"
echo -e "${GREEN}✓ Pushed to remote${NC}"

# Deploy to CocoaPods
echo -e "${YELLOW}[7/7] Publishing to CocoaPods...${NC}"
pod trunk push $PODSPEC_FILE --allow-warnings

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to publish to CocoaPods!${NC}"
    echo -e "${YELLOW}Note: Git tag and commit have been pushed.${NC}"
    echo -e "${YELLOW}You may need to manually publish to CocoaPods using:${NC}"
    echo -e "${BLUE}pod trunk push $PODSPEC_FILE --allow-warnings${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Published to CocoaPods${NC}"

# Print success summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Release completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Version:     ${GREEN}$CURRENT_VERSION${NC} → ${GREEN}$NEW_VERSION${NC}"
echo -e "CocoaPods:   ${GREEN}✓ Published${NC}"
echo -e "SPM:         ${GREEN}✓ Available via git tag${NC}"
echo -e "Git Tag:     ${GREEN}$NEW_VERSION${NC}"
echo ""
echo -e "${BLUE}SPM users can now update their Package.swift:${NC}"
echo -e "${BLUE}.package(url: \"https://github.com/tilltue/TLPhotoPicker.git\", from: \"$NEW_VERSION\")${NC}"
echo ""
