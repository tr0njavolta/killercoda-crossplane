# Verify Environment and Install Provider

Let's verify that Crossplane and LocalStack are running, then install the AWS S3 Provider.

## Check Crossplane

Verify Crossplane is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should see `crossplane` and `crossplane-rbac-manager` pods in Running state.

## Check LocalStack

Verify LocalStack is running:

```bash
kubectl get pods -l app=localstack
```{{exec}}

The LocalStack pod should show `STATUS: Running` and `READY: 1/1`.

## Install the AWS S3 Provider

Now let's install a Crossplane Provider. Providers extend Crossplane to manage external resources.

Create the Provider resource:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.14.0
EOF
```{{exec}}

## Watch Provider Installation

The provider will be downloaded and installed. This takes 1-2 minutes:

```bash
kubectl get providers
```{{exec}}

Watch it until you see `INSTALLED: True`:

```bash
kubectl get providers -w
```{{exec}}

Press `Ctrl+C` once installed.

Now wait for it to become healthy:

```bash
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=300s
```{{exec}}

## Verify Provider Pods

Check that the provider pod is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should now see an additional pod for `provider-aws-s3`.

Great! The provider is installed. Next, we'll configure it to use LocalStack.
