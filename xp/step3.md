# Install AWS Provider

Crossplane uses Providers to interact with external APIs. We'll install the AWS Provider to manage AWS resources.

## Install the AWS Provider

Create a Provider resource:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.16.0
EOF
```{{exec}}

## Wait for Provider Installation

The Provider will be downloaded and installed. This may take a minute or two.

Watch the provider installation:

```bash
kubectl get providers
```{{exec}}

Wait until the provider shows as HEALTHY and INSTALLED:

```bash
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=300s
```{{exec}}

## Verify Provider Pods

Check that the provider pod is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should now see additional pods for the AWS S3 provider.

## Check Available Resources

See what resources the provider makes available:

```bash
kubectl get crds | grep aws
```{{exec}}

You should see Custom Resource Definitions (CRDs) for AWS S3 resources like buckets.
