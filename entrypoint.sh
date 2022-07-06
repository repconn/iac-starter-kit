#!/usr/bin/env sh

# Load Google Cloud SDK completions
. /opt/google-cloud-sdk/path.bash.inc

# Add Google Cloud SDK bin directory to the PATH
export PATH="/opt/google-cloud-sdk/bin:${PATH}"

# Change current working directory to live
# and pass arguments if any
if [ -d /code/live ]; then
  cd /code/live || exec "$@"
else
  exec "$@"
fi
