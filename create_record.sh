#!/bin/bash
set -euo pipefail

source .env


read -p "Record name (e.g. www.domain.tld): " CUSTOMER_DNS

# Extract subdomain, domain and TLD from CUSTOMER_DNS
IFS='.' read -r SUBDOMAIN DOMAIN TLD <<< "$CUSTOMER_DNS"


echo "Is the system multilingual?"
echo "1) no"
echo "2) yes"
read -p "Please enter number (1 or 2): " MULTILINGUAL_OPTION

case "$MULTILINGUAL_OPTION" in
  1) MULTILINGUAL="no" ;;
  2) MULTILINGUAL="yes" ;;
  *) echo "Invalid selection!"; exit 1 ;;
esac

if [[ "$MULTILINGUAL" == "yes" ]]; then
  if [[ "$TLD" == "co.uk" ]]; then
    RECORD_NAME_TLD="uk"
  else
    RECORD_NAME_TLD="$TLD"
  fi
  
  echo "What type of system is it?"
  echo "1) Standard (live-production / cms / rms / preview)"
  echo "2) Staging"
  read -p "Please enter number (1 or 2): " VARIANT_OPTION

  case "$VARIANT_OPTION" in
    1) VARIANT="multilanguage-standard" ;;
    2) echo "Multilingual staging is currently not supported." ; exit 1 ;;
    *) echo "Invalid selection!"; exit 1 ;;
  esac



elif [[ "$MULTILINGUAL" == "no" ]]; then
  if [[ "$TLD" == "co.uk" ]]; then
    RECORD_NAME_TLD="uk"
  else
    RECORD_NAME_TLD="$TLD"
  fi
  echo "Which variant is it?"
  echo "1) Standard (live-production / cms / rms / preview)"
  echo "2) Staging" 
  read -p "Please enter number (1 or 2): " VARIANT_OPTION

  case "$VARIANT_OPTION" in
    1) VARIANT="standard" ;;
    2) VARIANT="staging" ;;   
    *) echo "Invalid selection!"; exit 1 ;;
  esac
fi





if [[ "$VARIANT" == "standard" ]]; then

  if [[ "$SUBDOMAIN" == cms* ]]; then
    R53_RECORD_NAME="cms.production.$DOMAIN"
  elif [[ "$SUBDOMAIN" == preview* ]]; then
    R53_RECORD_NAME="web.preview.$DOMAIN"
  else
    R53_RECORD_NAME="web.production.$DOMAIN"
  fi

elif [[ "$VARIANT" == "staging" ]]; then

  if [[ "$SUBDOMAIN" == cms* ]]; then
    R53_RECORD_NAME="cms.staging.$DOMAIN"
  elif [[ "$SUBDOMAIN" == preview* ]]; then
    R53_RECORD_NAME="preview.staging.$DOMAIN"
  else
    R53_RECORD_NAME="web.staging.$DOMAIN"
  fi

elif [[ "$VARIANT" == "multilanguage-standard" ]]; then

  if [[ "$SUBDOMAIN" == cms* ]]; then
    R53_RECORD_NAME="cms.$RECORD_NAME_TLD.production.$DOMAIN"
  elif [[ "$SUBDOMAIN" == preview* ]]; then
  echo "Multilingual preview is currently not supported."
  exit 1
  # R53_RECORD_NAME="preview.$RECORD_NAME_TLD.staging.$DOMAIN"
  else
    R53_RECORD_NAME="web.$RECORD_NAME_TLD.production.$DOMAIN"
  fi

# ## DISABLE FOR NOW MULTILANGUAGE STAGING##
# elif [[ "$VARIANT" == "multilanguage-staging" ]]; then
#   if [[ "$SUBDOMAIN" == cms* ]]; then
#     R53_RECORD_NAME="cms.$RECORD_NAME_TLD.staging.$DOMAIN"
#   elif [[ "$SUBDOMAIN" == preview* ]]; then
#     R53_RECORD_NAME="preview.$RECORD_NAME_TLD.staging.$DOMAIN"
#   else
#     R53_RECORD_NAME="web.$RECORD_NAME_TLD.staging.$DOMAIN"
#   fi

else
  echo "Unbekannte Variante: $VARIANT"
  exit 1
fi


# Check if the last character is a dot, if not, append a dot
if [[ ! "$R53_RECORD_NAME" =~ \.$ ]]; then
  R53_RECORD_NAME="$R53_RECORD_NAME."
fi

R53_RECORD_NAME="${R53_RECORD_NAME}${HOSTED_ZONE_DOMAIN}."


echo "Choose the target for the alias record:"
echo "1) $OPTION1"
echo "2) $OPTION2"
read -p "Please enter number (1 or 2): " TARGET_OPTION
case "$TARGET_OPTION" in
  1) TARGET_DNS_NAME="$OPTION1" ;;
  2) TARGET_DNS_NAME="$OPTION2" ;;
  *) echo "Invalid selection!"; exit 1 ;;
esac



TTL=300

echo "FOR THE DNS RECORD THE FOLLOWING WILL BE SET: $R53_RECORD_NAME points via ALIAS to $TARGET_DNS_NAME"
echo "FOR THE CUSTOMER THE FOLLOWING INFORMATION WILL BE PROVIDED: $CUSTOMER_DNS must point via CNAME to $R53_RECORD_NAME."

echo "➡️  Creating alias A-record $R53_RECORD_NAME → $TARGET_DNS_NAME ..."

CHANGE_ID=$(
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"CREATE\",
      \"ResourceRecordSet\": {
        \"Name\": \"$RECORD_NAME\",
        \"Type\": \"A\",
        \"AliasTarget\": {
            \"HostedZoneId\": \"${HOSTED_ZONE_ID}\",
          \"DNSName\": \"${TARGET_DNS_NAME}.\",
          \"EvaluateTargetHealth\": false
        }
      }
    }]
  }" \
  --query 'ChangeInfo.Id' --output text --no-cli-pager
)

echo "📨 Change submitted: $CHANGE_ID"
echo "⏳ Waiting for INSYNC ..."

# Polling until INSYNC (max. ~5 minutes)
ATTEMPTS=60
SLEEP_SECONDS=5

for ((i=1; i<=ATTEMPTS; i++)); do
  STATUS=$(aws route53 get-change --id "$CHANGE_ID" --query 'ChangeInfo.Status' --output text --no-cli-pager)
  if [[ "$STATUS" == "INSYNC" ]]; then
  echo "✅ Done: Record is INSYNC."
  # --- Prepare Outlook mail ---
  
  MAIL_SUBJECT="New DNS record created: $RECORD_NAME"
  MAIL_BODY="The following DNS record was created:\n\nRecord Name: $RECORD_NAME\nTarget DNS: $CUSTOMER_DNS\n\nPlease check."
  # AppleScript for Outlook
  osascript <<EOF
    tell application "Microsoft Outlook"
      set newMessage to make new outgoing message with properties {subject:"$MAIL_SUBJECT", content:"$MAIL_BODY"}
      open newMessage
      activate
    end tell
EOF
    exit 0
  fi
  printf "Attempt %d/%d: Status=%s\r" "$i" "$ATTEMPTS" "$STATUS"
  sleep "$SLEEP_SECONDS"
done

echo
echo "⚠️  Timeout: Status is still not INSYNC. Check manually with:"
echo "    aws route53 get-change --id $CHANGE_ID"
exit 1
