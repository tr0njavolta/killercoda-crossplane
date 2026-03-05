# Autonomous Operations

An API-first platform lets agents operate across the full resource lifecycle without human intervention.

## Update

The agent updates an image — the platform reconciles:

```bash
kubectl patch app my-app --type merge -p '{"spec":{"image":"nginx:1.25"}}'
```{{exec}}

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```{{exec}}

One API call. No Deployment patched directly. No rollout triggered manually.

## Read Status

The agent reads structured status to confirm the deployment is healthy:

```bash
kubectl get app my-app -o jsonpath='{.status}' | jq .
```{{exec}}

`status.replicas` and `status.address` are machine-readable. The agent can branch on these values without parsing logs or scraping metrics endpoints.

## Deploy at Scale

The API makes mass operations straightforward:

```bash
for app in worker-1 worker-2 worker-3; do
  kubectl apply -f - <<EOF
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: $app
spec:
  image: alpine:latest
EOF
done
```{{exec}}

```bash
kubectl get apps
```{{exec}}

## Teardown

```bash
kubectl delete app worker-1 worker-2 worker-3 api-server
```{{exec}}

```bash
kubectl get apps
```{{exec}}

```bash
kubectl get deployments,services
```{{exec}}

All composed resources cleaned up. One delete call per App.

## The Bigger Picture

The blog post ["Crossplane & AI: The Case for API-First Infrastructure"](https://blog.crossplane.io/crossplane-ai-the-case-for-api-first-infrastructure/) frames this precisely: the bottleneck for AI agents isn't capability — it's that most platforms were built for humans. UIs, runbooks, and informal coordination don't compose into agent workflows.

Crossplane's XRDs give agents a stable, validated, machine-readable interface. The Composition ensures governance is structural, not procedural. The agent doesn't need to be trusted with the full platform — just with the API surface it's been given.
