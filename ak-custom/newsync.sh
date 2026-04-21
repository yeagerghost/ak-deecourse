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

git checkout $VENDOR_MAIN_BRANCH upstream/main
git pull -u upstream main

# echo "Fetching upstream..."
# git fetch upstream
#
# # Update vendor-main branch
# echo "Updating $VENDOR_MAIN_BRANCH..."
# git checkout $VENDOR_MAIN_BRANCH 2>/dev/null || git checkout -b $VENDOR_MAIN_BRANCH upstream/main
# git reset --hard upstream/main
#
# # Push vendor mirror to origin
# git push origin $VENDOR_MAIN_BRANCH --force-with-lease
#
# Show incoming changes
echo ""
echo "📋 Commits from upstream:"
git log --oneline --no-merges main..$VENDOR_MAIN_BRANCH

echo " ===== BREAKING ======"
exit 0

echo ""
echo "📁 Files changed:"
git diff --name-status main..$VENDOR_MAIN_BRANCH

# Skip if nothing to do
if git diff --quiet main..$VENDOR_MAIN_BRANCH; then
  echo "✅ No upstream changes to merge."
  exit 0
fi

# Merge safely
echo ""
echo "Merging $VENDOR_MAIN_BRANCH into main..."
git checkout main

if ! git merge $VENDOR_MAIN_BRANCH --no-edit; then
  echo ""
  echo "❌ Merge conflict detected!"
  echo "Resolve conflicts, then run:"
  echo "  git add <files>"
  echo "  git commit"
  echo "  git push origin main"
  echo ""
  echo "Or abort with:"
  echo "  git merge --abort"
  exit 1
fi

# Push normally
# Ask for confirmation before pushing
echo ""
read -p "⚠️  Proceed with pushing 'main' to origin? (yes/no): " response

case "$response" in
yes | y | Y)
  echo "🚀 Pushing to origin/main..."
  git push origin main
  echo "✅ Sync complete"
  ;;
*)
  echo "❌ Push skipped. You can review changes locally."
  echo "To push later, run:"
  echo "  git push origin main"
  exit 0
  ;;
esac
