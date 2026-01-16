# Explore and Modify Resources

Let's explore how Crossplane manages resources and try making some changes.

## View Resource Status

Get a summary of your bucket:

```bash
kubectl get bucket my-crossplane-bucket
```{{exec}}

Get the full resource definition in YAML:

```bash
kubectl get bucket my-crossplane-bucket -o yaml
```{{exec}}

Notice the `status` section - Crossplane adds this to track the external resource state.

## Add Tags to the Bucket

Let's modify the bucket to add some tags. Open the editor:

```bash
kubectl edit bucket my-crossplane-bucket
```{{exec}}

Find the `spec.forProvider` section and add tags under it (maintain proper YAML indentation):

```yaml
spec:
  forProvider:
    region: us-east-1
    tags:
      environment: demo
      managed-by: crossplane
```

Save and exit (`:wq` in vim).

## Watch Crossplane Sync the Change

Crossplane will detect the change and update LocalStack automatically:

```bash
kubectl describe bucket my-crossplane-bucket
```{{exec}}

Look at the Events - you should see Crossplane updating the external resource.

## Create a Second Bucket

Let's create another bucket using kubectl directly:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-second-bucket
spec:
  forProvider:
    region: us-west-2
  providerConfigRef:
    name: default
EOF
```{{exec}}

## List All Buckets

View all buckets managed by Crossplane:

```bash
kubectl get buckets
```{{exec}}

Verify both buckets exist in LocalStack:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

## Understanding Resource Lifecycle

When you delete a Crossplane resource, it also deletes the external resource. Let's try it:

```bash
kubectl delete bucket my-second-bucket
```{{exec}}

Watch as Crossplane deletes the bucket from LocalStack:

```bash
kubectl get buckets -w
```{{exec}}

Press `Ctrl+C` after the bucket is gone.

Verify it's removed from LocalStack:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --env="AWS_ACCESS_KEY_ID=test" --env="AWS_SECRET_ACCESS_KEY=test" --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

## Cleanup (Optional)

If you want to clean up your first bucket:

```bash
kubectl delete bucket my-crossplane-bucket
```{{exec}}

## Key Concepts

You've learned:
- **Declarative Management**: Describe desired state, Crossplane makes it happen
- **Drift Detection**: Crossplane continuously syncs Kubernetes state with external resources
- **Lifecycle Management**: Creating/updating/deleting Kubernetes resources manages external infrastructure
- **GitOps Ready**: All resources are defined as YAML, perfect for version control

Great job! Check out the finish page for next steps.
