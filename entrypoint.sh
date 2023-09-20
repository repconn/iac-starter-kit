#!/usr/bin/env sh

# Load Google Cloud SDK completions
# shellcheck source=/dev/null
. /opt/google-cloud-sdk/path.bash.inc

# Adjust PATH
export PATH="/opt/google-cloud-sdk/bin:${PATH}"
export PATH="/opt/aws-cli/bin:${PATH}"

# Change current directory
cd /code/live > /dev/null 2>&1 || true

# Pass arguments if any
exec "$@"
