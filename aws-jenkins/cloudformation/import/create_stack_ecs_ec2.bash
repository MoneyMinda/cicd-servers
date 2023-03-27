#!/bin/bash

clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )"  &> /dev/null && pwd)"
STACK_RANDOM="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)"
RESOURCE_RANDOM="$(head /dev/urandom | tr -dc a-z0-9 | head -c5)"

echo "Script directory: $SCRIPT_DIR"
echo "Stack Random: $STACK_RANDOM"
echo "Resource Random: $RESOURCE_RANDOM"
cd "$SCRIPT_DIR" || exit
echo "Current working directory: $(pwd)"

echo "Execute script for secrets"
source "$SCRIPT_DIR/secrets.bash"
echo "Project name: $PROJECT_NAME"
echo "Passed to script:  $1"
PASSED_NETWORK_NAME="$1"
PASSED_PERIPHERALS_NAME="$2"
echo "Passed network name:  $PASSED_NETWORK_NAME"
echo "Passed peripherals name:  $PASSED_PERIPHERALS_NAME"


# ##################### Get Networking Stack Info
function set_networking_stack () {
  if [ -z "${PASSED_NETWORK_NAME}" ]; then

    # Begin networking stack creation
    echo -e "\n\n\nBegin networking stack creation"
    NETWORKING_STACK_NAME="$PROJECT_NAME-networking-$STACK_RANDOM"
    echo "Networking stack name: $NETWORKING_STACK_NAME"

    # Creating networking stack
    echo "Creating networking stack"
    aws cloudformation create-stack \
      --stack-name "$NETWORKING_STACK_NAME" \
      --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
      --template-body file://"$SCRIPT_DIR/networking.yaml" \
      --parameters file://"$SCRIPT_DIR/networking_params.json" \
      --stack-policy-body file://"$SCRIPT_DIR/networking_policy.json" \
      --region "$AWS_REGION"

    # Waiting for existence of networking stack
    echo "Waiting for creation of networking stack"
    aws cloudformation wait stack-create-complete \
      --stack-name "$NETWORKING_STACK_NAME" \
      --region "$AWS_REGION"
  else
    echo "\n\n\nNetworking stack exists"
    NETWORKING_STACK_NAME="${PASSED_NETWORK_NAME}"
    echo "Networking stack name: $NETWORKING_STACK_NAME"

#    # Updating networking stack
#    echo "Updating networking stack"
#    aws cloudformation update-stack \
#      --stack-name "$NETWORKING_STACK_NAME" \
#      --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
#      --template-body file://"$SCRIPT_DIR/networking.yaml" \
#      --parameters file://"$SCRIPT_DIR/networking_params.json" \
#      --stack-policy-body file://"$SCRIPT_DIR/networking_policy.json" \
#      --region "$AWS_REGION"
#
#    # Waiting for update of networking stack
#    echo "Waiting for update of networking stack"
#    aws cloudformation wait stack-update-complete \
#      --stack-name "$NETWORKING_STACK_NAME" \
#      --region "$AWS_REGION"
  fi
}


# ##################### Create Peripheral Stack
function set_peripheral_stack () {
  if [ -z "${PASSED_PERIPHERALS_NAME}" ]; then

    # Waiting for confirmation of existence of networking stack
    echo "Waiting for confirmation of existence of networking stack"
    aws cloudformation wait stack-exists \
      --stack-name "$NETWORKING_STACK_NAME" \
      --region "$AWS_REGION"

    # Begin peripheral stack creation
    echo -e "\n\n\nBegin peripheral stack creation"
    PERIPHERALS_STACK_NAME="$PROJECT_NAME-ecs-peripherals-$STACK_RANDOM"
    echo "Peripherals stack name: $PERIPHERALS_STACK_NAME"

    # Creating peripheral stack
    echo "Creating peripheral stack"
    aws cloudformation create-stack \
      --stack-name "$PERIPHERALS_STACK_NAME" \
      --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
      --template-body file://"$SCRIPT_DIR/ecs_peripherals.yaml" \
      --parameters file://"$SCRIPT_DIR/ecs_peripherals_params.json" \
      --stack-policy-body file://"$SCRIPT_DIR/ecs_peripherals_policy.json" \
      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
      --region "$AWS_REGION"

    # Waiting for creation of peripheral stack
    echo "Waiting for creation of peripheral stack"
    aws cloudformation wait stack-create-complete \
      --stack-name "$PERIPHERALS_STACK_NAME" \
      --region "$AWS_REGION"
  else
    echo "\n\n\nPeripheral stack exists"
    PERIPHERALS_STACK_NAME="${PASSED_PERIPHERALS_NAME}"
    echo "Peripheral stack name: $PERIPHERALS_STACK_NAME"

#    # Updating peripheral stack
#    echo "Updating peripheral stack"
#    aws cloudformation update-stack \
#      --stack-name "$PERIPHERALS_STACK_NAME" \
#      --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
#      --template-body file://"$SCRIPT_DIR/ecs_peripherals.yaml" \
#      --parameters file://"$SCRIPT_DIR/ecs_peripherals_params.json" \
#      --stack-policy-body file://"$SCRIPT_DIR/ecs_peripherals_policy.json" \
#      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
#      --region "$AWS_REGION"
#
#    # Waiting for creation of peripheral stack
#    echo "Waiting for update of peripheral stack"
#    aws cloudformation wait stack-update-complete \
#      --stack-name "$PERIPHERALS_STACK_NAME" \
#      --region "$AWS_REGION"
  fi
}


# ###################### Create peripheral stack if not exists
# Format parameterised file for stack parameters
echo "Format parameterised file for stack parameters for network stack"
cat "$SCRIPT_DIR/parameterised_networking_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  > "$SCRIPT_DIR/networking_params.json"

set_networking_stack



echo "Format parameterised file for stack parameters for peripherals stack"
cat "$SCRIPT_DIR/parameterised_ecs_peripherals_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  | sed "s/<network_stack_name>/$NETWORKING_STACK_NAME/g" \
  > "$SCRIPT_DIR/ecs_peripherals_params.json"

set_peripheral_stack



# Begin cluster stack creation
echo -e "\n\n\nBegin cluster stack creation"
CLUSTER_STACK_NAME="$PROJECT_NAME-ecs-ec2-$STACK_RANDOM"
echo "Cluster stack name: $CLUSTER_STACK_NAME"

echo "Format parameterised file for stack parameters for ecs ec2 cluster"
cat "$SCRIPT_DIR/parameterised_ecs_ec2_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  | sed "s/<network_stack_name>/$NETWORKING_STACK_NAME/g" \
  | sed "s/<ecs_peripherals_stack_name>/$PERIPHERALS_STACK_NAME/g" \
  > "$SCRIPT_DIR/ecs_ec2_params.json"

# Creating cluster
echo "Creating cluster"
aws cloudformation create-stack \
  --stack-name "$CLUSTER_STACK_NAME" \
  --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
  --template-body file://"$SCRIPT_DIR/ecs_ec2.yaml" \
  --parameters file://"$SCRIPT_DIR/ecs_ec2_params.json" \
  --stack-policy-body file://"$SCRIPT_DIR/ecs_ec2_policy.json" \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
  --region "$AWS_REGION"



