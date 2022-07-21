#!/usr/bin/env sh

# Load Google Cloud SDK completions
# shellcheck source=/dev/null
. /opt/google-cloud-sdk/path.bash.inc

# Add Google Cloud SDK bin directory to the PATH
export PATH="/opt/google-cloud-sdk/bin:${PATH}"

# Change current directory
cd /code/live > /dev/null 2>&1 || true

# Pass arguments if any
exec "$@"
