#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/git-functions.sh

if [ "$DEBUG" = true ]; then
  set -x
fi

WINDOWS_USER="$WINDOWS_USER"
WINDOWS_IP="$WINDOWS_IP"
WINDOWS_PASSWORD="$WINDOWS_PASSWORD"
CODEBASE_DIR="$CODEBASE_DIR"
REMOTE_TARGET_PATH="$REMOTE_TARGET_PATH"

ENV="$ENV"
CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"

sleep $SLEEP_DURATION
logInfoMessage "I'll do processing at [$CODEBASE_LOCATION]"
cd "${CODEBASE_LOCATION}"

COMPLETED_PATH="$REMOTE_TARGET_PATH/$ENV"
logInfoMessage "Complete path to Codebases: [$COMPLETED_PATH]"

WINDOWS_PATH=$(echo "$COMPLETED_PATH" | sed 's#\\#/#g')

logInfoMessage "Windows IP: $WINDOWS_IP"
logInfoMessage "Windows path: $WINDOWS_PATH"


if [ -n "$LOCAL_FILE_PATH" ] && [ -e "$LOCAL_FILE_PATH" ]; then
    logInfoMessage "LOCAL_FILE_PATH exists: $LOCAL_FILE_PATH"
else
    logErrorMessage "LOCAL_FILE_PATH not found or not provided"
    exit 1
fi

if [ "$CLEAN_OLD_DIR" = "true" ]; then
  sshpass -p "$WINDOWS_PASSWORD" ssh -o StrictHostKeyChecking=no "$WINDOWS_USER@$WINDOWS_IP" \
  "powershell -NoProfile -ExecutionPolicy Bypass -Command \"if (Test-Path '$WINDOWS_PATH') { Remove-Item -Recurse -Force '$WINDOWS_PATH' -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Force -Path '$WINDOWS_PATH'\""
  logInfoMessage "Cleaned and created directory [$WINDOWS_PATH]"
else
  sshpass -p "$WINDOWS_PASSWORD" ssh -o StrictHostKeyChecking=no "$WINDOWS_USER@$WINDOWS_IP" \
  "powershell -NoProfile -ExecutionPolicy Bypass -Command \"New-Item -ItemType Directory -Force -Path '$WINDOWS_PATH'\""
  logInfoMessage "Created directory or already exists [$WINDOWS_PATH]"
fi

logInfoMessage "I have started copying the Codebase to [$WINDOWS_PATH]"
sshpass -p "$WINDOWS_PASSWORD" scp -r -o StrictHostKeyChecking=no "$LOCAL_FILE_PATH" "$WINDOWS_USER@$WINDOWS_IP:$WINDOWS_PATH\\"
logInfoMessage "Codebase copy completed to [$WINDOWS_PATH]"

TASK_STATUS=$?
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
