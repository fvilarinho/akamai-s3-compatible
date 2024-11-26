#!/bin/bash

# Check the dependencies of this script.
function checkDependencies() {
  if [ -z "$KUBECONFIG" ]; then
    echo "The cluster kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$NAMESPACE" ]; then
    echo "The cluster namespace is not defined! Please define it first to continue!"

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

  if [ -z "$REPLICAS" ]; then
    echo "The replicas count is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$REPLICAS_RANGE" ]; then
    echo "The replicas range is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$HOSTNAME" ]; then
    echo "The hostname is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$ADMIN_HOSTNAME" ]; then
    echo "The admin hostname is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$WEBHOOKS_HOSTNAME" ]; then
    echo "The webhooks hostname is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$DEPLOYMENTS_FILENAME" ]; then
    echo "The deployments file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$SERVICES_FILENAME" ]; then
    echo "The services file is not defined! Please define it first to continue!"

    exit 1
  fi

  if [ -z "$STORAGE_DATA_SIZE" ]; then
    echo "The storage data size is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Applies the stack namespaces replacing the placeholders with the correspondent environment variable value.
function applyStackNamespaces() {
  $KUBECTL_CMD create namespace "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
}

# Applies the stack settings replacing the placeholders with the correspondent environment variable value.
function applyStackSettings() {
  configFilename=../etc/nginx/conf.d/default.conf

  cp -f "$configFilename" "$configFilename".tmp

  sed -i -e 's|${HOSTNAME}|'"$HOSTNAME"'|g' "$configFilename".tmp
  sed -i -e 's|${ADMIN_HOSTNAME}|'"$ADMIN_HOSTNAME"'|g' "$configFilename".tmp
  sed -i -e 's|${WEBHOOKS_HOSTNAME}|'"$WEBHOOKS_HOSTNAME"'|g' "$configFilename".tmp

  $KUBECTL_CMD create configmap nginx-settings --from-file=default.conf="$configFilename".tmp -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
  $KUBECTL_CMD create configmap nginx-tls-certificate --from-file=../etc/tls/certs/fullchain.pem -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -
  $KUBECTL_CMD create configmap nginx-tls-certificate-key --from-file=../etc/tls/private/privkey.pem -n "$NAMESPACE" -o yaml --dry-run=client | $KUBECTL_CMD apply -f -

  rm -f "$configFilename".tmp*
}

# Applies the stack deployments replacing the placeholders with the correspondent environment variable value.
function applyStackDeployments() {
  manifestFilename="$DEPLOYMENTS_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${ACCESS_KEY}|'"$ACCESS_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${SECRET_KEY}|'"$SECRET_KEY"'|g' "$manifestFilename".tmp
  sed -i -e 's|${REPLICAS}|'"$REPLICAS"'|g' "$manifestFilename".tmp
  sed -i -e 's|${REPLICAS_RANGE}|'"$REPLICAS_RANGE"'|g' "$manifestFilename".tmp
  sed -i -e 's|${STORAGE_DATA_SIZE}|'"$STORAGE_DATA_SIZE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack services replacing the placeholders with the correspondent environment variable value.
function applyStackServices() {
  manifestFilename="$SERVICES_FILENAME"

  cp -f "$manifestFilename" "$manifestFilename".tmp
  sed -i -e 's|${NAMESPACE}|'"$NAMESPACE"'|g' "$manifestFilename".tmp

  $KUBECTL_CMD apply -f "$manifestFilename".tmp

  rm -f "$manifestFilename".tmp*
}

# Applies the stack manifests.
function applyStackManifests() {
  applyStackNamespaces
  applyStackSettings
  applyStackDeployments
  applyStackServices
}

# Main function.
function main() {
  checkDependencies
  applyStackManifests
}

main