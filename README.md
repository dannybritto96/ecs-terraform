# ecs-terraform
- Provisoning AWS VPC, Subnets, Security Groups, ECR Repository, ECS Cluster, ECS Task Definition, ECS Service and API Gateway with Terraform and GitHub Actions.
- Continuous Deployment to ECS with GitHub Actions.


## Arch

![architecture-diagram](https://github.com/dannybritto96/ecs-terraform/blob/31975018f6f2b718ff017467fd059e84a67b3e2c/ECS%20Arch.png)

## GitHub Actions

- [Terraform](.github/workflows/terraform.yml)
- [Deploy To ECS](.github/workflows/aws.yml)

## Setting up Tokens

### Terraform Cloud

- [Setting up Terraform Token with GitHub Actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- Terraform API token should be saved as TF_API_TOKEN in GitHub secrets.

### AWS Credentials

- AWS_ACCESS_KEY_ID and AWS_ACCESS_SECRET_TOKEN must be added to the GitHub secrets. Information on how to add secrets to GitHub [https://learn.hashicorp.com/tutorials/terraform/github-actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)

