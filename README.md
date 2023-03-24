# CICD

This project uses different infrastructure as code (IaC) tools provided by the major cloud service provides (AWS, GCP, Azure) to build all the resources required to host different open source continuous integration and continuous deployment (CI/CD) tools.

The following resources are built as part of the project:
- virtual private cloud
- public and private subnets
- route tables and routes
- security groups (AWS)
- ssh keys for virtual machines
- roles for virtual machines
- instance profiles for virtual machines (AWS)
- virtual machine fleet
- launch templates (AWS)

This project aims to build the following CI/CD tools:
- [x] Jenkins server built using AWS Cloud Formation on AWS
- [ ] Jenkins server built using Terraform on AWS
- [ ] Jenkins server built using Deployment Manager on Google Cloud
- [ ] Jenkins server built using Terraform on Google Cloud
- [ ] Jenkins server built using Azure Resource Manager on Azure
- [ ] Jenkins server built using Terraform on Azure
