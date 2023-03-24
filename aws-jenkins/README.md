# AWS Jenkins

This folder uses AWS CloudFormation and Terraform to build all the resources required to host a Jenkins server (with worker nodes) on the AWS cloud.

The following resources are built as part of the project:
- virtual private cloud
- public and private subnets
- route tables and routes
- security groups 
- ssh keys for EC2 virtual machines
- roles for EC2 virtual machines
- instance profiles for EC2 virtual machines
- EC2 launch templates 
- EC2 instance fleet

Within this folder, the following are built:
- [x] Jenkins server built using AWS Cloud Formation on AWS
- [ ] Jenkins server built using Terraform on AWS
