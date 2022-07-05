#!/usr/bin/env sh

# Load Google Cloud completions
. /opt/google-cloud-sdk/path.bash.inc

# Add Google Cloud bin directory to the PATH
export PATH="/opt/google-cloud-sdk/bin:${PATH}"

# Change current working directory to IaC live
cd /code/live || exit

# Pass any arguments
exec "$@"
