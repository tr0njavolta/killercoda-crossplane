# Understand the CompositeResourceDefinition

`kind: App` isn't a built-in Kubernetes resource. It was registered by a CompositeResourceDefinition (XRD), which creates a new custom API.

## View the XRD

```bash
kubectl get xrd apps.example.crossplane.io -o yaml
```{{exec}}

## What the XRD Defines

The API group — what goes in `apiVersion`:

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.group}'
```{{exec}}

The input schema — what users can put in `spec`:

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec}' | jq .
```{{exec}}

The output schema — what gets written back to `status`:

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.status}' | jq .
```{{exec}}

## The XRD is the API Contract

The XRD does three things:
1. **Registers** `kind: App` as a valid Kubernetes resource
2. **Validates** input — Kubernetes rejects Apps with missing or wrong fields
3. **Defines status** — what information gets surfaced back to the user

In the next step, you'll see the KCL code that takes `spec.image` and generates the full Deployment and Service you saw in step 2.
