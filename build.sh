#!/bin/bash
source /opt/buildpiper/shell-functions/functions.sh
source /opt/buildpiper/shell-functions/log-functions.sh
source /opt/buildpiper/shell-functions/git-functions.sh
# Optionally enable debugging
if [ "$DEBUG" = true ]; then
  set -x  
fi
# Configuration
WINDOWS_USER="$WINDOWS_USER"
WINDOWS_IP="$WINDOWS_IP"
WINDOWS_PASSWORD="$WINDOWS_PASSWORD"
CODEBASE_DIR="$CODEBASE_DIR"                    
Deploy_Environment=$DEPLOY_ENV
#ARTIFACTS_PATH_LOCAL="$ARTIFACTS_PATH_LOCAL"
ARTIFACTS_PATH_WIND=$ARTIFACTS_PATH_WIND
#SHARED_LOCATION=$SHARED_LOCATION
CODEBASE_LOCATION="${WORKSPACE}"/"${CODEBASE_DIR}"
logInfoMessage "I'll do processing at [$CODEBASE_LOCATION]"
cd "${CODEBASE_LOCATION}"

# #Rename the artifact name
# mv "$ARTIFACTS_PATH_LOCAL/${tag}-Resource Center-win32-x64.exe" "$ARTIFACTS_PATH_LOCAL/Resource Center-win.exe"
# mkdir -p $ARTIFACTS_PATH_LOCAL/$DEPLOY_ENV/${tag}-PENDING_SANITY/
# cp "$ARTIFACTS_PATH_LOCAL/Resource Center-win.exe" "$ARTIFACTS_PATH_LOCAL/$DEPLOY_ENV/${tag}-PENDING_SANITY/"
# LOCAL_COPIED_ARTIFACT="$ARTIFACTS_PATH_LOCAL/$DEPLOY_ENV" 
# WINDOWS_COPIED_ARTIFACT="$DEPLOY_ENV/${tag}-PENDING_SANITY/Resource Center-win.exe"


#Copying $CODEBASE_DIR
logInfoMessage "I have started copying the artifact to [$ARTIFACTS_PATH_WIND]"
sshpass -p "$WINDOWS_PASSWORD" scp -r -o StrictHostKeyChecking=no "$LOCAL_COPIED_ARTIFACT" "$WINDOWS_USER@$WINDOWS_IP:$ARTIFACTS_PATH_WIND\\"
if [ $? -ne 0 ]; then
  logErrorMessage "Failed to transfer Artifact on Windows VM."
  exit 1
else
  logInfoMessage "artifact copied successfully to Artifact on Windows VM"
fi
#Copying Artifact to shared location
# sshpass -p "$WINDOWS_PASSWORD" ssh -v -o StrictHostKeyChecking=no -o ConnectTimeout=60 "$WINDOWS_USER@$WINDOWS_IP" \
# "echo f | xcopy \"$ARTIFACTS_PATH_WIND\\$DEPLOY_ENV\\\" \"${SHARED_LOCATION}\\$DEPLOY_ENV\\\" /Y /R /I /E"
# if [ $? -ne 0 ]; then
#   logErrorMessage "Failed to transfer Artifact code to Shared location."
#   exit 1
# else
#   logInfoMessage "artifact copied successfully to Artifact on Shared location"
# fi
TASK_STATUS=$?
saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}