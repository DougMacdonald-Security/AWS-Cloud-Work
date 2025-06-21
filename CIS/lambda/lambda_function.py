import boto3
import gzip
import json
import base64
import re
from io import BytesIO
from os import environ
from datetime import datetime, timedelta


sns = boto3.client("sns")
sns_topic_arn = environ.get("SNS_TOPIC_ARN")

# Define CIS-style match patterns using regular expressions and additional rules for ECR scans.
match_patterns = {
    # 1️⃣ Creation/Deletion of IAM Users
    "IAM User Creation/Deletion": lambda e: e.get("eventName") in ["CreateUser", "DeleteUser"],

    # 2️⃣ Creation of Cross-Account IAM Roles
    "Cross-Account IAM Role Creation": lambda e: (
        e.get("eventName") == "CreateRole" and
        "arn:aws:iam::" in json.dumps(e.get("roleAssumeRolePolicyDocument", {}))
    ),

    # 3️⃣ Deploying AWS Resources Outside London/Ireland
    "Resource Deployment Outside London/Ireland": lambda e: (
        e.get("eventSource") not in ["eu-west-1", "eu-west-2"] and
        e.get("eventName", "").startswith("Create")
    ),

    # 4️⃣ EKS Containers Running as Root
    "EKS Container Running as Root": lambda e: (
        e.get("eventSource") == "eks.amazonaws.com" and
        "root" in json.dumps(e.get("podSecurityViolations", {}))
    ),

    # 5️⃣ EKS Running on Unsupported Kubernetes Version
    "EKS on Unsupported Kubernetes Version": lambda e: (
        e.get("eventSource") == "eks.amazonaws.com" and
        e.get("eventName") == "DescribeCluster" and
        e.get("responseElements", {}).get("version") in ["1.21", "1.22"]
    ),

    # 6️⃣ High-Severity GuardDuty Findings
    "High-Severity GuardDuty Findings": lambda e: (
        e.get("eventSource") == "guardduty.amazonaws.com" and
        e.get("severity", 0) >= 7.0
    ),

    # 7️⃣ Unencrypted S3 Bucket Creation
    "Unencrypted S3 Bucket Creation": lambda e: (
        e.get("eventName") == "CreateBucket" and
        not e.get("responseElements", {}).get("BucketEncryption")
    ),

    # 8️⃣ IAM User Key Generation/Deletion
    "IAM AWS User Key Generation/Deletion": lambda e: e.get("eventName") in ["CreateAccessKey", "DeleteAccessKey"],

    "IAM Role Wildcard Permissions": lambda e: (
        e.get("eventName") in ["CreateRole", "PutRolePolicy"] and
        "*" in json.dumps(e.get("requestParameters", {}).get("policyDocument", {}))
    ),

    "IAM Role with External ID": lambda e: (
        e.get("eventName") == "CreateRole" and
        "sts:ExternalId" in json.dumps(e.get("requestParameters", {}).get("assumeRolePolicyDocument", {}))
    ),

    "Security Group Ingress for SSH/FTP": lambda e: (
        e.get("eventName") == "AuthorizeSecurityGroupIngress" and
        any(port in json.dumps(e.get("requestParameters", {}).get("ipPermissions", {})) for port in ["22", "21"])
    ),

    "Unencrypted ELB Listener": lambda e: (
        e.get("eventName") == "CreateLoadBalancer" and
        "80" in json.dumps(e.get("requestParameters", {}).get("listeners", {}))
    ),

    "EKS Cluster Public Endpoint": lambda e: (
        e.get("eventName") in ["CreateCluster", "UpdateClusterConfig"] and
        e.get("requestParameters", {}).get("resourcesVpcConfig", {}).get("endpointPublicAccess", True)
    ),

    "Public Access to S3 Bucket": lambda e: (
        e.get("eventName") in ["PutBucketPolicy", "PutBucketAcl"] and
        "*" in json.dumps(e.get("requestParameters", {}).get("policy", {}))
    ),

    # [CloudWatch.1] Root account usage
    "CIS-1 Root Account Usage": lambda e: (
        e.get("userIdentity", {}).get("type") == "Root" and
        "invokedBy" not in e.get("userIdentity", {}) and
        e.get("eventType") != "AwsServiceEvent"
    ),

    # [CloudWatch.3] Console login without MFA
    "CIS-3 Sign-In Without MFA": lambda e: (
        e.get("eventName") == "ConsoleLogin" and
        e.get("additionalEventData", {}).get("MFAUsed") != "Yes" and
        e.get("userIdentity", {}).get("type") == "IAMUser" and
        e.get("responseElements", {}).get("ConsoleLogin") == "Success"
    ),

    # [CloudWatch.4] IAM policy changes
    "CIS-4 IAM Policy Changes": lambda e: e.get("eventName") in [
        "DeleteGroupPolicy", "DeleteRolePolicy", "DeleteUserPolicy",
        "PutGroupPolicy", "PutRolePolicy", "PutUserPolicy",
        "CreatePolicy", "DeletePolicy", "CreatePolicyVersion",
        "DeletePolicyVersion", "AttachRolePolicy", "DetachRolePolicy",
        "AttachUserPolicy", "DetachUserPolicy", "AttachGroupPolicy",
        "DetachGroupPolicy"
    ],

    # [CloudWatch.5] CloudTrail or AWS Config changes
    "CIS-5 CloudTrail or Config Changes": lambda e: e.get("eventName") in [
        "CreateTrail", "StopLogging", "DeleteTrail", "UpdateTrail",
        "PutConfigurationRecorder", "PutDeliveryChannel",
        "DeleteDeliveryChannel", "DeleteConfigurationRecorder"
    ],

    # [CloudWatch.6] Console auth failures
    "CIS-6 Console Authentication Failures": lambda e: (
        e.get("eventName") == "ConsoleLogin" and
        e.get("errorMessage") == "Failed authentication"
    ),

    # [CloudWatch.7] Disabling or deleting CMKs
    "CIS-7 KMS CMK Disable or Schedule Delete": lambda e: e.get("eventName") in [
        "DisableKey", "ScheduleKeyDeletion"
    ],

    # [CloudWatch.8] S3 bucket policy changes
    "CIS-8 S3 Bucket Policy Changes": lambda e: e.get("eventName") in [
        "PutBucketAcl", "PutBucketPolicy", "PutBucketCors",
        "PutBucketLifecycle", "PutBucketReplication", "DeleteBucketPolicy",
        "DeleteBucketCors", "DeleteBucketLifecycle", "DeleteBucketReplication"
    ],

    # [CloudWatch.9] AWS Config Configuration Changes
    "CIS-9 Config Configuration Changes": lambda e: e.get("eventName") in [
        "PutConfigurationRecorder", "PutDeliveryChannel",
        "DeleteDeliveryChannel", "DeleteConfigurationRecorder"
    ],

    # [CloudWatch.10] Security group changes
    "CIS-10 Security Group Changes": lambda e: e.get("eventName") in [
        "AuthorizeSecurityGroupIngress", "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupIngress", "RevokeSecurityGroupEgress",
        "CreateSecurityGroup", "DeleteSecurityGroup"
    ],

    # [CloudWatch.11] NACL changes
    "CIS-11 NACL Changes": lambda e: e.get("eventName") in [
        "CreateNetworkAcl", "CreateNetworkAclEntry",
        "DeleteNetworkAcl", "DeleteNetworkAclEntry",
        "ReplaceNetworkAclEntry", "ReplaceNetworkAclAssociation"
    ],

    # [CloudWatch.12] Internet gateway / NAT gateway changes
    "CIS-12 Network Gateway Changes": lambda e: e.get("eventName") in [
        "CreateInternetGateway", "AttachInternetGateway",
        "DeleteInternetGateway", "DetachInternetGateway",
        "CreateNatGateway", "DeleteNatGateway",
        "CreateCustomerGateway", "DeleteCustomerGateway"
    ],

    # [CloudWatch.13] Route table changes
    "CIS-13 Route Table Changes": lambda e: e.get("eventName") in [
        "CreateRouteTable", "DeleteRouteTable",
        "ReplaceRouteTableAssociation", "CreateRoute",
        "DeleteRoute", "ReplaceRoute"
    ],

    # [CloudWatch.14] VPC changes
    "CIS-14 VPC Changes": lambda e: e.get("eventName") in [
        "CreateVpc", "DeleteVpc", "ModifyVpcAttribute",
        "AcceptVpcPeeringConnection", "CreateVpcPeeringConnection",
        "DeleteVpcPeeringConnection", "RejectVpcPeeringConnection",
        "AttachClassicLinkVpc", "DetachClassicLinkVpc",
        "DisableVpcClassicLink", "EnableVpcClassicLink"
    ],

    # [CloudWatch.15] AWS Organizations changes
    "CIS-15 AWS Organizations Changes": lambda e: (
        e.get("eventSource") == "organizations.amazonaws.com" and
        e.get("eventName") in [
            "AcceptHandshake", "AttachPolicy", "CreateAccount",
            "CreateOrganizationalUnit", "CreatePolicy", "DeclineHandshake",
            "DeleteOrganization", "DeleteOrganizationalUnit", "DeletePolicy",
            "DetachPolicy", "DisablePolicyType", "EnablePolicyType",
            "InviteAccountToOrganization", "LeaveOrganization",
            "MoveAccount", "RemoveAccountFromOrganization",
            "UpdatePolicy", "UpdateOrganizationalUnit"
        ]
    ),

    # [ECR] ECR scan findings with high or critical vulnerabilities.
    "ECR Scan High/Critical Findings": lambda e: (
        e.get("eventName") in ["ImageScanCompleted", "DescribeImageScanFindings"] and
        "imageScanFindings" in e and (
            (e["imageScanFindings"].get("findingSeverityCounts", {}).get("HIGH", 0) > 0) or
            (e["imageScanFindings"].get("findingSeverityCounts", {}).get("CRITICAL", 0) > 0)
        )
    )
}


