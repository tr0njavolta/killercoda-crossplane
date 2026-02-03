# Understand the Provider

A **Provider** in Crossplane is a plugin that enables management of specific cloud resources. The AWS provider allows you to manage S3 buckets, EC2 instances, RDS databases, and more.

## What is a Provider?

A Provider:
- Extends Crossplane with support for a specific cloud platform
- Defines custom resources (CRDs) for cloud resources
- Includes controllers that translate Kubernetes resources to cloud API calls
- Runs as pods in the `crossplane-system` namespace

## View the AWS Provider Installation

Check the Provider CRD:

```bash
kubectl get provider crossplane-provider-aws-s3 -o yaml | head -50
```{{exec}}

Key fields:
- **package**: The provider image location
- **status.conditions**: Health and readiness status

## Explore Available Resources

The AWS provider adds new resource types to your cluster. Check what S3 resources are available:

```bash
kubectl api-resources | grep s3
```{{exec}}

You should see resources like:
- `buckets` - S3 buckets
- Each with `s3.aws.upbound.io` as the API group

## Check the S3 CRD

View the Bucket resource definition:

```bash
kubectl get crd buckets.s3.aws.upbound.io -o yaml | head -100
```{{exec}}

Notice:
- **names.kind**: `Bucket` - the Kubernetes resource kind
- **names.singular**: `bucket` - singular form
- **scope**: `Cluster` - buckets are cluster-scoped
- **schema**: OpenAPI schema defining allowed fields

## Provider Controller

The AWS provider runs controllers that watch for Bucket resources. When you create a Bucket:

```bash
kubectl get pods -n crossplane-system | grep aws
```{{exec}}

The provider controller:
1. Detects the new Bucket resource
2. Extracts the AWS configuration
3. Calls the AWS API to create the actual bucket
4. Updates the resource status with results

## Provider Dependencies

Each provider may require specific controllers or supporting resources. Check all managed resource controllers:

```bash
kubectl get deployments -n crossplane-system
```{{exec}}

You should see both Crossplane and provider controllers running.

## What's Next?

Now that you understand what providers are, let's look at how provider configurations work in the next step.
