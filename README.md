# Terraform AWS Infrastructure

This repository contains Terraform configurations to deploy and manage AWS infrastructure, integrated with GitHub Actions for CI/CD.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [AWS IAM Setup](#aws-iam-setup)
- [GitHub Repository Secrets](#github-repository-secrets)
- [Terraform Configuration Files](#terraform-configuration-files)
- [CI/CD Workflow](#ci/cd-workflow)
- [Usage](#usage)

## Project Overview

This project uses Terraform to define and provision AWS resources. The infrastructure as code (IaC) is managed through a GitHub Actions CI/CD pipeline, ensuring automated checks, planning, and application of changes.

## Prerequisites

Before you begin, ensure you have the following:

- An AWS Account.
- AWS CLI configured with appropriate permissions.
- Terraform CLI installed (version >= 1.0).
- A GitHub repository to host this code.

## AWS IAM Setup

This setup requires an IAM role and an OpenID Connect (OIDC) provider in AWS to allow GitHub Actions to assume a role and deploy resources securely.

1.  **IAM Role (`GithubActionsRole`)**: This role grants GitHub Actions the necessary permissions to manage AWS resources. It includes policies for EC2, Route53, S3, IAM, VPC, SQS, and EventBridge, along with an inline policy for DynamoDB state locking.

    The trust policy for this role allows `token.actions.githubusercontent.com` to assume it, with a condition that the `sub` claim matches your GitHub repository.

2.  **IAM OIDC Provider**: Configured to trust `https://token.actions.githubusercontent.com`.

    These resources are defined in `iam.tf` and are provisioned as part of the Terraform apply process.

## GitHub Repository Secrets

For the GitHub Actions workflow to authenticate with AWS, you need to add your AWS Account ID as a repository secret.

1.  Go to your GitHub repository settings.
2.  Navigate to `Secrets and variables` -> `Actions`.
3.  Click on `New repository secret`.
4.  Name the secret `AWS_ACCOUNT_ID` and paste your 12-digit AWS account ID as the value.

## Terraform Configuration Files

The Terraform configuration is organized into several files:

- `main.tf`: Defines the required Terraform version.
- `variables.tf`: Contains variable definitions, such as `github_repository`.
- `providers.tf`: Configures the AWS provider.
- `backend.tf`: Configures the S3 backend for Terraform state management and DynamoDB for state locking.
- `data.tf`: Defines data sources, including current AWS caller identity and region.
- `iam.tf`: Contains the AWS IAM role and OIDC provider resources for GitHub Actions.

## CI/CD Workflow

The CI/CD pipeline is defined in `.github/workflows/terraform.yml` and consists of the following jobs:

- **`terraform-check`**: Runs `terraform fmt -check -recursive` to ensure code formatting compliance.
- **`terraform-plan`**: Initializes Terraform and generates an execution plan. This job requires the `terraform-check` to pass.
- **`terraform-apply`**: Applies the Terraform changes. This job runs only on `push` events to the `main` branch, after `terraform-plan` has succeeded, and requires manual approval if configured.

There is also a reusable composite action located at `.github/actions/setup-terraform/action.yml` that encapsulates common setup steps (checkout, AWS credentials configuration, and Terraform CLI setup) to reduce redundancy in the workflow.

## Usage

### Initial Setup (Manual, One-time)

1.  **Clone the repository**:
    ```bash
    git clone <your-repository-url>
    cd <your-repository-name>
    ```
2.  **Initialize Terraform**: This will download the necessary providers and set up the S3 backend. Make sure your AWS CLI is configured.
    ```bash
    terraform init
    ```
3.  **Apply Initial IAM Resources**: The `iam.tf` file contains the IAM role and OIDC provider that GitHub Actions will use. You might need to apply this initially outside the CI/CD pipeline if you don't have a pre-existing setup that creates these.
    ```bash
    terraform apply -target=aws_iam_role.github_actions -target=aws_iam_openid_connect_provider.github_actions
    # Or, if applying everything for the first time:
    # terraform apply
    ```

### Development Workflow (via GitHub Actions)

1.  **Make changes**: Modify your Terraform `.tf` files as needed.
2.  **Commit and Push**: Push your changes to a branch. A pull request will trigger the `terraform-check` and `terraform-plan` jobs.
3.  **Create a Pull Request (Optional but Recommended)**: Opening a pull request will run the `terraform-check` and `terraform-plan` jobs, showing you the proposed infrastructure changes before merging.
4.  **Merge to `main`**: Pushing or merging changes to the `main` branch will trigger the `terraform-apply` job, which will automatically apply your infrastructure changes to AWS (given all previous checks pass).
