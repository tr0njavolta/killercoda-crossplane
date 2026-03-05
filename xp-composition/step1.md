# Verify the Installation

Everything has been pre-installed. Let's confirm Crossplane, the KCL function, the XRD, and the Composition are all ready before we start.

## Check Crossplane

```bash
kubectl get pods -n crossplane-system
```{{exec}}

## Check the KCL Function

```bash
kubectl get functions
```{{exec}}

## Check the CompositeResourceDefinition

The XRD registers `kind: App` as a custom Kubernetes resource:

```bash
kubectl get xrd
```{{exec}}

## Check the Composition

The Composition contains the KCL code that generates resources when an App is created:

```bash
kubectl get compositions
```{{exec}}

All four should be present and healthy. In the next step, you'll see why composition exists by experiencing the problem it solves.
