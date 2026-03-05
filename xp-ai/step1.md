# Verify the Setup

Confirm everything is ready: Crossplane, the KCL function, the App API, and the local model.

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
kubectl get xrd && kubectl get compositions
```{{exec}}

## Ollama and the Model

```bash
ollama list
```{{exec}}

`llama3.2:1b` should be present. Check the server is accepting requests:

```bash
curl -s http://localhost:11434/api/tags | jq '.models[].name'
```{{exec}}

All good? In the next step, you'll see exactly what API surface the agent has been given.
