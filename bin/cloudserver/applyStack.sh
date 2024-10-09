#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$ACCESS_KEY" ]; then
    echo "The access key is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$SECRET_KEY" ]; then
    echo "The secret key is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STACK_HOSTNAME" ]; then
    echo "The stack hostname is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STACK_NAMESPACES_FILENAME" ]; then
    echo "The stack namespaces file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STACK_STORAGES_FILENAME" ]; then
    echo "The stack storages file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STACK_DEPLOYMENTS_FILENAME" ]; then
    echo "The stack deployments file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STACK_SERVICES_FILENAME" ]; then
    echo "The stack services file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STORAGE_DATA_SIZE" ]; then
    echo "The storage data size is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STORAGE_METADATA_SIZE" ]; then
    echo "The storage metadata size is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack namespaces replacing the placeholders with the correspondent environment variable value.
function applyStackNamespaces() {
  manifestFilename="$STACK_NAMESPACES_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack settings replacing the placeholders with the correspondent environment variable value.
function applyStackSettings() {
  $KUBECTL_CMD create configmap nginx-settings --from-file=../etc/nginx/conf.d/default.conf -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
  $KUBECTL_CMD create configmap nginx-tls-certificate --from-file=../etc/tls/certs/fullchain.pem -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
  $KUBECTL_CMD create configmap nginx-tls-certificate-key --from-file=../etc/tls/private/privkey.pem -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the stack storages replacing the placeholders with the correspondent environment variable value.
function applyStackStorages() {
  manifestFilename="$STACK_STORAGES_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_DATA_SIZE}|'"$STORAGE_DATA_SIZE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_METADATA_SIZE}|'"$STORAGE_METADATA_SIZE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack deployments replacing the placeholders with the correspondent environment variable value.
function applyStackDeployments() {
  manifestFilename="$STACK_DEPLOYMENTS_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${ACCESS_KEY}|'"$ACCESS_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${SECRET_KEY}|'"$SECRET_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STACK_HOSTNAME}|'"$STACK_HOSTNAME"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack services replacing the placeholders with the correspondent environment variable value.
function applyStackServices() {
  manifestFilename="$STACK_SERVICES_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack.
function applyStack() {
  applyStackNamespaces
  applyStackSettings
  applyStackStorages
  applyStackDeployments
  applyStackServices
}

# Main function.
function main() {
  checkDependencies
  applyStack
}

main