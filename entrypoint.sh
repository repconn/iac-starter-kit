#!/usr/bin/env sh

# Load Google Cloud SDK completions
. /opt/google-cloud-sdk/path.bash.inc

# Add Google Cloud SDK bin directory to the PATH
export PATH="/opt/google-cloud-sdk/bin:${PATH}"

# Change current directory
cd /code/live

# Pass arguments if any
exec "$@"
