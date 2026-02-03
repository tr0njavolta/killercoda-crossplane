# Create Your First Managed Resource

Now you'll create an S3 bucket by simply declaring a Kubernetes resource. Crossplane will handle the AWS API calls.

## Check the Demo Bucket Status

The demo bucket was created during setup. Check its current status:

```bash
kubectl get bucket crossplane-demo-bucket
```{{exec}}

Fields:
- **READY**: Is the AWS resource ready?
- **SYNCED**: Is Crossplane synced with AWS?
- **EXTERNAL-NAME**: The actual AWS resource name

Get more details:

```bash
kubectl describe bucket crossplane-demo-bucket
```{{exec}}

## Create a New Bucket

Create your own S3 bucket in a different region:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-first-bucket
spec:
  forProvider:
    region: us-west-2
  providerConfigRef:
    name: default
EOF
```{{exec}}

## Monitor the Resource Creation

Watch the bucket creation progress:

```bash
kubectl get bucket my-first-bucket -o yaml
```{{exec}}

Look for:
- **status.conditions**: Shows resource health and readiness
- **status.observedGeneration**: Crossplane's tracking of changes
- **status.externalName**: AWS bucket name

Watch it in real-time:

```bash
kubectl get buckets --watch
```{{exec}}

(Press Ctrl+C to stop watching)

## Verify AWS Resource Creation

Once the bucket is ready, you could verify it in AWS (if credentials were real):

```bash
# This command shows what would happen with real AWS credentials:
echo "In a real AWS environment, run:"
echo "  aws s3 ls --region us-west-2"
echo ""
echo "You would see:"
echo "  2024-02-02 10:30:00 my-first-bucket"
```{{exec}}

## View All Managed Buckets

See all buckets managed by Crossplane:

```bash
kubectl get buckets
```{{exec}}

List with full details:

```bash
kubectl get buckets -o wide
```{{exec}}

## What Happened?

When you applied the bucket manifest:
1. Kubernetes accepted it as a valid resource
2. The AWS provider controller detected it
3. Crossplane extracted the `region: us-west-2` setting
4. Crossplane called the AWS S3 API to create the bucket
5. The resource status updated with the result
6. AWS created the actual S3 bucket

All from a simple YAML file! This is infrastructure-as-code.

In the next step, we'll update and clean up these resources.
