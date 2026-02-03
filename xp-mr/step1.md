# Verify the Installation

Everything has been pre-installed for you! Let's verify that Crossplane, the AWS provider, and the credentials are all set up.

## Check Crossplane

Verify Crossplane is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

You should see:
- `crossplane-*` pod (main controller)
- `crossplane-rbac-manager-*` pod (RBAC manager)

## Check the AWS Provider

Verify the AWS provider is installed:

```bash
kubectl get providers
```{{exec}}

You should see `crossplane-provider-aws-s3` with `INSTALLED: True` and `HEALTHY: True`.

Get details about the AWS provider:

```bash
kubectl describe provider crossplane-provider-aws-s3
```{{exec}}

## Check the Provider Configuration

Verify the ProviderConfig was created:

```bash
kubectl get providerconfig
```{{exec}}

You should see `default`.

Look at the ProviderConfig details:

```bash
kubectl get providerconfig default -o yaml
```{{exec}}

Notice:
- **credentials.source**: `Secret` - credentials come from a Kubernetes secret
- **secretRef**: Points to the `aws-secret` in the `crossplane-system` namespace

## Check the AWS Credentials Secret

Verify the credentials secret exists:

```bash
kubectl get secret -n crossplane-system aws-secret
```{{exec}}

## Check the Example S3 Bucket

Verify the example S3 bucket resource was created:

```bash
kubectl get buckets
```{{exec}}

You should see `crossplane-demo-bucket` (SYNCED and READY might still be loading).

Look at the bucket details:

```bash
kubectl describe bucket crossplane-demo-bucket
```{{exec}}

Notice:
- **Ready**: Whether the resource is synced with AWS
- **Synced**: Whether Crossplane is tracking the AWS resource
- **External Name**: The actual AWS resource identifier

## What Gets Created?

When a Bucket is created, Crossplane:
1. Uses the AWS provider and ProviderConfig
2. Authenticates to AWS with the credentials
3. Creates the S3 bucket in the specified region
4. Tracks the bucket's status

This is the power of managed resources: define cloud infrastructure as Kubernetes YAML, and Crossplane handles provisioning!

In the next step, we'll explore how the AWS provider works.
