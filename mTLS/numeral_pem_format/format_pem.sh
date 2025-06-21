#!/bin/bash
set -e

# Example input: whitespace-separated certificate string
CERT_RAW="<+pipeline.variables.CERT>"

# Define headers
BEGIN_LINE="-----BEGIN CERTIFICATE-----"
END_LINE="-----END CERTIFICATE-----"

# Extract body by stripping headers
BODY=$(echo "$CERT_RAW" \
  | sed "s/$BEGIN_LINE//" \
  | sed "s/$END_LINE//" \
  | tr -d '[:space:]' \
  | fold -w 64)

# Reconstruct the PEM with proper formatting
FORMATTED_CERT=$(printf "%s\n%s\n%s\n" "$BEGIN_LINE" "$BODY" "$END_LINE")

# Show output for visibility
echo "Formatted PEM content:"
echo "$FORMATTED_CERT"

# Build JSON secret
SECRET_STRING=$(jq -n --arg cert "$FORMATTED_CERT" '{formattedCert: $cert}')

# Update AWS secret
aws secretsmanager update-secret \
  --secret-id "doug_test" \
  --secret-string "$SECRET_STRING" \
  --region eu-west-2

echo "AWS secret '$SECRET_NAME' updated"

