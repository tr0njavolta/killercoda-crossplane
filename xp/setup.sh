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
echo "⏳ Installing Crossplane (this may take 2-3 minutes)..."
helm install crossplane \
  --namespace crossplane-system \
  crossplane-stable/crossplane \
  --wait \
  --timeout 10m
echo "✅ Crossplane installed"

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
echo "⏳ Installing AWS S3 Provider..."
cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.16.0
EOF
echo "✅ Provider installation started"

# Wait for provider to be healthy
echo "⏳ Waiting for provider to be healthy (this may take 2-3 minutes)..."
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-aws-s3 --timeout=600s
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
echo "⏳ Waiting for ProviderConfig to be ready..."
sleep 10

# Verify ProviderConfig was created
if kubectl get providerconfig default &>/dev/null; then
    echo "✅ Provider configured"
else
    echo "⚠️  Warning: ProviderConfig may not be ready yet. Checking available CRDs..."
    kubectl get crd | grep providerconfig
    echo "Retrying ProviderConfig creation..."
    kubectl apply -f /root/provider-config.yaml
    sleep 5
    echo "✅ Provider configuration applied"
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
