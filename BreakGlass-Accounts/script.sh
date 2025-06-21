#!/bin/bash

# Variables
ROLE_NAME="awsadministrator"                      # The role in question
ACTION="cloudwatch:DescribeAlarms"                # CloudWatch action being denied (change if needed)
REGION="us-east-1"                                # AWS region
MAX_EVENTS=10                                     # Number of events to check (increase if needed)

# Fetch CloudTrail events and parse for AccessDenied errors
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=$ACTION \
    --region $REGION \
    --max-results $MAX_EVENTS \
    --query "Events[?ErrorCode=='AccessDenied']" \
    --output json | jq -r '.[] | select(.CloudTrailEvent | contains("service control policy")) | .CloudTrailEvent' > denied_events.json

# Check if there are any SCP-related denial events
if [[ ! -s denied_events.json ]]; then
    echo "No SCP-related AccessDenied events found for action '$ACTION' in region '$REGION'."
    exit 1
fi

# Parse each event to identify the denial reason
echo "SCP-related AccessDenied events found:"
jq -r '
    . | 
    {
      EventTime: .eventTime,
      Username: .userIdentity.sessionContext.sessionIssuer.userName,
      EventName: .eventName,
      ErrorCode: .errorCode,
      ErrorMessage: .errorMessage,
      AccessDeniedCause: .requestParameters | select(. != null)
    }
' denied_events.json

echo "Review the SCPs in your organization that apply to the role '$ROLE_NAME' and region '$REGION' to identify the specific policy with the explicit deny."

# Cleanup temporary file
rm denied_events.json
