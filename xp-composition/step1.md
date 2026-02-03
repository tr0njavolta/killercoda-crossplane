# Verify the Installation

Everything has been pre-installed for you! Let's verify that Crossplane, the KCL function, and the CompositeResourceDefinition are all set up.

## Check Crossplane

Verify Crossplane is running:

```bash
kubectl get pods -n crossplane-system
```{{exec}}

## Check the KCL Function

Verify the KCL composition function is installed:

```bash
kubectl get functions
```{{exec}}

## Check the CompositeResourceDefinition

Verify the XRD for the `App` resource exists:

```bash
kubectl get xrd
```{{exec}}

View the XRD details:

```bash
kubectl get xrd apps.example.crossplane.io -o yaml
```{{exec}}

## Check the Composition

Verify the Composition with KCL was created:

```bash
kubectl get compositions
```{{exec}}

View the Composition:

```bash
kubectl get composition app-kcl -o yaml | head -80
```{{exec}}

## Check the Example App

Verify the example `App` resource was created:

```bash
kubectl get apps
```{{exec}}

## What Gets Created?

When an `App` is created, Crossplane automatically creates a Deployment and Service:

```bash
kubectl get deployment -l example.crossplane.io/app=my-app
```{{exec}}

```bash
kubectl get service -l example.crossplane.io/app=my-app
```{{exec}}

User creates a simple `App` → Crossplane runs KCL composition → Generates Deployment and Service. That's the power of composition!

In the next step, we'll explore how the XRD defines this custom API.
