import boto3
import os
from datetime import datetime, timedelta, timezone

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

TABLE_NAME = os.environ['DDB_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    today = datetime.now(timezone.utc).date()

    response = table.scan()
    alerts = []

    for item in response.get('Items', []):
        expiry_str = item.get('expiry_date')
        serial = item.get('serial_number')
        name = item.get('client_name')
        status = item.get('status', 'unknown')

        if not expiry_str:
            continue

        expiry = datetime.strptime(expiry_str, "%Y-%m-%d").date()
        days_left = (expiry - today).days

        if status != "revoked" and (days_left in [60, 30] or 0 <= days_left <= 14):
            alerts.append(f"Certificate '{name}' (Serial: {serial}) expires in {days_left} day(s) on {expiry_str}.")

    if alerts:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="⚠️ Certificate Expiry Alert",
            Message="\n\n".join(alerts)
        )

