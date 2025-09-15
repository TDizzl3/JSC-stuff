#!/bin/zsh --no-rcs

####################################################################################################
#This script's purpose is to run a POST against Jamf Pro's server to create the API role required for OAuth Authentication for Device Lifecycle Management UEM Connect Settings which are required fro UEM connection.
#Requirements for this script to work:
#-Existing API Client with appropriate permissions to create the API Role
#Permissions required for Device Lifecycle management are in the PRIVILEGES Variable
####################################################################################################
# Changelog:
# Modified 09/15/2025 - Terry Nichols Jr
####################################################################################################
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#        * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#           notice, this list of conditions and the following disclaimer in the
#           documentation and/or other materials provided with the distribution.
#         * Neither the name of the JAMF Software, LLC nor the
#           names of its contributors may be used to endorse or promote products
#           derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
# EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
####################################################################################################

# ---------- CONFIG FOR JAMF PRO ----------
JAMF_URL="https://YOURJAMFCLOUD.jamfcloud.com"
CLIENT_ID="XXXXX-xxxxx-xxxxx-xxxxxx"
CLIENT_SECRET="XXXXX-xxxxx-xxxxx-xxxxxx"
ROLE_NAME="NAME OF THE ROLE HERE"
#This is the privileges required when utilizing API Client account to connect Jamf Security Cloud and Jamf Pro
PRIVILEGES=("Read Mac Applications" "Read Mobile Devices" "Read Mobile Device Applications" "Read Smart Mobile Device Groups" "Create Static Mobile Device Groups" "Read Static Mobile Device Groups" "Read Computers" "Read Smart Computer Groups" "Create Static Computer Groups" "Create Computer Extension Attributes" "Read Computer Extension Attributes" "Update Computer Extension Attributes" "Delete Computer Extension Attributes" "Create Mobile Device Extension Attributes" "Read Mobile Device Extension Attributes" "Update Mobile Device Extension Attributes" "Delete Mobile Device Extension Attributes" "Update Mobile Devices" "Update Computers" "Update User")

# ---------- GET BEARER TOKEN USING OAUTH ----------
getAccessToken() {
  response=$(curl --silent --location --request POST "${JAMF_URL}/api/oauth/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${CLIENT_ID}" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_secret=${CLIENT_SECRET}")

  TOKEN=$(echo "$response" | jq -r .access_token)
  TOKEN_EXPIRES_IN=$(echo "$response" | jq -r .expires_in)
  CURRENT_EPOCH=$(date +%s)
  TOKEN_EXPIRATION_EPOCH=$((CURRENT_EPOCH + TOKEN_EXPIRES_IN - 1))
}

# ---------- CALL TOKEN FUNCTION ----------
getAccessToken

# ---------- BUILD PRIVILEGES JSON ----------
PRIV_JSON=""
for p in "${PRIVILEGES[@]}"; do
  PRIV_JSON+="\"$p\","
done
PRIV_JSON="[${PRIV_JSON%,}]"

# ---------- CREATE API ROLE ----------
echo "[+] Creating API role: $ROLE_NAME"
RESPONSE=$(curl -s -X POST \
  "$JAMF_URL/uapi/v1/api-roles" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"displayName\": \"$ROLE_NAME\",
    \"privileges\": $PRIV_JSON
  }")

echo "$RESPONSE" | jq
