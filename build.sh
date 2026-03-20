#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/git-functions.sh


if [ -z "$FERNET_KEY" ]; then
  logErrorMessage "FERNET_KEY is not set"
  exit 1
fi

TARGET_USERNAME=$(python3 - <<PY
import os, json
from cryptography.fernet import Fernet

data = json.loads(os.environ['CREDENTIAL_MANAGEMENT'])
fernet = Fernet(os.environ['FERNET_KEY'].encode())

val = data["integration_1"].get("CREDENTIAL_USERNAME")

if val:
    print(fernet.decrypt(val.encode()).decode())
else:
    print("")
PY
)

TARGET_PASSWORD=$(python3 - <<PY
import os, json
from cryptography.fernet import Fernet

data = json.loads(os.environ['CREDENTIAL_MANAGEMENT'])
fernet = Fernet(os.environ['FERNET_KEY'].encode())

val = data["integration_1"].get("CREDENTIAL_PASSWORD")

if val:
    print(fernet.decrypt(val.encode()).decode())
else:
    print("")
PY
)

TARGET_TOKEN=$(python3 - <<PY
import os, json
from cryptography.fernet import Fernet

data = json.loads(os.environ['CREDENTIAL_MANAGEMENT'])
fernet = Fernet(os.environ['FERNET_KEY'].encode())

val = data["integration_1"].get("CREDENTIAL_ACCESS_TOKEN_OR_KEY")

if val:
    print(fernet.decrypt(val.encode()).decode())
else:
    print("")
PY
)

TARGET_KEY_VALUE=$(python3 - <<PY
import os, json

data = json.loads(os.environ['CREDENTIAL_MANAGEMENT'])

val = data["integration_1"].get("CREDENTIAL_KEY_VALUE_PAIR")

print("" if val is None else val)
PY
)

export TARGET_USERNAME
export TARGET_PASSWORD
export TARGET_TOKEN
export TARGET_KEY_VALUE


if [ "$DEBUG" = true ]; then
  set -x
fi

TARGET_USERNAME="$TARGET_USERNAME"
TARGET_PASSWORD="$TARGET_PASSWORD"
TARGET_IP="$TARGET_IP"
SOURCE_PATH="${WORKSPACE}/$SOURCE_PATH"
DEST_PATH="$DEST_PATH"

if [ -z "$TARGET_USERNAME" ] || [ -z "$TARGET_IP" ] || [ -z "$TARGET_PASSWORD" ]; then
  logErrorMessage "Target Server credentials are missing"
  exit 1
fi

CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"

sleep $SLEEP_DURATION
logInfoMessage "I'll do processing at [$CODEBASE_LOCATION]"
cd "${CODEBASE_LOCATION}"

COMPLETED_PATH="$DEST_PATH/$PROJECT_ENV_NAME"
logInfoMessage "Complete path to Codebases: [$COMPLETED_PATH]"

WINDOWS_PATH=$(echo "$COMPLETED_PATH" | sed 's#\\#/#g')

logInfoMessage "Target Server IP: $TARGET_IP"
logInfoMessage "Target Server path: $WINDOWS_PATH"


if [ -n "$SOURCE_PATH" ] && [ -e "$SOURCE_PATH" ]; then
    logInfoMessage "SOURCE_PATH exists: $SOURCE_PATH"
else
    logErrorMessage "SOURCE_PATH not found or not provided"
    exit 1
fi

if [ "$CLEAN_OLD_DIR" = "true" ]; then
  sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no "$TARGET_USERNAME@$TARGET_IP" \
  "powershell -NoProfile -ExecutionPolicy Bypass -Command \"if (Test-Path '$WINDOWS_PATH') { Remove-Item -Recurse -Force '$WINDOWS_PATH' -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Force -Path '$WINDOWS_PATH'\""
  logInfoMessage "Cleaned and created directory [$WINDOWS_PATH]"
else
  logWarningMessage "CLEAN_OLD_DIR is not set to true, skipping directory cleanup"
fi

logInfoMessage "I have started copying the Codebase to [$WINDOWS_PATH]"
if sshpass -f <(echo "$TARGET_PASSWORD") scp -o StrictHostKeyChecking=no -r "$SOURCE_PATH" "$TARGET_USERNAME@$TARGET_IP:$WINDOWS_PATH"; then
    logInfoMessage "Codebase copy completed successfully"
    TASK_STATUS=0
else
    logErrorMessage "Codebase copy failed to [$WINDOWS_PATH] either due to connectivity issues or authentication failure"
    TASK_STATUS=1
fi

TASK_STATUS=$?
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
