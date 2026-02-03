# Understand the CompositeResourceDefinition

The CompositeResourceDefinition (XRD) is the schema that defines your custom Kubernetes API.

## View the Full XRD

Get the complete XRD definition:

```bash
kubectl get xrd apps.example.crossplane.io -o yaml
```{{exec}}

## Understanding the Schema

Check the API group:

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.group}'
```{{exec}}

The API group is `example.crossplane.io`, so resources use `apiVersion: example.crossplane.io/v1` and `kind: App`.

Check the input schema (spec):

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec}'
```{{exec}}

Check the output schema (status):

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.status}'
```{{exec}}

## Create and Test an App

Let's create a new App:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: test-app
spec:
  image: nginx:1.21
EOF
```{{exec}}

Check what was created:

```bash
kubectl get app test-app -o yaml
```{{exec}}

```bash
kubectl get deployment -l example.crossplane.io/app=test-app
```{{exec}}

```bash
kubectl get service -l example.crossplane.io/app=test-app
```{{exec}}

The composition receives `spec.image`, runs KCL, and generates Deployment + Service + status updates.

## Cleanup

Delete the test app:

```bash
kubectl delete app test-app
```{{exec}}

Deleting the App automatically deletes all composed resources!

In the next step, we'll dive into the KCL code that makes this work.
