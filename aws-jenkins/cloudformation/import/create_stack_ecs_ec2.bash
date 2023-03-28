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
NETWORKING_STACK_NAME="$1"
PERIPHERALS_STACK_NAME="$2"
CLUSTER_STACK_NAME="$3"
echo "Passed network name:  $NETWORKING_STACK_NAME"
echo "Passed peripherals name:  $PERIPHERALS_STACK_NAME"
echo "Passed cluster name:  $CLUSTER_STACK_NAME"


# ##################### Create Networking Stack
function create_networking_stack () {
  CURRENT_STACK="Network"
  echo -e "\n\n\nBegin $CURRENT_STACK stack creation"

  NETWORKING_STACK_NAME="$PROJECT_NAME-networking-$STACK_RANDOM"
  echo "$CURRENT_STACK stack name: $NETWORKING_STACK_NAME"

  echo "Creating $CURRENT_STACK stack"
  aws cloudformation create-stack \
    --stack-name "$NETWORKING_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/networking.yaml" \
    --parameters file://"$SCRIPT_DIR/networking_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/networking_policy.json" \
    --region "$AWS_REGION"

  echo "Waiting for creation of $CURRENT_STACK stack"
  aws cloudformation wait stack-create-complete \
    --stack-name "$NETWORKING_STACK_NAME" \
    --region "$AWS_REGION"
}

# ##################### Update Networking stack
function update_networking_stack () {
  CURRENT_STACK="Network"
  echo -e "\n\n\n$CURRENT_STACK stack exists"
  echo "$CURRENT_STACK stack name: $NETWORKING_STACK_NAME"

  echo "Updating $CURRENT_STACK stack"
  aws cloudformation update-stack \
    --stack-name "$NETWORKING_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/networking.yaml" \
    --parameters file://"$SCRIPT_DIR/networking_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/networking_policy.json" \
    --region "$AWS_REGION"

  echo "Waiting for update of $CURRENT_STACK stack"
  aws cloudformation wait stack-update-complete \
    --stack-name "$NETWORKING_STACK_NAME" \
    --region "$AWS_REGION"
}

# ##################### Create Peripheral Stack
function create_peripheral_stack () {
  CURRENT_STACK="Peripheral"

  echo "Waiting for confirmation of existence of networking stack"
  aws cloudformation wait stack-exists \
    --stack-name "$NETWORKING_STACK_NAME" \
    --region "$AWS_REGION"
  echo "Existence of networking stack is confirmed"

  echo -e "\n\n\nBegin peripheral stack creation"
  PERIPHERALS_STACK_NAME="$PROJECT_NAME-ecs-peripherals-$STACK_RANDOM"
  echo "Peripherals stack name: $PERIPHERALS_STACK_NAME"

  echo "Creating $CURRENT_STACK stack"
  aws cloudformation create-stack \
    --stack-name "$PERIPHERALS_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/ecs_peripherals.yaml" \
    --parameters file://"$SCRIPT_DIR/ecs_peripherals_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/ecs_peripherals_policy.json" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$AWS_REGION"

  echo "Waiting for creation of $CURRENT_STACK stack"
  aws cloudformation wait stack-create-complete \
    --stack-name "$PERIPHERALS_STACK_NAME" \
    --region "$AWS_REGION"
}

# ##################### Update Peripheral Stack
function update_peripheral_stack () {
  CURRENT_STACK="Peripheral"
  echo -e "\n\n\n$CURRENT_STACK stack exists"
  echo "$CURRENT_STACK stack name: $PERIPHERALS_STACK_NAME"

  echo "Updating $CURRENT_STACK stack"
  aws cloudformation update-stack \
    --stack-name "$PERIPHERALS_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/ecs_peripherals.yaml" \
    --parameters file://"$SCRIPT_DIR/ecs_peripherals_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/ecs_peripherals_policy.json" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$AWS_REGION"

  echo "Waiting for update of $CURRENT_STACK stack"
  aws cloudformation wait stack-update-complete \
    --stack-name "$PERIPHERALS_STACK_NAME" \
    --region "$AWS_REGION"
}

