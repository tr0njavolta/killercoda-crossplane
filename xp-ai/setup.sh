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

mkdir -p /root/.theia
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

# Write the agent script
cat > /root/xp-ai/agent.sh <<'AGENT'
#!/bin/bash
# Simulated AI agent: receives a name and image, deploys via the infrastructure API

set -e

NAME=${1:?"Usage: agent.sh <name> <image>"}
IMAGE=${2:?"Usage: agent.sh <name> <image>"}

echo "[agent] Deploying $NAME with image $IMAGE..."

kubectl apply -f - <<EOF
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: $NAME
spec:
  image: $IMAGE
EOF

echo "[agent] Waiting for $NAME to be ready..."
until kubectl get app "$NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"; do
  sleep 3
done

ADDRESS=$(kubectl get app "$NAME" -o jsonpath='{.status.address}')
REPLICAS=$(kubectl get app "$NAME" -o jsonpath='{.status.replicas}')

echo "[agent] $NAME is ready"
echo "[agent]   address:  $ADDRESS"
echo "[agent]   replicas: $REPLICAS"
AGENT

chmod +x /root/xp-ai/agent.sh

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
echo "  5. Agent script at /root/xp-ai/agent.sh"
echo ""
