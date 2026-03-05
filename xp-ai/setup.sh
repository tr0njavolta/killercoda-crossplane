#!/bin/bash

set -e

echo "=========================================="
echo "API-First Infrastructure for AI Agents"
echo "=========================================="

export KUBECONFIG=~/.kube/config
mkdir -p /root/xp-ai
cd /root/xp-ai

# Setup Theia IDE
mkdir -p /root/.theia
cat > /root/.theia/settings.json <<'EOF'
{
  "files.exclude": {
    ".git": true,
    ".claude": true,
    ".*": true,
    "filesystem": true
  }
}
EOF

cat > /root/.theia/recentworkspace.json <<'EOF'
{"recentRoots":["file:///root/xp-ai"]}
EOF

cat > /root/.theia/enter-folder.json <<'EOF'
{
  "folderPath": "/root/xp-ai"
}
EOF

# Install Crossplane if not present
echo "Checking Crossplane..."
if ! kubectl get namespace crossplane-system &> /dev/null; then
  echo "Installing Crossplane..."
  helm repo add crossplane-stable https://charts.crossplane.io/stable
  helm repo update
  helm install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait
  echo "Crossplane installed"
else
  echo "Crossplane already installed"
fi

# Install the KCL function
echo "Installing KCL Function..."
cat > fn.yaml <<'EOF'
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-kcl
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-kcl:v0.11.2
EOF

kubectl apply -f fn.yaml
echo "Waiting for KCL function to be healthy..."
until kubectl get function crossplane-contrib-function-kcl -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null | grep -q "True"; do
  echo "Waiting..."
  sleep 5
done
echo "KCL function ready"

# Create the XRD
echo "Creating CompositeResourceDefinition..."
cat > xrd.yaml <<'EOF'
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: apps.example.crossplane.io
spec:
  scope: Namespaced
  group: example.crossplane.io
  names:
    kind: App
    plural: apps
  versions:
  - name: v1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              image:
                description: The app's OCI container image.
                type: string
            required:
            - image
          status:
            type: object
            properties:
              replicas:
                description: The number of available app replicas.
                type: integer
              address:
                description: The app's cluster IP address.
                type: string
EOF

kubectl apply -f xrd.yaml
echo "XRD created"

# Create the Composition with governance baked in
echo "Creating Composition..."
cat > composition.yaml <<'EOF'
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: app-kcl
spec:
  compositeTypeRef:
    apiVersion: example.crossplane.io/v1
    kind: App
  mode: Pipeline
  pipeline:
  - step: create-deployment-and-service
    functionRef:
      name: crossplane-contrib-function-kcl
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLInput
      spec:
        source: |
          observed_xr = option("params").oxr
          app_name = observed_xr.metadata.name

          # Governance: enforced labels applied to all resources
          _labels = {"example.crossplane.io/app" = app_name, "managed-by" = "crossplane"}

          _desired_deployment = {
            apiVersion = "apps/v1"
            kind = "Deployment"
            metadata = {
              annotations = {
                "krm.kcl.dev/composition-resource-name" = "deployment"
              }
              labels = _labels
            }
            spec = {
              # Governance: replica count enforced by platform
              replicas = 2
              selector.matchLabels = _labels
              template = {
                metadata.labels = _labels
                spec.containers = [{
                  name = "app"
                  image = observed_xr.spec.image
                  ports = [{containerPort = 80}]
                  # Governance: resource limits enforced by platform
                  resources = {
                    requests = {cpu = "100m", memory = "128Mi"}
                    limits = {cpu = "500m", memory = "256Mi"}
                  }
                }]
              }
            }
          }

          observed_deployment = option("params").ocds["deployment"]?.Resource
          if any_true([c.type == "Available" and c.status == "True" for c in observed_deployment?.status?.conditions or []]):
            _desired_deployment.metadata.annotations["krm.kcl.dev/ready"] = "True"

          _desired_service = {
            apiVersion = "v1"
            kind = "Service"
            metadata = {
              annotations = {
                "krm.kcl.dev/composition-resource-name" = "service"
              }
              labels = _labels
            }
            spec = {
              selector = _labels
              ports = [{protocol = "TCP", port = 8080, targetPort = 80}]
            }
          }

          observed_service = option("params").ocds["service"]?.Resource
          if observed_service?.spec?.clusterIP:
            _desired_service.metadata.annotations["krm.kcl.dev/ready"] = "True"

          _desired_xr = {
            **option("params").dxr
            status.address = observed_service?.spec?.clusterIP or ""
            status.replicas = observed_deployment?.status?.availableReplicas or 0
          }

          items = [_desired_deployment, _desired_service, _desired_xr]
EOF

kubectl apply -f composition.yaml
echo "Composition created"

# Install Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable --now ollama
echo "Waiting for Ollama to start..."
until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
  sleep 2
done
echo "Ollama running"

# Pull the model
echo "Pulling llama3.2:1b (this takes a few minutes)..."
ollama pull llama3.2:1b
echo "Model ready"

# Install Python requests
pip3 install -q requests

# Write the agent
cat > /root/xp-ai/agent.py <<'AGENT'
#!/usr/bin/env python3
"""Infrastructure agent: natural language -> Crossplane App API via tool calling."""

import json
import subprocess
import sys
import requests

