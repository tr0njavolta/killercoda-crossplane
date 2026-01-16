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

## Check Provider Configuration

View the ProviderConfig that connects to LocalStack:

```bash
kubectl get providerconfigs
```{{exec}}

You should see a `default` ProviderConfig.

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
