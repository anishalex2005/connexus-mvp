Environment files for ConnexUS Flutter app
===========================================

Create the following files locally (not committed) with environment-specific values:

- .env.development
- .env.staging
- .env.production (must be gitignored)

Example contents:

Development (.env.development):

API_BASE_URL=http://10.0.2.2:3000
API_VERSION=v1
API_TIMEOUT=30000
TELNYX_API_KEY=KEY_TEST_xxxxx
TELNYX_SIP_USER=dev_user
TELNYX_SIP_PASSWORD=dev_password
TELNYX_WEBHOOK_URL=http://localhost:3000/webhooks/telnyx
RETELL_API_KEY=dev_retell_key
RETELL_AGENT_ID=dev_agent_001
RETELL_WEBHOOK_URL=http://localhost:3000/webhooks/retell
FCM_SERVER_KEY=dev_fcm_key
ENABLE_CALL_RECORDING=false
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=false
DEBUG_MODE=true
APP_NAME=ConnexUS Dev
APP_VERSION=0.0.1
BUILD_NUMBER=1

Staging (.env.staging):

API_BASE_URL=https://staging-api.connexus.app
API_VERSION=v1
API_TIMEOUT=30000
TELNYX_API_KEY=KEY_TEST_staging_xxxxx
TELNYX_SIP_USER=staging_user
TELNYX_SIP_PASSWORD=staging_password
TELNYX_WEBHOOK_URL=https://staging-api.connexus.app/webhooks/telnyx
RETELL_API_KEY=staging_retell_key
RETELL_AGENT_ID=staging_agent_001
RETELL_WEBHOOK_URL=https://staging-api.connexus.app/webhooks/retell
FCM_SERVER_KEY=staging_fcm_key
ENABLE_CALL_RECORDING=true
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
DEBUG_MODE=true
APP_NAME=ConnexUS Staging
APP_VERSION=0.0.1
BUILD_NUMBER=1

Production (.env.production):

API_BASE_URL=https://api.connexus.app
API_VERSION=v1
API_TIMEOUT=20000
TELNYX_API_KEY=KEY_LIVE_xxxxx
TELNYX_SIP_USER=prod_user
TELNYX_SIP_PASSWORD=prod_password
TELNYX_WEBHOOK_URL=https://api.connexus.app/webhooks/telnyx
RETELL_API_KEY=prod_retell_key
RETELL_AGENT_ID=prod_agent_001
RETELL_WEBHOOK_URL=https://api.connexus.app/webhooks/retell
FCM_SERVER_KEY=prod_fcm_key
ENABLE_CALL_RECORDING=true
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
DEBUG_MODE=false
APP_NAME=ConnexUS
APP_VERSION=1.0.0
BUILD_NUMBER=1


