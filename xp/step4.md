# Configure the AWS Provider

Now we need to configure the AWS Provider to use LocalStack instead of real AWS.

## Create AWS Credentials Secret

First, create a Kubernetes secret with dummy AWS credentials (LocalStack doesn't require real credentials):

```bash
kubectl create secret generic aws-creds \
  -n crossplane-system \
  --from-file=credentials=aws-credentials.txt
```{{exec}}

Verify the secret was created:

```bash
kubectl get secret aws-creds -n crossplane-system
```{{exec}}

## Create ProviderConfig

Apply the ProviderConfig that points to LocalStack:

```bash
kubectl apply -f provider-config.yaml
```{{exec}}

## Verify ProviderConfig

Check the ProviderConfig:

```bash
kubectl get providerconfigs
```{{exec}}

View the details:

```bash
kubectl describe providerconfig default
```{{exec}}

The ProviderConfig tells the AWS Provider to:
- Use our dummy credentials
- Point to LocalStack's endpoint (http://localstack:4566)
- Skip certificate verification (since LocalStack uses self-signed certs)
- Use us-east-1 as the default region

Now we're ready to create AWS resources!
