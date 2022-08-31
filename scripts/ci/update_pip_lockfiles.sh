#!/bin/sh

set -eux

BAZEL_STARTUP_OPTIONS="${BAZEL_STARTUP_OPTIONS:-}"

# Get pip_compile labels in the order they should be ran.
get_pip_compile_labels() {
  bazel $BAZEL_STARTUP_OPTIONS query --output=label --order_output=full \
    'kind(py_binary, attr("main", "@rules_python//python/pip_install:pip_compile.py", //...))' |
    tac
}

BAZEL_PC_LABELS="$(get_pip_compile_labels)"

# Build all of them
# shellcheck disable=SC2086
bazel $BAZEL_STARTUP_OPTIONS build $BAZEL_PC_LABELS

# Run them in order
for label in $BAZEL_PC_LABELS; do
  bazel $BAZEL_STARTUP_OPTIONS run "$label"
done

# [REMOVED] Update for gazelle manifests.

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
