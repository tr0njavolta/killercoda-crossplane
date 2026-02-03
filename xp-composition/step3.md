# Explore the KCL Composition

Now let's look at the KCL code that makes the composition work.

## View the Composition Resource

Get the Composition definition:

```bash
kubectl get composition app-kcl -o yaml
```{{exec}}

## Understanding the Composition Structure

Check the CompositeTypeRef (what it composes):

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.compositeTypeRef}'
```{{exec}}

Check the Mode (how it composes):

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.mode}'
```{{exec}}

`Pipeline` mode means composition functions are used.

Check the pipeline function:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].functionRef.name}'
```{{exec}}

## The KCL Source Code

View the KCL code:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].input.spec.source}' | head -50
```{{exec}}

The KCL code:
1. Gets the observed App resource (`oxr` = observed XR)
2. Creates a Deployment using `spec.image`
3. Creates a Service exposing the Deployment
4. Updates the App's status with replicas and cluster IP

## How KCL Accesses Runtime Data

KCL uses `option("params")` to access:
- **oxr**: The App resource the user created
- **ocds**: Composed resources (Deployment, Service)
- **dxr**: Desired state of the App

This lets KCL read user input and update status.

## Verify the KCL Logic

Check what got created from `my-app`:

```bash
kubectl get app my-app -o json | jq '.status'
```{{exec}}

## The Composition Pipeline

Complete flow:
1. User creates App with `spec.image`
2. Crossplane detects the new App
3. Calls the KCL function
4. KCL generates Deployment and Service manifests
5. Crossplane creates those resources
6. KCL updates App status

All automatic!

In the next step, we'll create more Apps.
