# The API Contract

An AI agent can only be as autonomous as the interface allows. The XRD defines exactly what the agent can express — and nothing more.

## What the Agent Sees

Inspect the App API:

```bash
kubectl explain app
```{{exec}}

```bash
kubectl explain app.spec
```{{exec}}

The agent sees one field: `image`. That's the entire interface surface. It doesn't need to know about Deployments, Services, label selectors, or port mappings.

## The Full Schema

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec}' | jq .
```{{exec}}

The schema is machine-readable and validated. If the agent provides a wrong type or missing field, Kubernetes rejects it immediately — before anything gets provisioned.

## What Gets Written Back

The API also defines what the platform surfaces back to the agent:

```bash
kubectl get xrd apps.example.crossplane.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.status}' | jq .
```{{exec}}

The agent can read `status.replicas` and `status.address` to know the state of what it deployed — no scraping, no parsing logs.

## Why This Matters

Most platforms give agents raw access: generate a Deployment YAML, apply it, hope for the best. A validated API:
- Constrains what agents can express (smaller blast radius)
- Validates input before anything is provisioned
- Surfaces structured status the agent can read and reason about
- Decouples agent logic from infrastructure implementation

In the next step, you'll simulate an AI agent using this API.
