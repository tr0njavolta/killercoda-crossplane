# What the API Enforces

The agent only specified an image. Everything else came from the Composition — and the agent had no way to override it.

## The KCL Source

```bash
kubectl get composition app-kcl -o jsonpath='{.spec.pipeline[0].input.spec.source}'
```{{exec}}

## Enforced Labels

Every resource gets a consistent label the agent never wrote:

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o jsonpath='{.items[0].metadata.labels}' | jq .
```{{exec}}

These labels exist on every App, every time. The agent can't forget them because the agent never writes them.

## Enforced Resource Limits

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o jsonpath='{.items[0].spec.template.spec.containers[0].resources}' | jq .
```{{exec}}

CPU and memory limits are set by the composition. No agent can deploy without them.

## Enforced Replica Count

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o jsonpath='{.items[0].spec.replicas}'
```{{exec}}

Always 2. Platform policy, not agent configuration.

## The Governance Model

The Composition is where platform teams encode organizational standards. The agent interacts with the API; the composition enforces the rules. These are separate concerns, owned by separate teams, expressed in separate files.

An agent can be fully autonomous within the API surface. Outside it, the platform says no.

In the next step, you'll have the agent perform a full lifecycle: update, scale, and teardown.
