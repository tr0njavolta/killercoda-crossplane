# Create an S3 Bucket

Let's create our first managed resource: an S3 bucket!

## Create the S3 Bucket

Apply the bucket manifest:

```bash
kubectl apply -f s3-bucket.yaml
```{{exec}}

## Watch the Bucket Creation

Check the bucket status:

```bash
kubectl get buckets
```{{exec}}

Watch the bucket until it's ready (this may take 30-60 seconds):

```bash
kubectl get buckets -w
```{{exec}}

Press `Ctrl+C` to stop watching once you see `READY=True` and `SYNCED=True`.

## Examine the Bucket Details

Get detailed information about the bucket:

```bash
kubectl describe bucket my-crossplane-bucket
```{{exec}}

## Verify in LocalStack

Let's confirm the bucket was actually created in LocalStack:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

You should see `my-crossplane-bucket` in the list!

## Experiment: Update the Bucket

Try editing the bucket to add tags:

```bash
kubectl edit bucket my-crossplane-bucket
```{{exec}}

Crossplane will automatically synchronize your changes to LocalStack!

## Cleanup

When you're done, delete the bucket:

```bash
kubectl delete bucket my-crossplane-bucket
```{{exec}}

Crossplane will automatically remove the bucket from LocalStack. You can verify with another `aws s3 ls` command.
