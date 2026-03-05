# Autonomous Operations

The same API handles the full lifecycle. The agent can deploy, inspect, update, and tear down — all through the same structured interface.

## Multi-Step Request

The agent can handle requests that require multiple tool calls:

```bash
python3 /root/xp-ai/agent.py "deploy httpd:2.4 as web-server and then check its status"
```{{exec}}

Watch the tool calls: the model deploys, then immediately calls `get_status` to verify.

## Update via Re-Deploy

The Crossplane API is declarative — applying a changed image is just another `deploy_app` call:

```bash
python3 /root/xp-ai/agent.py "update web-frontend to use nginx:1.25"
```{{exec}}

```bash
kubectl get deployment -l example.crossplane.io/app=web-frontend -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```{{exec}}

## Teardown

```bash
python3 /root/xp-ai/agent.py "delete web-frontend and api-server"
```{{exec}}

Note: the model may call `delete_app` twice, once per app.

```bash
kubectl get apps
```{{exec}}

```bash
kubectl get deployments,services
```{{exec}}

All composed resources cleaned up.

## What Made This Work

The agent is autonomous because the platform is well-structured:

- **Validated API** — the model can't generate invalid infrastructure; Kubernetes rejects it at admission
- **Structured status** — the model reads JSON back from `get_status`, not logs or HTML
- **Governance in the platform** — limits, labels, and replica counts are enforced regardless of what the model requests
- **Declarative reconciliation** — update and delete are the same API surface as create

The model doesn't need to understand Kubernetes. It needs to understand the API.
