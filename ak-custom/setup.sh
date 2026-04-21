#!/bin/bash
set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./setup.sh [dev|prod]"
  exit 1
fi

echo "=== Setting up Discourse ($ENV) ==="

# Load env
source env/$ENV.env

# Prompt secrets
read -s -p "Database Password: " DISCOURSE_DB_PASSWORD
echo ""

if [ "$ENABLE_MAILPIT" != "true" ]; then
  read -s -p "SMTP Password: " SMTP_PASSWORD
  echo ""
fi

export DISCOURSE_HOSTNAME
export DISCOURSE_DEVELOPER_EMAILS
export DISCOURSE_NOTIFICATION_EMAIL
export DISCOURSE_DB_PASSWORD
export SMTP_ADDRESS SMTP_USER SMTP_PASSWORD

# Clone upstream if needed
# if [ ! -d discourse ]; then
#   git clone https://github.com/discourse/discourse.git discourse
# fi

# Copy template
cp my-templates/web_only.base.yml.template containers/web_only.yml
cd containers

########################################
# 🔧 STRUCTURAL CHANGES WITH yq
########################################

echo "Applying feature flags..."

# Remove HTTPS if disabled
if [ "$ENABLE_HTTPS" != "true" ]; then
  yq -i '
    .expose |= map(select(. != "443:443"))
  ' web_only.yml
fi

# Add mailpit link if enabled
if [ "$ENABLE_MAILPIT" = "true" ]; then
  yq -i '
    .links += [{
      "link": {
        "name": "mailpit",
        "alias": "mailpit"
      }
    }]
  ' web_only.yml
fi

# Remove mailpit if disabled (safety)
if [ "$ENABLE_MAILPIT" != "true" ]; then
  yq -i '
    .links |= map(select(.link.name != "mailpit"))
  ' web_only.yml
fi

########################################
# 🌍 VARIABLE SUBSTITUTION
########################################

echo "Injecting variables..."

envsubst < web_only.yml > web_only.final.yml
# mv -v web_only.final.yml web_only.yml

########################################
# 🚀 BUILD
########################################

#echo "Running Discourse rebuild..."
#./launcher rebuild app

echo "✅ Setup complete"
