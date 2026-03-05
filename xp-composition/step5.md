# Reactive Composition

Every change to an App re-runs the KCL pipeline and updates all composed resources automatically.

## Update the Image

Change the image on `my-app`:

```bash
kubectl patch app my-app --type merge -p '{"spec":{"image":"nginx:1.25"}}'
```{{exec}}

Crossplane immediately re-runs the KCL pipeline. Check the Deployment picked up the new image:

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```{{exec}}

## Create More Apps

Each App gets its own independent Deployment and Service:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: second-app
spec:
  image: httpd:latest
EOF
```{{exec}}

```bash
kubectl get apps
```{{exec}}

```bash
kubectl get deployments,services
```{{exec}}

## Delete an App

```bash
kubectl delete app second-app
```{{exec}}

All composed resources are cleaned up automatically:

```bash
kubectl get deployments,services
```{{exec}}

## The Full Picture

```
User applies App (3 lines)
        ↓
Crossplane detects change
        ↓
KCL function runs
        ↓
Generates Deployment + Service
        ↓
Status written back to App
```

Platform teams encode the complexity once in KCL. Everyone else gets a simple, validated API.
