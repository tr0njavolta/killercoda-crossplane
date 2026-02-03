# Manage and Clean Up Resources

Now you'll update managed resources and learn how to safely delete them.

## Update a Bucket

Managed resources can be updated using kubectl. For example, add tags to your bucket:

```bash
kubectl patch bucket my-first-bucket --type merge -p '{"spec":{"forProvider":{"tags":{"Environment":"Development","Team":"Platform"}}}}'
```{{exec}}

Verify the update:

```bash
kubectl get bucket my-first-bucket -o yaml | grep -A5 tags
```{{exec}}

Watch the resource reconcile:

```bash
kubectl describe bucket my-first-bucket
```{{exec}}

The provider controller will:
1. Detect the change
2. Update the AWS resource
3. Update the resource status

## View Resource Details

Get comprehensive information about a managed resource:

```bash
kubectl get bucket my-first-bucket -o yaml
```{{exec}}

Key sections:
- **spec**: What you declared (desired state)
- **status**: Current state and conditions
- **metadata**: Kubernetes metadata

Check the bucket's events:

```bash
kubectl describe bucket my-first-bucket
```{{exec}}

Look for events showing creation, updates, and status changes.

## List All Managed Resources

See all S3 buckets:

```bash
kubectl get buckets
```{{exec}}

List with specific columns:

```bash
kubectl get buckets -o custom-columns=NAME:.metadata.name,REGION:.spec.forProvider.region,READY:.status.conditions[?(@.type=="Ready")].status
```{{exec}}

## Delete a Managed Resource

When you delete a Crossplane managed resource, it typically deletes the actual AWS resource (default behavior is deletion cascades to cloud resources).

Delete your custom bucket:

```bash
kubectl delete bucket my-first-bucket
```{{exec}}

Watch the deletion:

```bash
kubectl get buckets --watch
```{{exec}}

(Press Ctrl+C to stop)

## Understand Deletion Behavior

Crossplane has policies for resource deletion. Check the demo bucket:

```bash
kubectl get bucket crossplane-demo-bucket -o yaml | grep -A5 deletionPolicy
```{{exec}}

Deletion policies:
- **Delete** (default): AWS resource is deleted when Kubernetes resource is deleted
- **Orphan**: AWS resource is kept when Kubernetes resource is deleted

You can change the deletion policy to protect important resources:

```bash
kubectl patch bucket crossplane-demo-bucket --type merge -p '{"spec":{"deletionPolicy":"Orphan"}}'
```{{exec}}

Now if you delete the Kubernetes resource, the AWS bucket will remain.

## Final Cleanup

Delete all demo resources:

```bash
kubectl delete buckets --all
```{{exec}}

Check that they're gone:

```bash
kubectl get buckets
```{{exec}}

## Key Takeaways

With Crossplane managed resources you can:
- ✅ Declare cloud infrastructure as YAML
- ✅ Use kubectl to create, update, and delete cloud resources
- ✅ Track cloud resources as Kubernetes objects
- ✅ Integrate with Kubernetes workflows and GitOps
- ✅ Define permissions using RBAC
- ✅ Compose multiple resources with custom APIs

Managed resources are the foundation of infrastructure-as-code with Crossplane!
