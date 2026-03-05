# API-First Infrastructure for AI Agents

AI has accelerated code creation — but the bottleneck is everything *after* `git push`. Infrastructure workflows are still built for humans: UIs, runbooks, informal coordination, scattered policies. AI agents hit a wall, not because they lack capability, but because the platform wasn't built for programmatic access.

The fix isn't better prompts. It's better APIs.

## The Core Idea

Crossplane turns infrastructure into a set of structured, validated, machine-readable APIs. An AI agent doesn't need to know how to write a Deployment, wire labels to selectors, or remember port numbers. It just calls the API — the same way it calls any other API.

## What You'll Do

- Explore the XRD that defines the infrastructure API an AI agent sees
- Simulate an AI agent provisioning infrastructure through that API
- See the governance baked into the Composition that the agent can't bypass
- Watch the agent perform autonomous lifecycle operations: deploy, update, teardown

## Setup

The environment is being prepared:
- Installing Crossplane v2
- Installing the KCL composition function
- Registering the `App` API via a CompositeResourceDefinition
- Deploying the Composition with governance rules baked in

Once you see "Setup Complete!" you're ready to go.
