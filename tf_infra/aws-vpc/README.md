# AWS VPC

There have two directories, name with `production` & `staging` for VPCs. 

There is a public and private subnet created per availability zone in addition to single NAT Gateway shared between all 3 availability zones.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```
## Creating the VPC

To create the VPC, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

* Apply Terraform configuration:
```bash
cd staging <or> production
terraform init
terraform plan
terraform apply 
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
This terraform configuration creates:


## Configuration

| Name | Description |
|------|-------------|
| azs | A list of availability zones spefified as argument to this module |
| nat\_public\_ips | List of public Elastic IPs created for AWS NAT Gateway |
| vpc_name | Name of the VPC which should have created |
| private\_subnets | List of IDs of private subnets |
| public\_subnets | List of IDs of public subnets |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_id | The ID of the VPC |
| tags | Tags which should be applied to all resources |

## Deleting the VPC

To delete the VPC, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Destroy Terraform configuration:
```bash
terraform destroy 
```
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
