#!/bin/bash

set -e

echo "=========================================="
echo "Setting up Crossplane with LocalStack..."
echo "=========================================="

# Wait for Kubernetes to be ready
echo "⏳ Waiting for Kubernetes cluster..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s
echo "✅ Kubernetes is ready"

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo "⏳ Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "✅ Helm installed"
else
    echo "✅ Helm already installed"
fi

# Add Crossplane Helm repo
echo "⏳ Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
echo "✅ Helm repository added"

# Create crossplane-system namespace
echo "⏳ Creating crossplane-system namespace..."
kubectl create namespace crossplane-system 2>/dev/null || true
echo "✅ Namespace ready"

# Install Crossplane
echo "⏳ Installing Crossplane v2 (this may take 2-3 minutes)..."
helm install crossplane \
  --namespace crossplane-system \
  crossplane-stable/crossplane \
  --version 2.1.3 \
  --wait \
  --timeout 10m \
  --set args='{--enable-composition-webhook-schema-validation,--enable-environment-configs}'
echo "✅ Crossplane v2 installed"

# Create all manifest files
echo "⏳ Creating manifest files..."

# LocalStack deployment
cat > /root/localstack-deployment.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: localstack
  labels:
    app: localstack
spec:
  type: ClusterIP
  ports:
    - port: 4566
      targetPort: 4566
      protocol: TCP
      name: edge
  selector:
    app: localstack
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: localstack
  labels:
    app: localstack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: localstack
  template:
    metadata:
      labels:
        app: localstack
    spec:
      containers:
      - name: localstack
        image: localstack/localstack:3.0
        ports:
        - containerPort: 4566
        env:
        - name: SERVICES
          value: "s3"
        - name: DEBUG
          value: "1"
        - name: DATA_DIR
          value: "/tmp/localstack/data"
        - name: DOCKER_HOST
          value: "unix:///var/run/docker.sock"
        - name: EAGER_SERVICE_LOADING
          value: "1"
        resources:
          limits:
            memory: "1Gi"
            cpu: "1000m"
          requests:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /_localstack/health
            port: 4566
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
        livenessProbe:
          httpGet:
            path: /_localstack/health
            port: 4566
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
EOF

# Deploy LocalStack
echo "⏳ Deploying LocalStack..."
kubectl apply -f /root/localstack-deployment.yaml
echo "✅ LocalStack deployment created"

# Wait for LocalStack
echo "⏳ Waiting for LocalStack to be ready..."
kubectl wait --for=condition=Ready pod -l app=localstack --timeout=300s
echo "✅ LocalStack is running"

# Install AWS Provider
echo "⏳ Installing AWS S3 Provider (v2 compatible)..."
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.18.0
  packagePullPolicy: IfNotPresent
EOF

# Check if provider was created
if kubectl get provider provider-aws-s3 &>/dev/null; then
    echo "✅ Provider resource created"
else
    echo "❌ Failed to create provider resource"
    echo "Checking if Provider CRD exists..."
    kubectl get crd providers.pkg.crossplane.io
    exit 1
fi

echo "✅ Provider installation started"

# Wait for provider to be installed first (not just healthy)
echo "⏳ Waiting for provider to be installed (this may take 2-3 minutes)..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    installed=$(kubectl get provider provider-aws-s3 -o jsonpath='{.status.conditions[?(@.type=="Installed")].status}' 2>/dev/null)
    if [ "$installed" == "True" ]; then
        echo "✅ Provider installed successfully"
        break
    fi
    echo -n "."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo ""
    echo "❌ Provider installation timed out"
    echo "Current provider status:"
    kubectl get provider provider-aws-s3 -o yaml
    exit 1
fi

# Now wait for provider to be healthy
echo "⏳ Waiting for provider to be healthy..."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=300s || {
    echo "❌ Provider failed to become healthy"
    echo "Provider status:"
    kubectl describe provider provider-aws-s3
    echo ""
    echo "Provider pods:"
    kubectl get pods -n crossplane-system
    exit 1
}
echo "✅ AWS S3 Provider is healthy"

# AWS credentials
cat > /root/aws-credentials.txt <<'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

# Create AWS credentials secret
echo "⏳ Creating AWS credentials secret..."
kubectl create secret generic aws-creds \
  -n crossplane-system \
  --from-file=credentials=/root/aws-credentials.txt
echo "✅ AWS credentials secret created"

# Provider config
cat > /root/provider-config.yaml <<'EOF'
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: credentials
  endpoint:
    url:
      type: Static
      static: "http://localstack:4566"
    hostnameImmutable: true
  skip_credentials_validation: true
  skip_metadata_api_check: true
  skip_requesting_account_id: true
  s3_use_path_style: true
  s3_force_path_style: true
EOF

# Apply provider config
echo "⏳ Configuring AWS Provider..."
kubectl apply -f /root/provider-config.yaml

# Wait a moment for the ProviderConfig to be processed
echo "⏳ Waiting for ProviderConfig CRD to be available..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if kubectl get crd providerconfigs.aws.upbound.io &>/dev/null; then
        echo "✅ ProviderConfig CRD is available"
        break
    fi
    echo -n "."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo ""
    echo "❌ ProviderConfig CRD not found after waiting"
    echo "Available CRDs:"
    kubectl get crd | grep -i provider
    exit 1
fi

# Now apply the ProviderConfig
echo "⏳ Applying ProviderConfig..."
kubectl apply -f /root/provider-config.yaml

# Verify ProviderConfig was created
sleep 5
if kubectl get providerconfig default &>/dev/null; then
    echo "✅ Provider configured"
else
    echo "⚠️  Warning: ProviderConfig may not be ready yet"
    echo "Checking available ProviderConfigs..."
    kubectl get providerconfig --all-namespaces 2>/dev/null || echo "None found"
    echo "Retrying ProviderConfig creation..."
    kubectl apply -f /root/provider-config.yaml
    sleep 5
    if kubectl get providerconfig default &>/dev/null; then
        echo "✅ Provider configuration applied"
    else
        echo "❌ Failed to create ProviderConfig"
        kubectl get crd | grep providerconfig
        exit 1
    fi
fi

# S3 bucket
cat > /root/s3-bucket.yaml <<'EOF'
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-crossplane-bucket
spec:
  forProvider:
    region: us-east-1
  providerConfigRef:
    name: default
EOF

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📦 Installed:"
echo "  • Crossplane $(kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d: -f2)"
echo "  • AWS S3 Provider"
echo "  • LocalStack (AWS simulator)"
echo ""
echo "📁 Files created in /root/:"
ls -1 /root/*.yaml /root/*.txt 2>/dev/null | sed 's/^/  • /'
echo ""
echo "🔍 Quick verification:"
echo "  • Crossplane pods: $(kubectl get pods -n crossplane-system --no-headers 2>/dev/null | wc -l) running"
echo "  • LocalStack pod: $(kubectl get pods -l app=localstack --no-headers 2>/dev/null | grep Running | wc -l)/1 ready"
echo "  • AWS Provider: $(kubectl get provider provider-aws-s3 -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null || echo 'checking...')"
echo "  • ProviderConfig: $(kubectl get providerconfig default -o jsonpath='{.metadata.name}' 2>/dev/null || echo 'checking...')"
echo ""
echo "🚀 You're ready to start creating managed resources!"
echo ""
