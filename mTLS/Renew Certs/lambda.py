import boto3
from datetime import datetime, timezone, timedelta

# Initialize clients
acm_client = boto3.client('acm')
sns_client = boto3.client('sns')

# Configuration
sns_topic_arn = 'arn:aws:sns:eu-west-2:891377009330:Security-Notifications'  # Replace with your SNS topic ARN
days_threshold = 60  # Number of days before expiry

def lambda_handler(event, context):
    certificates = acm_client.list_certificates()['CertificateSummaryList']
    expiring_certs = []

    for cert in certificates:
        cert_arn = cert['CertificateArn']
        cert_details = acm_client.describe_certificate(CertificateArn=cert_arn)
        not_after = cert_details['Certificate']['NotAfter']
        time_remaining = not_after - datetime.now(timezone.utc)

        if time_remaining < timedelta(days=days_threshold):
            expiring_certs.append({
                'DomainName': cert['DomainName'],
                'NotAfter': not_after.strftime('%Y-%m-%d')
            })

    if expiring_certs:
        message = "The following ACM certificates are nearing expiration:\n\n"
        for cert in expiring_certs:
            message += f"- Domain: {cert['DomainName']}, Expiry Date: {cert['NotAfter']}\n"

        # Send notification
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject="ALERT: ACM Certificates Expiring Soon",
            Message=message
        )

    return {
        'statusCode': 200,
        'body': 'Lambda execution completed.'
    }
