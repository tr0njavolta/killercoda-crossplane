# Explore the KCL Composition

The Composition contains the KCL code responsible for generating the Deployment and Service you saw in step 2.

## View the Composition

```bash
kubectl get composition app-kcl -o yaml
```{{exec}}

## How It's Wired

The Composition references which XRD it implements:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.compositeTypeRef}'
```{{exec}}

It uses `Pipeline` mode, calling functions in sequence:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.mode}'
```{{exec}}

The function it calls is the KCL runner:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].functionRef.name}'
```{{exec}}

## The KCL Source

This is the code that generated the Deployment and Service:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].input.spec.source}'
```{{exec}}

The KCL code:
1. Reads `oxr` (the observed App resource) to get `spec.image`
2. Constructs a full Deployment manifest with correct labels, selectors, and ports
3. Constructs a matching Service manifest
4. Writes replica count and cluster IP back to the App's `status`

In the next step, you'll see the composition react to changes in real time.
