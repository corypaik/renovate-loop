#!/bin/sh

set -eux

# Usually this checks for files that need to be updated and then updates them.
# For this reproduction, it is just applying the patch that makes those changes.
git apply third_party/datasets.patch

# If there were any changes commit them and exit with an error.
if [ "$(git diff --stat)" != '' ]; then
  # If there were not changes w.r.t. main, it is likely that we just reverted
  # versions. In this case we do not want to commit the changes.
  if ! [ "$(git diff main --stat)" != '' ]; then
    echo "ERROR: Detected changes from last commit, but none from main."
  # Allow this script to be ran without a buildkite branch by a user.
  elif [ "${BUILDKITE_BRANCH:-}" != "" ]; then
    git pull origin "$BUILDKITE_BRANCH"
    git add .
    git commit --fixup HEAD
    git push origin "HEAD:$BUILDKITE_BRANCH"
  fi
  exit 1
fi