def parse_event_time(event_time_str):
    try:
        if '.' in event_time_str:
            return datetime.strptime(event_time_str, "%Y-%m-%dT%H:%M:%S.%fZ")
        else:
            return datetime.strptime(event_time_str, "%Y-%m-%dT%H:%M:%SZ")
    except Exception as ex:
        print(f"Error parsing event time: {ex}")
        return datetime.utcnow()


def extract_user_identity(user_identity):
    if not user_identity:
        return "Unknown"

    identity_type = user_identity.get("type")
    if identity_type == "IAMUser":
        return user_identity.get("userName", "Unknown")
    elif identity_type in ["AssumedRole", "FederatedUser"]:
        return user_identity.get("arn", "Unknown")
    elif identity_type == "Root":
        return "Root"
    else:
        return user_identity.get("principalId", "Unknown")


def extract_details(event):
    user_identity = event.get("userIdentity", {})
    return {
        "eventTime": event.get("eventTime"),
        "userName": extract_user_identity(user_identity),
        "sourceIPAddress": event.get("sourceIPAddress", "Unknown"),
        "eventName": event.get("eventName", "Unknown"),
        "accountId": event.get("recipientAccountId", "Unknown"),
        "matchedRule": None
    }



def publish_aggregated_alert(rule_name, events):
    count = len(events)
    first_event = events[0]
    last_event = events[-1]
    message = (
        f"🚨 Aggregated Alert for Rule: {rule_name}\n\n"
        f"Total events: {count}\n"
        f"Time range: {first_event['eventTime']} - {last_event['eventTime']}\n"
        f"First event details: User: {first_event['userName']}, Source IP: {first_event['sourceIPAddress']}\n"
    )
    message += (
        "Multiple similar events were detected within a short period."
        if count > 1 else f"Event: {first_event['eventName']}"
    )

    sns.publish(
        TopicArn=sns_topic_arn,
        Subject=f"[Alert] {rule_name} (Aggregated)",
        Message=message
    )


