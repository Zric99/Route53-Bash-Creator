#!/bin/bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

##SETTINGS##

# Vordefinierte Ziel-DNS-Namen
OPTION1="www.${HOSTED_ZONE_DOMAIN}"
OPTION2="test.${HOSTED_ZONE_DOMAIN}"


read -p "Record-Name (z.B. preview.wolftravel.de): " CUSTOMER_DNS

# Extrahiere Subdomain, Domain und TLD aus CUSTOMER_DNS
IFS='.' read -r SUBDOMAIN DOMAIN TLD <<< "$CUSTOMER_DNS"


echo "Ist das System mehrsprachig?"
echo "1) no"
echo "2) yes"
read -p "Bitte Nummer eingeben (1 oder 2): " MULTILINGUAL_OPTION

case "$MULTILINGUAL_OPTION" in
  1) MULTILINGUAL="no" ;;
  2) MULTILINGUAL="yes" ;;
  *) echo "Ungültige Auswahl!"; exit 1 ;;
esac

if [[ "$MULTILINGUAL" == "yes" ]]; then
  if [[ "$TLD" == "co.uk" ]]; then
    RECORD_NAME_TLD="uk"
  else
    RECORD_NAME_TLD="$TLD"
  fi
  
  echo "Um was für ein system handelt es sich?"
  echo "1) Standard (live-production / cms / rms / preview)"
  echo "2) Staging"
  read -p "Bitte Nummer eingeben (1 oder 2): " VARIANT_OPTION

  case "$VARIANT_OPTION" in
    1) VARIANT="multilanguage-standard" ;;
    2) echo "Multilingual Staging wird aktuell nicht unterstütz." ; exit 1 ;;
    *) echo "Ungültige Auswahl!"; exit 1 ;;
  esac



elif [[ "$MULTILINGUAL" == "no" ]]; then
  if [[ "$TLD" == "co.uk" ]]; then
    RECORD_NAME_TLD="uk"
  else
    RECORD_NAME_TLD="$TLD"
  fi
  echo "Um was für eine Variante handelt es sich?"
  echo "1) Standard (live-production / cms / rms / preview)"
  echo "2) Staging" 
  read -p "Bitte Nummer eingeben (1 oder 2): " VARIANT_OPTION

  case "$VARIANT_OPTION" in
    1) VARIANT="standard" ;;
    2) VARIANT="staging" ;;   
    *) echo "Ungültige Auswahl!"; exit 1 ;;
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
    echo "Multilingual Preview wird aktuell nicht unterstützt."
    exit 1
    # R53_RECORD_NAME="preview.$RECORD_NAME_TLD.staging.$DOMAIN"
  else
    R53_RECORD_NAME="web.$RECORD_NAME_TLD.production.$DOMAIN"
  fi

  ## DISABLE FOR NOW MULTILANGUAGE STAGING##
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


# Prüfe, ob das letzte Zeichen ein Punkt ist, falls nicht, hänge einen Punkt an
if [[ ! "$R53_RECORD_NAME" =~ \.$ ]]; then
  R53_RECORD_NAME="$R53_RECORD_NAME."
fi

R53_RECORD_NAME="${R53_RECORD_NAME}${HOSTED_ZONE_DOMAIN}."


echo "Wähle das Ziel für den Alias-Record:"
echo "1) $OPTION1"
echo "2) $OPTION2"
read -p "Bitte Nummer eingeben (1 oder 2): " TARGET_OPTION
case "$TARGET_OPTION" in
  1) TARGET_DNS_NAME="$OPTION1" ;;
  2) TARGET_DNS_NAME="$OPTION2" ;;
  *) echo "Ungültige Auswahl!"; exit 1 ;;
esac



TTL=300

echo "FÜR DEN DNS RECORD WIRD FOLGENDES GESETZT: $R53_RECORD_NAME zeigt per ALIAS auf $TARGET_DNS_NAME"
echo "FÜR DEN KUNDEN WIRD FOLGENDE INFORMATION BEREITGGESTELLT: $CUSTOMER_DNS muss per CNAME auf $R53_RECORD_NAME zeigen."

echo "➡️  Lege Alias A-Record $R53_RECORD_NAME → $TARGET_DNS_NAME an ..."

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

echo "📨 Change eingereicht: $CHANGE_ID"
echo "⏳ Warte auf INSYNC ..."

# Polling bis INSYNC (max. ~5 Minuten)
ATTEMPTS=60
SLEEP_SECONDS=5
for ((i=1; i<=ATTEMPTS; i++)); do
  STATUS=$(aws route53 get-change --id "$CHANGE_ID" --query 'ChangeInfo.Status' --output text --no-cli-pager)
  if [[ "$STATUS" == "INSYNC" ]]; then
    echo "✅ Fertig: Record ist INSYNC."
    # --- Outlook-Mail vorbereiten ---
  
    MAIL_SUBJECT="Neuer DNS-Record angelegt: $RECORD_NAME"
    MAIL_BODY="Der folgende DNS-Record wurde angelegt:\n\nRecord Name: $RECORD_NAME\nZiel-DNS: $CUSTOMER_DNS\n\nBitte prüfen."
    # AppleScript für Outlook
    osascript <<EOF
    tell application "Microsoft Outlook"
      set newMessage to make new outgoing message with properties {subject:"$MAIL_SUBJECT", content:"$MAIL_BODY"}
      open newMessage
      activate
    end tell
EOF
    exit 0
  fi
  printf "Versuch %d/%d: Status=%s\r" "$i" "$ATTEMPTS" "$STATUS"
  sleep "$SLEEP_SECONDS"
done

echo
echo "⚠️  Timeout: Status ist noch nicht INSYNC. Prüfe manuell mit:"
echo "    aws route53 get-change --id $CHANGE_ID"
exit 1

