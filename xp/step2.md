# Deploy LocalStack

LocalStack will simulate AWS services locally, allowing us to test Crossplane without using real AWS resources.

## Deploy LocalStack

Apply the LocalStack deployment:

```bash
kubectl apply -f localstack-deployment.yaml
```{{exec}}

## Wait for LocalStack to be Ready

Wait for the LocalStack pod to be running:

```bash
kubectl wait --for=condition=Ready pod -l app=localstack --timeout=300s
```{{exec}}

## Verify LocalStack

Check the LocalStack pod status:

```bash
kubectl get pods -l app=localstack
```{{exec}}

Get the LocalStack service:

```bash
kubectl get svc localstack
```{{exec}}

## Test LocalStack Connection

Let's verify LocalStack is accessible:

```bash
kubectl run aws-cli --rm -it --restart=Never --image=amazon/aws-cli --command -- \
  aws --endpoint-url=http://localstack:4566 s3 ls
```{{exec}}

If you see an empty list or a connection success, LocalStack is working correctly! The command will automatically clean up after execution.
