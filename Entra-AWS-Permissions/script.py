import boto3
import re

# Define expected permission sets
PERMISSION_SET_MAPPING = {
    "-admin": "EntraID-AWSAdminAccess",
    "-reader": "EntraID-AWSReadOnlyAccess",
    "-pwruser": "EntraID-AWSPowerUserAccess",
    "-eksadmin": "EntraID-AWSEKSAdminAccess",
    "-eksreader": "EntraID-AWSEKSReadOnlyAccess",
    "-eksorchreader": "EntraID-AWSEKSOrchReadOnlyAccess",
    "-mskadmin": "EntraID-AWSMSKAdminAccess",
    "-scaudit": "EntraID-AWSSecurityAuditAccess",
    "-ssmreader": "EntraID-AWSSSMReadOnlyAccess",
    "-apigwadmin": "EntraID-AWSAPIGWAdminAccess",
    "-kafkaadmin": "EntraID-AWSKafkaUIAdminAccess",
    "-developer": "EntraID-AWSVeriParkDeveloper"
}

# Define account mapping based on group name pattern
ACCOUNT_MAPPING = {
    "-audit-": "339713012643",
    "-backup-": "381492148168",
    "-devtest-": "381491825821",
    "-mgmt-": "654654512313",
    "-log-": "851725432165",
    "-network-": "211125625664",
    "-oprdev-": "713881793836",
    "-oprprod-": "207567780569",
    "-prod-": "533267118313",
    "-sctools-": "891377009330",
    "-sharedsvc-": "533267216364",
    "-vpdev-": "010928204689",
    "-vpprod-": "010928204850",
    "-sandbox-": "905418475562"
}

# Initialize AWS SSO client
sso_client = boto3.client('identitystore')

# Function to list all groups in AWS Identity Center
def list_groups(identity_store_id):
    groups = []
    paginator = sso_client.get_paginator('list_groups')
    for page in paginator.paginate(IdentityStoreId=identity_store_id):
        for group in page['Groups']:
            if group['DisplayName'].startswith("aws-sg-acc-"):
                groups.append(group['DisplayName'])
    return groups

# Function to check group account assignments and permission sets
def validate_groups(groups):
    errors = []

    for group in groups:
        assigned_account = None
        expected_permission_set = None

        # Determine expected account
        for key, account in ACCOUNT_MAPPING.items():
            if key in group:
                assigned_account = account
                break

        # Determine expected permission set
        for key, permission_set in PERMISSION_SET_MAPPING.items():
            if group.endswith(key):
                expected_permission_set = permission_set
                break

        if not assigned_account:
            errors.append(f"Group {group} does not match any known account patterns.")
        
        if not expected_permission_set:
            errors.append(f"Group {group} does not match any known permission set patterns.")

        print(f"Group: {group} -> Account: {assigned_account}, Permission Set: {expected_permission_set}")

    return errors

if __name__ == "__main__":
    identity_store_id = "d-9c67612a2e"

    print("Fetching groups from AWS Identity Center...")
    groups = list_groups(identity_store_id)

    print("\nValidating group assignments...")
    validation_errors = validate_groups(groups)

    if validation_errors:
        print("\nValidation Errors:")
        for error in validation_errors:
            print(error)
    else:
        print("\nAll group mappings are correct!")
