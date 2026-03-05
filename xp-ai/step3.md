# The Agent Deploys

Here's a script that simulates an AI agent receiving deployment requests and acting on them through the infrastructure API.

## The Agent

```bash
cat /root/xp-ai/agent.sh
```{{exec}}

The agent takes a name and image, generates the minimal API call, and applies it. It then polls `status` until the deployment is ready — all through the structured API.

## Run the Agent

Deploy an app:

```bash
/root/xp-ai/agent.sh my-app nginx:latest
```{{exec}}

Deploy another:

```bash
/root/xp-ai/agent.sh api-server node:20
```{{exec}}

## What the Agent Needed to Know

- The API group: `example.crossplane.io/v1`
- The kind: `App`
- The field: `spec.image`

That's it. No Kubernetes internals. No label selectors. No port wiring.

## What Came Out

```bash
kubectl get apps
```{{exec}}

```bash
kubectl get deployments,services
```{{exec}}

Two apps, each with a correctly wired Deployment and Service, consistent labels, enforced resource limits — none of which the agent specified.

In the next step, you'll see what the platform enforced that the agent never touched.
