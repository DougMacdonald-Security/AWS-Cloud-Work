locals {
  # Permission sets with their managed policies and inline policies
  permission_sets = {
    "EntraID-AWSAdminAccess" = {
      description = "Full access to AWS services and resources"
      managed_policies = [
        ["arn:aws:iam::aws:policy/AdministratorAccess",
        "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"]
      ]
      inline_policy = null
    }
    "EntraID-AWSReadOnlyAccess" = {
      description = "View resources and basic metadata across all AWS services"
      managed_policies = [
        ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      ]
      inline_policy = null
    }
    "EntraID-AWSDeveloperAccess" = {
      description = "EMPTY"
      managed_policies = [
        ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      ]
      inline_policy = null
    }
    "EntraID-AWSPowerUserAccess" = {
      description = "Access to AWS services and resources, but does not allow management of Users and groups"
      managed_policies = [
        ["arn:aws:iam::aws:policy/PowerUserAccess"]
      ]
      inline_policy = null
    }
    "EntraID-AWSEKSAdminAccess" = {
      description = "EKS Environment Admin Access"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
        "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess", 
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
      inline_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "eks:*",
                    "iam:ListRoles"
                ],
                "Resource": "*"
            },
            {
                "Sid": "Statement1",
                "Effect": "Allow",
                "Action": [
                    "inspector2:BatchGet*",
                    "inspector2:List*",
                    "inspector2:Describe*",
                    "inspector2:Get*",
                    "inspector2:Search*",
                    "ecr:GetRegistryScanningConfiguration"
                ],
                "Resource": "*"
            }
        ]
    })
    }
    "EntraID-AWSSSMReadOnlyAccess" = {
      description = "Read-only AWS Certificate Manager Private CA and ACM. View resources and basic metadata across all AWS services plus Inline policy"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSCertificateManagerPrivateCAReadOnly",
        "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      ]
      inline_policy = null
      
    }
    "EntraID-AWSAPIGWAdminAccess" = {
      description = "Full access to API Gateway"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator",
        "arn:aws:iam::aws:policy/AWSCertificateManagerPrivateCAReadOnly", 
        "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly",
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:ResumeSession",
                "ssm:TerminateSession",
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ssm:*:1234:document/*",
                "arn:aws:ecs:*:1234:task/*",
                "arn:aws:ec2:eu-west-2:1234:instance/i-abc",
                "arn:aws:ssm:*:1234:session/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ssm:Describe*",
                "ssm:Get*",
                "ssm:List*",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:CreateControlChannel",
                "ec2:Get*"
            ],
            "Resource": "*"
        }
    ]
})
    }
    "EntraID-AWSSecurityAuditAccess" = {
      description = "Read only access for security audit tasks"
      managed_policies = [
        ["arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
         "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
        ]
      ]
      inline_policy = null
    }

    "EntraID-AWSVeriParkDeveloper" = {
      description = "Read-only access to EC2 Container Registry, AmazonMQ, MSK Connect, RDS and CloudWatch Logs"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
        "arn:aws:iam::aws:policy/AmazonMQReadOnlyAccess", 
        "arn:aws:iam::aws:policy/AmazonMSKConnectReadOnlyAccess", 
        "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess", 
        "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "inspector2:BatchGet*",
                "inspector2:List*",
                "inspector2:Describe*",
                "inspector2:Get*",
                "inspector2:Search*",
                "ecr:GetRegistryScanningConfiguration"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectAttributes",
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::veripark-*/*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::veripark-*",
                "arn:aws:s3:::rosa-*"
            ]
        },
        {
            "Sid": "Extra",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
})
    }
      "EntraID-AWSVPSSMReadOnlyAccess" = {
      description = "specific read-only"
      managed_policies = [
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SSO",
            "Effect": "Allow",
            "Action": [
                "sso:ListDirectoryAssociations*",
                "identitystore:DescribeUser"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:GetPasswordData"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSM",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeInstanceProperties",
                "ssm:GetCommandInvocation",
                "ssm:GetInventorySchema",
                "ssm:DescribeInstanceInformation",
                "ssm:GetConnectionStatus"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerminateSession",
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/aws:ssmmessages:session-id": [
                        "$${aws:userName}"
                    ]
                }
            }
        },
        {
            "Sid": "SSMStartSession",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ec2:eu-west-2:1234:instance/i-abc",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                },
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": "ssm-guiconnect.amazonaws.com"
                }
            }
        },
        {
            "Sid": "SSMSendCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWSSSO-CreateSSOUser"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                }
            }
        },
        {
            "Sid": "GuiConnect",
            "Effect": "Allow",
            "Action": [
                "ssm-guiconnect:CancelConnection",
                "ssm-guiconnect:GetConnection",
                "ssm-guiconnect:StartConnection"
            ],
            "Resource": "*"
        }
    ]
})
    }
    "EntraID-AWSOrgFullAccess" = {
      description = "EMPTY"
      managed_policies = [
        ["arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"]
      ]
      inline_policy = null
    }
    "EntraID-AWSIAMFullAccess" = {
      description = "EMPTY"
      managed_policies = [
        ["arn:aws:iam::aws:policy/IAMFullAccess"]
      ]
     inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:AccessKubernetesApi",
                "eks:ListAddons",
                "eks:DescribeCluster",
                "eks:DescribeAddonVersions",
                "eks:ListClusters",
                "eks:ListIdentityProviderConfigs",
                "iam:ListRoles"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "inspector2:BatchGet*",
                "inspector2:List*",
                "inspector2:Describe*",
                "inspector2:Get*",
                "inspector2:Search*",
                "ecr:GetRegistryScanningConfiguration"
            ],
            "Resource": "*"
        }
    ]
})
    }

    "EntraID-AWSKafkaUISSMDev" = {
      description = "Dev Access to Kafka UI"
      managed_policies = []
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SSO",
            "Effect": "Allow",
            "Action": [
                "sso:ListDirectoryAssociations*",
                "identitystore:DescribeUser"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:GetPasswordData"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSM",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeInstanceProperties",
                "ssm:GetCommandInvocation",
                "ssm:GetInventorySchema",
                "ssm:DescribeInstanceInformation",
                "ssm:GetConnectionStatus",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerminateSession",
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/aws:ssmmessages:session-id": [
                        "$${aws:userName}"
                    ]
                }
            }
        },
        {
            "Sid": "SSMStartSession",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ec2:eu-west-2:1234:instance/i-abc",
                "arn:aws:ec2:eu-west-2:1234:instance/i-abc",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                },
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": "ssm-guiconnect.amazonaws.com"
                }
            }
        },
        {
            "Sid": "SSMSendCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWSSSO-CreateSSOUser"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                }
            }
        },
        {
            "Sid": "GuiConnect",
            "Effect": "Allow",
            "Action": [
                "ssm-guiconnect:CancelConnection",
                "ssm-guiconnect:GetConnection",
                "ssm-guiconnect:StartConnection"
            ],
            "Resource": "*"
        }
    ]
})
    }
        "EntraID-AWSEKSOrchViewAccess" = {
      description = "View access to Container Registry, MSK, CloudWatch and EKS orchestration layer namespace "
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
        "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess", 
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:AccessKubernetesApi",
                "eks:ListAddons",
                "eks:DescribeCluster",
                "eks:DescribeAddonVersions",
                "eks:ListClusters",
                "eks:ListIdentityProviderConfigs",
                "iam:ListRoles"
            ],
            "Resource": "*"
        }
    ]
})}
        "EntraID-AWSEKSOrchEditAccess" = {
      description = "Edit access for Devs "
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
        "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess", 
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
{
	"Statement": [
		{
			"Action": [
				"eks:DescribeNodegroup",
				"eks:ListNodegroups",
				"eks:ListUpdates",
				"eks:AccessKubernetesApi",
				"eks:ListAddons",
				"eks:DescribeCluster",
				"eks:DescribeAddonVersions",
				"eks:ListClusters",
				"eks:ListIdentityProviderConfigs",
				"iam:ListRoles",
				"s3:ListBucket",
				"s3:ListAllMyBuckets",
				"s3:ListBucketVersions"
			],
			"Effect": "Allow",
			"Resource": "*"
		},
		{
			"Sid": "DevTeamS3Access",
			"Effect": "Allow",
			"Action": [
				"s3:GetBucketAcl",
				"s3:GetBucketPolicy",
				"s3:GetObject",
				"s3:GetObjectAcl",
				"s3:GetObjectVersionAcl",
				"s3:PutObject",
				"s3:GetBucketVersioning",
				"s3:DeleteObjectVersion",
				"s3:DeleteObject",
				"s3:RestoreObject"
			],
			"Resource": [
				"arn:aws:s3:::s3-producer-*",
				"arn:aws:s3:::s3-producer-*/*",
				"arn:aws:s3:::s3-consumer-*",
				"arn:aws:s3:::s3-consumer-*/*",
				"arn:aws:s3:::s3-webhook-*",
				"arn:aws:s3:::s3-webhook-*/*",
				"arn:aws:s3:::s3-proxy-*",
				"arn:aws:s3:::s3-proxy-*/*"
			]
		}
	],
	"Version": "2012-10-17"
}
    ]
})}
"EntraID-AWSMSKReadOnly" = {
      description = "Read-only access to Amazon MSK, EC2 Container Registry and CloudWatch"
      managed_policies = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
      "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess", 
      "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
      "arn:aws:iam::aws:policy/AWSLambdaInvocation-DynamoDB",
      "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
      ]
      inline_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "eks:DescribeNodegroup",
              "eks:ListNodegroups",
              "eks:ListUpdates",
              "eks:AccessKubernetesApi",
              "eks:ListAddons",
              "eks:DescribeCluster",
              "eks:DescribeAddonVersions",
              "eks:ListClusters",
              "eks:ListIdentityProviderConfigs",
              "iam:ListRoles"
            ],
            "Resource": "*"
          },
          {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
              "inspector2:BatchGet*",
              "inspector2:List*",
              "inspector2:Describe*",
              "inspector2:Get*",
              "inspector2:Search*",
              "ecr:GetRegistryScanningConfiguration"
            ],
            "Resource": "*"
          }
        ]
      })
    }
  

  "EntraID-AWSEKSClusterViewAccess" = {
      description = "Read-only access to Amazon EC2 Container Registry, MSK and CloudWatch"
      managed_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", 
        "arn:aws:iam::aws:policy/AmazonMSKReadOnlyAccess", 
        "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
        ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:ListUpdates",
                "eks:AccessKubernetesApi",
                "eks:ListAddons",
                "eks:DescribeCluster",
                "eks:DescribeAddonVersions",
                "eks:ListClusters",
                "eks:ListIdentityProviderConfigs",
                "iam:ListRoles"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "inspector2:BatchGet*",
                "inspector2:List*",
                "inspector2:Describe*",
                "inspector2:Get*",
                "inspector2:Search*",
                "ecr:GetRegistryScanningConfiguration"
            ],
            "Resource": "*"
        }
    ]
})
    }
    "EntraID-AWSDynamoDBDevAccess" = {
      description = "Specific for DynamoDB"
      managed_policies = [
        ]
      inline_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"dynamodb:BatchGetItem",
				"dynamodb:BatchWriteItem",
				"dynamodb:ConditionCheckItem",
				"dynamodb:PutItem",
				"dynamodb:PartiQLUpdate",
				"dynamodb:DescribeContributorInsights",
				"dynamodb:Scan",
				"dynamodb:ListTagsOfResource",
				"dynamodb:Query",
				"dynamodb:DescribeStream",
				"dynamodb:UpdateItem",
				"dynamodb:DescribeTimeToLive",
				"dynamodb:PartiQLSelect",
				"dynamodb:DescribeTable",
				"dynamodb:GetShardIterator",
				"dynamodb:PartiQLInsert",
				"dynamodb:GetItem",
				"dynamodb:GetResourcePolicy",
				"dynamodb:DescribeKinesisStreamingDestination",
				"dynamodb:GetRecords",
				"dynamodb:PartiQLDelete",
				"dynamodb:DescribeTableReplicaAutoScaling"
			],
			"Resource": [
				"arn:aws:dynamodb:*:1234:table/PaymentLatestStatusProjection/index/*",
				"arn:aws:dynamodb:*:1234:table/PaymentStatus/index/*",
				"arn:aws:dynamodb:*:1234:table/PaymentStatusEventProjection/index/*",
				"arn:aws:dynamodb:*:1234:table/PaymentLatestStatusProjection/stream/*",
				"arn:aws:dynamodb:*:1234:table/PaymentStatus/stream/*",
				"arn:aws:dynamodb:*:1234:table/PaymentStatusEventProjection/stream/*",
				"arn:aws:dynamodb:*:1234:table/PaymentLatestStatusProjection",
				"arn:aws:dynamodb:*:1234:table/PaymentStatus",
				"arn:aws:dynamodb:*:1234:table/PaymentStatusEventProjection"
			]
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"dynamodb:DescribeReservedCapacityOfferings",
				"dynamodb:ListTables",
				"dynamodb:DescribeReservedCapacity",
				"dynamodb:GetAbacStatus",
				"dynamodb:DescribeLimits",
				"dynamodb:DescribeEndpoints"
			],
			"Resource": "*"
		}
	]
})
    }
        "EntraID-AWSSSMWinReadOnlyAccess" = {
      description = "Windows session host"
      managed_policies = [
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      ]
      inline_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SSO",
            "Effect": "Allow",
            "Action": [
                "sso:ListDirectoryAssociations*",
                "identitystore:DescribeUser"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:GetPasswordData"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSM",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeInstanceProperties",
                "ssm:GetCommandInvocation",
                "ssm:GetInventorySchema",
                "ssm:DescribeInstanceInformation",
                "ssm:GetConnectionStatus"
            ],
            "Resource": "*"
        },
        {
            "Sid": "TerminateSession",
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/aws:ssmmessages:session-id": [
                        "$${aws:userName}"
                    ]
                }
            }
        },
        {
            "Sid": "SSMStartSession",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ec2:eu-west-2:1234:instance/i-abc",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                },
                "ForAnyValue:StringEquals": {
                    "aws:CalledVia": "ssm-guiconnect.amazonaws.com"
                }
            }
        },
        {
            "Sid": "SSMSendCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:managed-instance/*",
                "arn:aws:ssm:*:*:document/AWSSSO-CreateSSOUser"
            ],
            "Condition": {
                "BoolIfExists": {
                    "ssm:SessionDocumentAccessCheck": "true"
                }
            }
        },
        {
            "Sid": "GuiConnect",
            "Effect": "Allow",
            "Action": [
                "ssm-guiconnect:CancelConnection",
                "ssm-guiconnect:GetConnection",
                "ssm-guiconnect:StartConnection"
            ],
            "Resource": "*"
        }
    ]
})
    }
  }

  # Flattening the list of permission sets and their managed policies
  permission_sets_with_policies = flatten([
    for ps_name, ps in local.permission_sets : [
      for policy_arn in flatten(ps.managed_policies) : {
        permission_set_name = ps_name
        managed_policy_arn  = policy_arn
      }
    ]
  ])
}