def group_events_by_time(events, window_minutes=2):
    events.sort(key=lambda e: parse_event_time(e["eventTime"]))
    groups = []
    current_group = []
    window = timedelta(minutes=window_minutes)

    for event in events:
        event_time = parse_event_time(event["eventTime"])
        if not current_group:
            current_group.append(event)
        else:
            last_event_time = parse_event_time(current_group[-1]["eventTime"])
            if event_time - last_event_time <= window:
                current_group.append(event)
            else:
                groups.append(current_group)
                current_group = [event]
    if current_group:
        groups.append(current_group)
    return groups

def lambda_handler(event, context):
    try:
        if "awslogs" not in event:
            print("No 'awslogs' key found in event. Event structure:")
            print(json.dumps(event, indent=2))
            return  # Exit early if the event isn't from CloudWatch Logs

        # Dictionary to hold aggregated events for each matching rule.
        aggregated_alerts = {}

        # Decode and decompress the CloudWatch Logs payload.
        compressed_payload = base64.b64decode(event["awslogs"]["data"])
        uncompressed_payload = gzip.GzipFile(fileobj=BytesIO(compressed_payload)).read()
        logs = json.loads(uncompressed_payload)

        # Process each log record.
        for record in logs.get("logEvents", []):
            try:
                event_data = json.loads(record["message"])
            except json.JSONDecodeError:
                continue  # Skip invalid JSON

            for rule_name, matcher in match_patterns.items():
                if matcher(event_data):
                    details = extract_details(event_data)
                    details["matchedRule"] = rule_name
                    aggregated_alerts.setdefault(rule_name, []).append(details)
                    break

        # Group and publish alerts
        for rule, events_list in aggregated_alerts.items():
            groups = group_events_by_time(events_list, window_minutes=2)
            for group in groups:
                publish_aggregated_alert(rule, group)

    except Exception as e:
        print(f"Error in log processing: {e}")
        raise
