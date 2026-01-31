#!/bin/bash

# ============================================
# Script to Update Main Branch with Latest Project
# ============================================
# This script replaces the main branch content with your current branch
# Usage: ./update_main.sh "Project Name/Description"
# ============================================

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Check if project name is provided
if [ -z "$1" ]; then
    print_error "Please provide a project name/description"
    echo "Usage: ./update_main.sh \"Project Name\""
    exit 1
fi

PROJECT_NAME=$1
CURRENT_BRANCH=$(git branch --show-current)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Validation checks
print_info "Starting main branch update process..."
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not a git repository. Please run this script from your git project directory."
fi

# Check if current branch is not main
if [ "$CURRENT_BRANCH" == "main" ]; then
    print_error "You are currently on the main branch. Please switch to your project branch first."
fi

# Display current status
print_info "Current branch: ${YELLOW}$CURRENT_BRANCH${NC}"
print_info "Project name: ${YELLOW}$PROJECT_NAME${NC}"
echo ""

# Confirm with user
read -p "$(echo -e ${YELLOW}⚠️  This will replace ALL content in main branch with $CURRENT_BRANCH. Continue? [y/N]: ${NC})" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Operation cancelled by user."
    exit 0
fi

echo ""
print_info "Proceeding with update..."
echo ""

# Step 1: Create backup of main branch
print_info "Step 1/7: Creating backup of main branch..."
BACKUP_BRANCH="main-backup-$(date +%Y%m%d-%H%M%S)"

if git show-ref --verify --quiet refs/heads/main; then
    git branch "$BACKUP_BRANCH" main
    print_success "Backup created: $BACKUP_BRANCH"
else
    print_warning "Main branch doesn't exist yet. Will create it fresh."
fi

# Step 2: Ensure all changes are committed
print_info "Step 2/7: Checking for uncommitted changes..."
if ! git diff-index --quiet HEAD --; then
    print_error "You have uncommitted changes. Please commit or stash them first."
fi
print_success "Working directory is clean"

# Step 3: Push current branch to remote (if it exists)
print_info "Step 3/7: Pushing current branch to remote..."
if git ls-remote --heads origin "$CURRENT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
    git push origin "$CURRENT_BRANCH" || print_warning "Failed to push $CURRENT_BRANCH (continuing anyway)"
    print_success "Current branch pushed to remote"
else
    git push -u origin "$CURRENT_BRANCH" || print_warning "Failed to push $CURRENT_BRANCH (continuing anyway)"
    print_success "Current branch pushed to remote (new branch)"
fi

# Step 4: Checkout main branch
print_info "Step 4/7: Switching to main branch..."
git checkout main 2>/dev/null || git checkout -b main
print_success "On main branch"

# Step 5: Replace main with current branch content
print_info "Step 5/7: Replacing main branch content..."
git reset --hard "$CURRENT_BRANCH"
print_success "Main branch content replaced"

# Step 6: Update commit message
print_info "Step 6/7: Creating update commit..."
git commit --amend -m "Portfolio Update: $PROJECT_NAME

Updated: $TIMESTAMP
Source Branch: $CURRENT_BRANCH
Previous backup: $BACKUP_BRANCH

This commit represents the latest project in the portfolio.
" --allow-empty || git commit -m "Portfolio Update: $PROJECT_NAME

Updated: $TIMESTAMP
Source Branch: $CURRENT_BRANCH

This commit represents the latest project in the portfolio.
" --allow-empty

print_success "Commit created"

# Step 7: Force push to remote
print_info "Step 7/7: Pushing to remote repository..."
read -p "$(echo -e ${YELLOW}Push to remote (force push required)? [y/N]: ${NC})" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin main --force
    print_success "Main branch updated on remote!"
else
    print_warning "Skipped remote push. Run 'git push origin main --force' manually when ready."
fi

# Step 8: Return to original branch
print_info "Returning to original branch..."
git checkout "$CURRENT_BRANCH"
print_success "Back on $CURRENT_BRANCH"

echo ""
echo "============================================"
print_success "Main branch successfully updated!"
echo "============================================"
echo ""
print_info "Summary:"
echo "  • Main branch now contains: $PROJECT_NAME"
echo "  • Source branch: $CURRENT_BRANCH"
echo "  • Backup created: $BACKUP_BRANCH"
echo ""
print_info "To restore previous main if needed:"
echo "  git checkout main"
echo "  git reset --hard $BACKUP_BRANCH"
echo "  git push origin main --force"
echo ""
print_success "Done! 🎉"