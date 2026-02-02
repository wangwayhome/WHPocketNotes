#!/bin/bash

# Branch Comparison Tool for WHPocketNotes
# 用于比较分支代码，检查是否有遗漏的合并

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}WHPocketNotes Branch Comparison Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Base branch (usually main or develop)
BASE_BRANCH=${1:-main}

echo -e "${GREEN}Base Branch:${NC} $BASE_BRANCH"
echo ""

# Get all local and remote branches
ALL_BRANCHES=$(git branch -a | grep -v HEAD | grep -v "^\*" | sed 's/^ *//' | sed 's/remotes\/origin\///' | sort -u)

# Filter out base branch and current working branches
BRANCHES=""
for branch in $ALL_BRANCHES; do
    if [[ "$branch" != "$BASE_BRANCH" ]] && \
       [[ "$branch" != "copilot/compare-branch-code" ]] && \
       [[ "$branch" != "copilot/update-readme-in-english-and-chinese" ]]; then
        BRANCHES="$BRANCHES $branch"
    fi
done

echo -e "${YELLOW}Analyzing branches...${NC}"
echo ""

# Function to compare a branch with base
compare_branch() {
    local branch=$1
    local base=$2
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Branch: ${NC}$branch"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if branch has commits not in base
    COMMITS_AHEAD=$(git log $base..$branch --oneline 2>/dev/null | wc -l)
    
    if [ $COMMITS_AHEAD -gt 0 ]; then
        echo -e "${YELLOW}⚠ Found $COMMITS_AHEAD commit(s) NOT in $base${NC}"
        echo ""
        echo "Commits:"
        git log $base..$branch --oneline --pretty=format:"  %C(yellow)%h%C(reset) - %s %C(green)(%cr)%C(reset)" | head -20
        echo ""
        echo ""
        
        echo "Files changed:"
        git diff --name-status $base...$branch | head -30
        echo ""
        
        echo "Summary of changes:"
        git diff --stat $base...$branch | tail -5
        echo ""
    else
        echo -e "${GREEN}✓ No commits ahead of $base${NC}"
        echo ""
    fi
    
    # Check if base has commits not in branch
    COMMITS_BEHIND=$(git log $branch..$base --oneline 2>/dev/null | wc -l)
    
    if [ $COMMITS_BEHIND -gt 0 ]; then
        echo -e "${YELLOW}⚠ Branch is $COMMITS_BEHIND commit(s) BEHIND $base${NC}"
        echo ""
    fi
    
    echo ""
}

# Compare each branch
for branch in $BRANCHES; do
    compare_branch "$branch" "$BASE_BRANCH"
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Analysis Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "To merge a branch into $BASE_BRANCH:"
echo "  git checkout $BASE_BRANCH"
echo "  git merge <branch-name>"
echo ""
echo "To view detailed differences:"
echo "  git diff $BASE_BRANCH...<branch-name>"
echo ""
