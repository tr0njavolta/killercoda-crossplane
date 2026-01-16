# Setup Kubernetes and Install Crossplane

First, let's wait for the Kubernetes cluster to be ready and then install Crossplane.

## Wait for Kubernetes

Wait for the cluster to be fully operational:

```bash
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```{{exec}}

## Install Crossplane using Helm

Add the Crossplane Helm repository:

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
```{{exec}}

Create a namespace for Crossplane:

```bash
kubectl create namespace crossplane-system
```{{exec}}

Install Crossplane:

```bash
helm install crossplane \
  --namespace crossplane-system \
  crossplane-stable/crossplane \
  --wait
```{{exec}}

## Verify Installation

Check that Crossplane pods are running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should see the crossplane and crossplane-rbac-manager pods in a Running state.

Check the Crossplane version:

```bash
kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```{{exec}}
