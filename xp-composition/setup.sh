#!/bin/bash

set -e

echo "=========================================="
echo "Crossplane with KCL Composition Setup"
echo "=========================================="

export KUBECONFIG=~/.kube/config

# Prerequisites check
echo "📋 Prerequisites:"
echo "  • Kubernetes cluster running"
echo "  • kubectl configured"
echo "  • Crossplane v1.14+ (will install if missing)"
echo ""

# Step 0: Install Crossplane if not present
echo "⏳ Step 0: Checking Crossplane installation..."
if ! kubectl get namespace crossplane-system &> /dev/null; then
  echo "⏳ Installing Crossplane..."
  helm repo add crossplane-stable https://charts.crossplane.io/stable
  helm repo update
  helm install crossplane crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace \
    --wait
  echo "✅ Crossplane installed"
else
  echo "✅ Crossplane already installed"
fi

# Step 1: Install the KCL function
echo ""
echo "⏳ Step 1: Installing KCL Function..."
cat > fn.yaml <<'EOF'
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: crossplane-contrib-function-kcl
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-kcl:v0.11.2
EOF

kubectl apply -f fn.yaml
echo "⏳ Waiting for KCL function to be healthy..."
until kubectl get function crossplane-contrib-function-kcl -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null | grep -q "True"; do
  echo "⏳ Waiting for function to be ready..."
  sleep 5
done
echo "✅ KCL function installed"

# Step 2: Create a CompositeResourceDefinition (XRD)
echo ""
echo "⏳ Step 2: Creating CompositeResourceDefinition..."
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
                description: The app's IP address.
                type: string
EOF

kubectl apply -f xrd.yaml
echo "✅ CompositeResourceDefinition created"

# Step 3: Create a Composition with KCL
echo ""
echo "⏳ Step 3: Creating Composition with KCL..."
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

          _desired_deployment = {
            apiVersion = "apps/v1"
            kind = "Deployment"
            metadata = {
              annotations = {
                "krm.kcl.dev/composition-resource-name" = "deployment"
              }
              labels = {"example.crossplane.io/app" = observed_xr.metadata.name}
            }
            spec = {
              replicas = 2
              selector.matchLabels = {"example.crossplane.io/app" = observed_xr.metadata.name}
              template = {
                metadata.labels = {"example.crossplane.io/app" = observed_xr.metadata.name}
                spec.containers = [{
                  name = "app"
                  image = observed_xr.spec.image
                  ports = [{containerPort = 80}]
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
              labels = {"example.crossplane.io/app" = observed_xr.metadata.name}
            }
            spec = {
              selector = {"example.crossplane.io/app" = observed_xr.metadata.name}
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
echo "✅ Composition with KCL created"

# Step 4: Create example App
echo ""
echo "⏳ Step 4: Creating example App..."
cat > app.yaml <<'EOF'
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  namespace: default
  name: my-app
spec:
  image: nginx
EOF

kubectl apply -f app.yaml
echo "✅ Example App created"

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📝 What was created:"
echo "  1. Crossplane core components"
echo "  2. KCL Function for composition"
echo "  3. CompositeResourceDefinition (App XRD)"
echo "  4. Composition with KCL logic (app-kcl)"
echo "  5. Example App resource (my-app)"
echo ""
echo "🔍 Check status:"
echo "  kubectl get apps"
echo "  kubectl get apps -o wide"
echo "  kubectl get deployments -l example.crossplane.io/app=my-app"
echo "  kubectl get services -l example.crossplane.io/app=my-app"
echo ""
echo "📝 Create a new App:"
echo "  cat <<'APP' | kubectl apply -f -"
echo "  apiVersion: example.crossplane.io/v1"
echo "  kind: App"
echo "  metadata:"
echo "    name: custom-app"
echo "  spec:"
echo "    image: your-image:v1"
echo "  APP"
echo ""
echo "🔄 Update an App (e.g., change image):"
echo "  kubectl patch app my-app --type merge -p '{\"spec\":{\"image\":\"new-image:v2\"}}'"
echo ""
echo "🗑️  Delete an App:"
echo "  kubectl delete app my-app"
echo ""
