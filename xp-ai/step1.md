# Verify the Setup

Confirm Crossplane and the platform APIs are ready.

## Crossplane

```bash
kubectl get pods -n crossplane-system
```{{exec}}

## KCL Function

```bash
kubectl get functions
```{{exec}}

## The Infrastructure API

```bash
kubectl get xrd
```{{exec}}

```bash
kubectl get compositions
```{{exec}}

All four should be present and healthy.

In the next step, you'll see exactly what the AI agent sees: the API contract.
