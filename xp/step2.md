# Create Your First S3 Bucket

Now let's create a managed resource - an S3 bucket in LocalStack!

## Review the Bucket Manifest

First, let's look at what we're about to create:

```bash
cat /root/s3-bucket.yaml
```{{exec}}

This manifest defines:
- **apiVersion**: The S3 API from the AWS provider
- **kind**: A Bucket resource
- **metadata.name**: The Kubernetes resource name
- **spec.forProvider.region**: The AWS region
- **spec.providerConfigRef**: Which ProviderConfig to use (pointing to LocalStack)

## Create the S3 Bucket

Apply the bucket manifest:

```bash
kubectl apply -f /root/s3-bucket.yaml
```{{exec}}

## Watch the Bucket Creation

Check the bucket status:

```bash
kubectl get buckets
```{{exec}}

Watch the bucket until it's ready (this usually takes 30-60 seconds):

```bash
kubectl get buckets -w
```{{exec}}

Press `Ctrl+C` once you see `READY=True` and `SYNCED=True`.

## Examine the Bucket

Get detailed information about the bucket:

```bash
kubectl describe bucket my-crossplane-bucket
```{{exec}}

Look at the Events section at the bottom - you'll see Crossplane:
1. Creating the external resource in LocalStack
2. Syncing the state
3. Marking it as Ready

## Verify in LocalStack

Let's confirm the bucket actually exists in LocalStack:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

You should see `my-crossplane-bucket` in the list!

🎉 Congratulations! You've created your first Crossplane managed resource. The bucket exists in LocalStack and is managed through Kubernetes.

In the next step, we'll explore how to modify and manage resources.
