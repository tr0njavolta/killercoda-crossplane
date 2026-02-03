# Create and Use Your First App

Now let's leverage the power of Crossplane composition! Declare what you want using the custom `App` API.

## Review the Example App

Crossplane already created `my-app` during setup:

```bash
kubectl get app my-app -o yaml
```{{exec}}

## Create a New App

Create a Node.js app:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: nodejs-app
spec:
  image: node:18
EOF
```{{exec}}

Watch the status:

```bash
kubectl get app nodejs-app -w
```{{exec}}

Press `Ctrl+C` once you see `READY: True`.

## Check What Was Created

Crossplane automatically created a Deployment and Service:

```bash
kubectl get deployment -l example.crossplane.io/app=nodejs-app
```{{exec}}

```bash
kubectl get service -l example.crossplane.io/app=nodejs-app
```{{exec}}

## Check the App Status

View the App's status:

```bash
kubectl get app nodejs-app -o jsonpath='{.status}'
```{{exec}}

## Create Multiple Apps

Create a Python app:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: python-app
spec:
  image: python:3.11
EOF
```{{exec}}

Create a custom app:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: custom-app
spec:
  image: mycompany/myapp:v1.0
EOF
```{{exec}}

## List All Apps

See all your Apps:

```bash
kubectl get apps
```{{exec}}

View all Deployments and Services:

```bash
kubectl get deployments
```{{exec}}

```bash
kubectl get services
```{{exec}}

All created automatically!

## The Power of Abstraction

Without Composition: Deployment + Service + labels + port mapping (10+ lines per app)
With Composition: Just the image (3 lines)

The composition handles Deployment, Service, labels, ports, and status syncing—complex patterns become simple APIs.

In the next step, we'll modify Apps and explore reactive behavior.