# ##################### Create Cluster Stack
function create_cluster_stack () {
  CURRENT_STACK="Cluster"

  echo "Waiting for confirmation of existence of networking stack"
  aws cloudformation wait stack-exists \
    --stack-name "$NETWORKING_STACK_NAME" \
    --region "$AWS_REGION"

  echo "Waiting for confirmation of existence of peripherals stack"
  aws cloudformation wait stack-exists \
    --stack-name "$PERIPHERALS_STACK_NAME" \
    --region "$AWS_REGION"

  echo -e "\n\n\nBegin cluster stack creation"
  CLUSTER_STACK_NAME="$PROJECT_NAME-ecs-ec2-$STACK_RANDOM"
  echo "Cluster stack name: $CLUSTER_STACK_NAME"

  echo "Creating $CURRENT_STACK stack"
  aws cloudformation create-stack \
    --stack-name "$CLUSTER_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/ecs_ec2.yaml" \
    --parameters file://"$SCRIPT_DIR/ecs_ec2_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/ecs_ec2_policy.json" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$AWS_REGION"
}

# ##################### Update Cluster Stack
function update_cluster_stack () {
  CURRENT_STACK="Cluster"

  echo -e "\n\n\n$CURRENT_STACK stack exists"
  echo "Cluster stack name: $CLUSTER_STACK_NAME"

  echo "Updating $CURRENT_STACK stack"
  aws cloudformation update-stack \
    --stack-name "$CLUSTER_STACK_NAME" \
    --role-arn "$AWS_CLOUDFORMATION_ROLE_ARN" \
    --template-body file://"$SCRIPT_DIR/ecs_ec2.yaml" \
    --parameters file://"$SCRIPT_DIR/ecs_ec2_params.json" \
    --stack-policy-body file://"$SCRIPT_DIR/ecs_ec2_policy.json" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region "$AWS_REGION"

  echo "Waiting for update of $CURRENT_STACK stack"
  aws cloudformation wait stack-update-complete \
    --stack-name "$CLUSTER_STACK_NAME" \
    --region "$AWS_REGION"
}


# ###################### Create network stack if not exists
# Format parameterised file for stack parameters
echo "Format parameterised file for stack parameters for network stack"
cat "$SCRIPT_DIR/parameterised_networking_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  > "$SCRIPT_DIR/networking_params.json"
if [ -z "${NETWORKING_STACK_NAME}" ]; then
  echo -e "\n\nIn the if branch of: $NETWORKING_STACK_NAME"
  create_networking_stack
else
  echo -e "\n\nIn the else branch of: $NETWORKING_STACK_NAME"
#  update_networking_stack
fi


# ###################### Create peripheral stack if not exists
echo "Format parameterised file for stack parameters for peripherals stack"
cat "$SCRIPT_DIR/parameterised_ecs_peripherals_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  | sed "s/<network_stack_name>/$NETWORKING_STACK_NAME/g" \
  > "$SCRIPT_DIR/ecs_peripherals_params.json"
if [ -z "${PERIPHERALS_STACK_NAME}" ]; then
  echo -e "\n\nIn the if branch of: $PERIPHERALS_STACK_NAME"
  create_peripheral_stack
else
  echo -e "\n\nIn the else branch of: $PERIPHERALS_STACK_NAME"
#  update_peripheral_stack
fi


# ###################### Create cluster stack if not exists
echo "Format parameterised file for stack parameters for ecs ec2 cluster"
cat "$SCRIPT_DIR/parameterised_ecs_ec2_params.json"  \
  | sed "s/<project_name>/$PROJECT_NAME/g"  \
  | sed "s/<resource_random>/$RESOURCE_RANDOM/g" \
  | sed "s/<network_stack_name>/$NETWORKING_STACK_NAME/g" \
  | sed "s/<ecs_peripherals_stack_name>/$PERIPHERALS_STACK_NAME/g" \
  > "$SCRIPT_DIR/ecs_ec2_params.json"
if [ -z "${CLUSTER_STACK_NAME}" ]; then
  echo -e "\n\nIn the if branch of: $CLUSTER_STACK_NAME"
  create_cluster_stack
else
  echo -e "\n\nIn the else branch of: $CLUSTER_STACK_NAME"
  update_cluster_stack
fi