MODEL = "llama3.2:1b"
OLLAMA_URL = "http://localhost:11434/api/chat"

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "deploy_app",
            "description": "Deploy an application via the Crossplane App API",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "App name (lowercase, hyphens allowed, no spaces)"
                    },
                    "image": {
                        "type": "string",
                        "description": "OCI container image, e.g. nginx:latest"
                    }
                },
                "required": ["name", "image"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_status",
            "description": "Get the current status of a deployed application",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "App name"}
                },
                "required": ["name"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_apps",
            "description": "List all currently deployed applications",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_app",
            "description": "Delete a deployed application and all its composed resources",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "App name to delete"}
                },
                "required": ["name"]
            }
        }
    }
]


def deploy_app(name: str, image: str) -> str:
    manifest = f"""apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: {name}
spec:
  image: {image}"""
    result = subprocess.run(
        ["kubectl", "apply", "-f", "-"],
        input=manifest, capture_output=True, text=True
    )
    if result.returncode == 0:
        return f"App '{name}' applied with image '{image}'. Crossplane is reconciling."
    return f"Error: {result.stderr.strip()}"


def get_status(name: str) -> str:
    result = subprocess.run(
        ["kubectl", "get", "app", name, "-o", "json"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return f"App '{name}' not found."
    app = json.loads(result.stdout)
    status = app.get("status", {})
    conditions = status.get("conditions", [])
    ready = next((c["status"] for c in conditions if c["type"] == "Ready"), "Unknown")
    return json.dumps({
        "name": name,
        "image": app["spec"]["image"],
        "ready": ready,
        "replicas": status.get("replicas", 0),
        "address": status.get("address", "")
    })


def list_apps() -> str:
    result = subprocess.run(
        ["kubectl", "get", "apps", "-o", "json"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return "Error listing apps."
    items = json.loads(result.stdout).get("items", [])
    if not items:
        return "No apps deployed."
    apps = []
    for item in items:
        status = item.get("status", {})
        conditions = status.get("conditions", [])
        ready = next((c["status"] for c in conditions if c["type"] == "Ready"), "Unknown")
        apps.append({
            "name": item["metadata"]["name"],
            "image": item["spec"]["image"],
            "ready": ready,
            "replicas": status.get("replicas", 0)
        })
    return json.dumps(apps)


def delete_app(name: str) -> str:
    result = subprocess.run(
        ["kubectl", "delete", "app", name, "--ignore-not-found"],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        return f"App '{name}' deleted. All composed resources will be cleaned up."
    return f"Error: {result.stderr.strip()}"


def execute_tool(name: str, args: dict) -> str:
    if name == "deploy_app":
        return deploy_app(**args)
    elif name == "get_status":
        return get_status(**args)
    elif name == "list_apps":
        return list_apps()
    elif name == "delete_app":
        return delete_app(**args)
    return f"Unknown tool: {name}"


def get_system_prompt() -> str:
    schema = subprocess.run(
        ["kubectl", "explain", "app.spec"],
        capture_output=True, text=True
    ).stdout.strip()

    return f"""You are an infrastructure agent. You provision and manage applications \
on a platform built with Crossplane.

The platform exposes a single API resource:

{schema}

Use the provided tools to deploy, inspect, and delete applications based on \
what the user asks. After each tool call, give a brief natural-language summary \
of what happened. Do not invent app names or images — use exactly what the user specifies."""


def chat(user_input: str, messages: list) -> tuple[str, list]:
    messages.append({"role": "user", "content": user_input})

    while True:
        resp = requests.post(OLLAMA_URL, json={
            "model": MODEL,
            "messages": messages,
            "tools": TOOLS,
            "stream": False
        })
        resp.raise_for_status()
        msg = resp.json()["message"]
        messages.append(msg)

        if not msg.get("tool_calls"):
            return msg.get("content", ""), messages

        for call in msg["tool_calls"]:
            fn_name = call["function"]["name"]
            args = call["function"]["arguments"]
            if isinstance(args, str):
                args = json.loads(args)

            arg_str = ", ".join(f"{k}={v}" for k, v in args.items())
            print(f"  [tool] {fn_name}({arg_str})")

            result = execute_tool(fn_name, args)
            messages.append({"role": "tool", "content": result})


def main():
    system_prompt = get_system_prompt()
    messages = [{"role": "system", "content": system_prompt}]

    # Single-command mode: python3 agent.py "deploy nginx as web-app"
    if len(sys.argv) > 1:
        user_input = " ".join(sys.argv[1:])
        response, _ = chat(user_input, messages)
        if response:
            print(response)
        return

    # Interactive REPL
    print(f"Infrastructure agent ready (model: {MODEL}). Type 'exit' to quit.\n")
    while True:
        try:
            user_input = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not user_input:
            continue
        if user_input.lower() in ("exit", "quit"):
            break
        response, messages = chat(user_input, messages)
        if response:
            print(response)
        print()


if __name__ == "__main__":
    main()
AGENT

chmod +x /root/xp-ai/agent.py

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "What was created:"
echo "  1. Crossplane core components"
echo "  2. KCL Function for composition"
echo "  3. App API via CompositeResourceDefinition"
echo "  4. Composition with governance rules"
echo "  5. Ollama running llama3.2:1b"
echo "  6. Agent at /root/xp-ai/agent.py"
echo ""
