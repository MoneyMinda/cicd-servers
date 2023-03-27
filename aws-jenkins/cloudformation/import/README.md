# Jenkins with AWS CloudFormation 

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

## CloudFormation Stacks
In this project, the stack that builds the networking resources and the virtual machines are separated for easy reading. CloudFormation currently provided two methods for cross-stack resource referencing:
1) Nested stacks where one stack is the parent and the other stack is the child stack.
2) Independent stacks with exported resources

### Nested stacks
In nested stacks, one stack is the parent and the other stack(s) are children stacks. The template storing the child stacks should be stored in an S3 location. The parent stack triggers the creation of child stack(s) and any resources within the parent stack that depend on resource(s) within the child stack will not attempt to be created until the creation of all the resources within the child stack(s) are completed. 

This method tightly couples the parent and child stack(s) and failures in the creation of resources within the parent stack (that are independent of the child stacks) will trigger rollback of the child stack(s) if rollback is permitted for the parent stack. The tick coupling between the parent and child stack means resources do not need to be exported and exposed to other resources within other stacks.

This option is implemented in `./nested_vms.yaml` and `./nested_networking.yaml`.

### Independent Stacks with exported resources
In this option, the networking and virtual machine stacks are created independently. The networking stack creates its resources and exports some resources for use by any other stack within the region. The virtual machine stack imports the resources exported by the networking stack for use within its own stack.

This option has the advantage of failures within a stack not affecting another stack. However, this decoupling means that the developer needs to create the stack that imports resources after the stack that exports resources. CloudFormation assumes that the imported resources already exists. Another point to note is that the names of exported resources need to be unique within the region, and exported resources are available to all stacks within the same region.

This option is implemented in `./vms.yaml` and `./networking.yaml`.

## Building the CloudFormation stack

Listed below are the parameters required for the creation of the stacks.

### Networking stack
The parameters below apply to `./networking.yaml` and `./nested_networking.yaml`.
- ProjectNameParam:
  Project name tag
- EnvParam:
  Environment tag
- ResourceRandom:
  Characters appended to resource name to differentiate the resources created in different stacks with the same template

### Virtual machine stack
The parameters below apply to `./vms.yaml` and `./nested_vms.yaml`.
- ProjectNameParam:
  Project name tag
- EnvParam:
  Environment tag
- ResourceRandom:
  Characters appended to resource name to differentiate the resources created in different stacks with the same template

The parameters below apply to `./nested_vms.yaml` only. 
- NetworkStackS3PathParam:
  S3 Path of file containing networking stack template

The parameters below apply to `./vms.yaml` only
- NetworkStackName:
  Name of networking stack with exported resources
- NetworkStackVpc:
  Name of exported Vpc in networking stack
- NetworkStackPublicSubnet1Id:
  Name of exported public subnet 1 id in networking stack
- NetworkStackPublicSubnet1Az:
  Name of exported public subnet 1 az in networking stack
- NetworkStackPrivateSubnet1Id:
  Name of exported private subnet 1 id in networking stack
- NetworkStackPrivateSubnet1Az:
  Name of exported private subnet 1 az in networking stack
