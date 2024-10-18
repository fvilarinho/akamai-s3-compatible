#!/bin/bash

# Checks the dependencies of this script.
function checkDependencies() {
  export KUBECONFIG="$1"

  if [ -z "$KUBECONFIG" ]; then
    echo "The kubeconfig filename is not defined! Please define it first to continue!"

    exit 1
  fi

  export NAMESPACE="$2"

  if [ -z "$NAMESPACE" ]; then
    echo "The namespace is not defined! Please define it first to continue!"

    exit 1
  fi
}

# Fetches the stack hostname.
function fetchStackHostname() {
  checkDependencies "$1" "$2"

  HOSTNAME=

  # Waits until LKE cluster load balancer is ready.
  while true; do
    # Fetches the LKE cluster load balancer hostname.
    HOSTNAME=$($KUBECTL_CMD get service ingress \
                            -n "$NAMESPACE" \
                            -o json | $JQ_CMD -r '.status.loadBalancer.ingress[].hostname')

    if [ -n "$HOSTNAME" ]; then
      IP=$($KUBECTL_CMD get service ingress \
                        -n "$NAMESPACE" \
                        -o json | $JQ_CMD -r '.status.loadBalancer.ingress[].ip')

      if [ -n "$IP" ]; then
        break
      fi
    fi

    sleep 5
  done

  # Returns the fetched hostname.
  echo "{\"ip\": \"$IP\", \"hostname\": \"$HOSTNAME\"}"
}

fetchStackHostname "$1" "$2"