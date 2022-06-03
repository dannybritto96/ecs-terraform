# ecs-terraform
- Provisoning AWS VPC, Subnets, Security Groups, ECR Repository, ECS Cluster, ECS Task Definition, ECS Service and API Gateway with Terraform and GitHub Actions.
- Continuous Deployment to ECS with GitHub Actions.


## Arch

The ECS Service is fronted with an internal load balancer which is accesible only inside the VPC. An API Gateway accessible from the internet is deployed which acts as a proxy to the internal load balancer.

![architecture-diagram](https://github.com/dannybritto96/ecs-terraform/blob/31975018f6f2b718ff017467fd059e84a67b3e2c/ECS%20Arch.png)

## GitHub Actions

- [Terraform](.github/workflows/terraform.yml)
- [Deploy To ECS](.github/workflows/aws.yml)

## Setting up Tokens

### Terraform Cloud

- [Setting up Terraform Token with GitHub Actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- Terraform API token should be saved as TF_API_TOKEN in GitHub secrets.

### AWS Credentials

- AWS_ACCESS_KEY_ID and AWS_ACCESS_SECRET_TOKEN must be added to the GitHub secrets. Information on how to add secrets to GitHub [https://docs.github.com/en/actions/security-guides/encrypted-secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

