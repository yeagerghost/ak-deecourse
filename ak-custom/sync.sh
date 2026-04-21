#!/bin/bash
set -e

UPSTREAM_URL="https://github.com/yeagerghost/deecourse.git"
VENDOR_MAIN_BRANCH="discourse-main"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ You have uncommitted changes. Commit or stash before running."
  exit 1
fi

# Ensure upstream remote exists
if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "Upstream not found. Adding it..."
  git remote add upstream "$UPSTREAM_URL"
fi

echo "Fetching upstream..."
git fetch upstream

# Update vendor-main branch
echo "Updating $VENDOR_MAIN_BRANCH..."
git checkout $VENDOR_MAIN_BRANCH 2>/dev/null || git checkout -b $VENDOR_MAIN_BRANCH upstream/main
git reset --hard upstream/main

# Push vendor mirror to origin
git push origin $VENDOR_MAIN_BRANCH --force-with-lease

# Rebase your main branch onto vendor
echo "Rebasing main onto $VENDOR_MAIN_BRANCH..."
git checkout main
git rebase $VENDOR_MAIN_BRANCH

# Push updated main
git push origin main --force-with-lease

echo "✅ Sync complete"
