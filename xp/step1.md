# Verify the Environment

Everything has been pre-installed for you! Let's verify that Crossplane, LocalStack, and the AWS Provider are all running.

## Check Crossplane

Verify Crossplane is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should see the `crossplane` and `crossplane-rbac-manager` pods, plus the AWS provider pod (starting with `provider-aws-s3`).

Check the Crossplane version:

```bash
kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```{{exec}}

## Check LocalStack

Verify LocalStack is running:

```bash
kubectl get pods -l app=localstack
```{{exec}}

The LocalStack pod should show `STATUS: Running` and `READY: 1/1`.

## Check AWS Provider

Verify the AWS S3 Provider is installed and healthy:

```bash
kubectl get providers
```{{exec}}

You should see `provider-aws-s3` with `INSTALLED: True` and `HEALTHY: True`.

**Troubleshooting**: If no providers are found, the installation may have failed. Check the logs:

```bash
kubectl logs -n crossplane-system -l app.kubernetes.io/name=crossplane --tail=50
```{{exec}}

Try installing the provider manually:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.18.0
EOF
```{{exec}}

Wait for it to install:

```bash
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=300s
```{{exec}}

## Check Provider Configuration

View the ProviderConfig that connects to LocalStack:

```bash
kubectl get providerconfig
```{{exec}}

You should see a `default` ProviderConfig. Let's look at its details:

```bash
kubectl describe providerconfig default
```{{exec}}

**Note**: If the ProviderConfig is not found, it may still be processing. First verify the CRD exists:

```bash
kubectl get crd | grep providerconfig
```{{exec}}

If you see `providerconfigs.aws.upbound.io`, then you can recreate the config:

```bash
kubectl apply -f /root/provider-config.yaml
```{{exec}}

Then wait a moment and check again:

```bash
kubectl get providerconfig
```{{exec}}

If the CRD doesn't exist, the provider may not be fully installed yet. Go back and check the provider status.

## Test LocalStack Connection

Let's verify we can communicate with LocalStack:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

You should see an empty list (no buckets yet) or a connection success. This confirms LocalStack is accessible!

## Available Resources

See what S3 resources you can create:

```bash
kubectl get crds | grep s3.aws
```{{exec}}

You'll see several S3-related Custom Resource Definitions, including `buckets.s3.aws.upbound.io`.

Everything is ready! Let's create some resources in the next step.
