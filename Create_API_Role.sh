#!/bin/bash

# ---------- CONFIG ----------
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
