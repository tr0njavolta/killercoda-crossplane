# What the API Enforces

The agent only specified a name and image. Everything else was enforced by the Composition — and the model had no way to override it.

## What Got Created

```bash
kubectl get deployments,services
```{{exec}}

## Enforced Labels

Every resource carries consistent labels the agent never wrote:

```bash
kubectl get deployment -l example.crossplane.io/app=web-frontend -o jsonpath='{.items[0].metadata.labels}' | jq .
```{{exec}}

`managed-by: crossplane` and the app label exist on every resource, every time. The agent can't forget them because the agent never writes them.

## Enforced Resource Limits

```bash
kubectl get deployment -l example.crossplane.io/app=web-frontend -o jsonpath='{.items[0].spec.template.spec.containers[0].resources}' | jq .
```{{exec}}

CPU and memory limits are set by the Composition. No deployment — agent-initiated or otherwise — runs without them.

## Enforced Replica Count

```bash
kubectl get deployment -l example.crossplane.io/app=web-frontend -o jsonpath='{.items[0].spec.replicas}'
```{{exec}}

Always 2. Platform policy, not model output.

## The KCL Source

All of these rules live here:

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].input.spec.source}'
```{{exec}}

The model sees the XRD (what it can ask for). The Composition governs what actually gets built. These are separate concerns — the agent cannot reach past the API boundary into the Composition.

In the next step, you'll see the agent perform autonomous lifecycle operations.
