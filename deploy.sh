#!/bin/bash

# Checks the dependencies to run this scripts.
function checkDependencies() {
  if [ -z "$TERRAFORM_CMD" ]; then
    echo "terraform is not installed! Please install it first to continue!"

    exit 1
  fi

  if [ -z "$KUBECTL_CMD" ]; then
    echo "kubectl is not installed! Please install it first to continue!"

    exit 1
  fi

  if [ -z "$CERTBOT_CMD" ]; then
    echo "certbot is not installed! Please install it first to continue!"

    exit 1
  fi

  if [ -z "$JQ_CMD" ]; then
    echo "jq is not installed! Please install it first to continue!"

    exit 1
  fi
}

# Prepares the environment to execute this script.
function prepareToExecute() {
  source functions.sh

  showBanner

  cd iac || exit 1
}

# Deploys the infrastructure based on the IaC files.
function deploy() {
  # Initializes Terraform providers and state.
  $TERRAFORM_CMD init \
                 -upgrade \
                 -migrate-state || exit 1

  # Plans/Validates the provisioning.
  $TERRAFORM_CMD plan -out /tmp/akamai-s3-compatible.plan || exit 1

  # Applies the provisioning based on the plan.
  $TERRAFORM_CMD apply \
                 -auto-approve \
                 /tmp/akamai-s3-compatible.plan
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  deploy
}

main