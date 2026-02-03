# Explore the Provider Configuration

A **ProviderConfig** tells the provider how to authenticate and connect to your cloud account. It's the bridge between Crossplane and AWS.

## What is a ProviderConfig?

A ProviderConfig:
- Stores authentication credentials securely
- Defines which AWS account and region to use
- Can specify IAM roles, endpoint URLs, and other configuration
- Is referenced by managed resources to know which account to use

## Check the Existing ProviderConfig

View the default ProviderConfig:

```bash
kubectl get providerconfig default -o yaml
```{{exec}}

Key fields:
- **credentials.source**: How credentials are provided (Secret, InjectedIdentity, etc.)
- **secretRef**: Reference to the secret containing credentials
- **region**: Default AWS region (can be overridden per resource)

## Understand the Credentials Secret

The ProviderConfig references a Kubernetes secret for credentials. View it:

```bash
kubectl get secret -n crossplane-system aws-secret -o yaml
```{{exec}}

The secret contains:
- **data.creds**: Base64-encoded AWS credentials in INI format

Decode and view the credentials format:

```bash
kubectl get secret -n crossplane-system aws-secret -o jsonpath='{.data.creds}' | base64 -d
```{{exec}}

## How Resources Use the ProviderConfig

When a Bucket is created, it specifies which ProviderConfig to use:

```bash
kubectl get bucket crossplane-demo-bucket -o yaml | grep -A5 providerConfigRef
```{{exec}}

The resource will have:
```yaml
spec:
  providerConfigRef:
    name: default
```

This tells Crossplane: "Use the credentials and settings from the 'default' ProviderConfig."

## Create a Custom ProviderConfig

You can create additional ProviderConfigs for different AWS accounts or regions:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: us-west-2
spec:
  region: us-west-2
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF
```{{exec}}

Verify it was created:

```bash
kubectl get providerconfig
```{{exec}}

Now you can create buckets in different regions by changing the `providerConfigRef.name`.

## Security Considerations

Best practices:
- Credentials should be stored in secure secret management (AWS Secrets Manager, Vault, etc.)
- Use IAM roles instead of static credentials when possible
- Restrict provider controllers to specific namespaces
- Enable RBAC to control who can create managed resources

Next, we'll create and manage your own S3 buckets using managed resources!
