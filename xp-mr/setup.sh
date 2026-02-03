#!/bin/bash

set -e

echo "=========================================="
echo "Crossplane Managed Resources Setup"
echo "=========================================="

export KUBECONFIG=~/.kube/config
mkdir -p /root/xp-mr
cd /root/xp-mr

# Prerequisites check
echo "📋 Prerequisites:"
echo "  • Kubernetes cluster running"
echo "  • kubectl configured"
echo "  • Crossplane v2 (will install if missing)"
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

# Step 1: Install the AWS provider
echo ""
echo "⏳ Step 1: Installing AWS Provider..."
cat > provider.yaml <<'EOF'
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-provider-aws-s3
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0
EOF

kubectl apply -f provider.yaml
echo "⏳ Waiting for AWS provider to be healthy..."
until kubectl get provider crossplane-provider-aws-s3 -o jsonpath='{.status.conditions[?(@.type=="Healthy")].status}' 2>/dev/null | grep -q "True"; do
  echo "⏳ Waiting for provider to be ready..."
  sleep 5
done
echo "✅ AWS provider installed"

# Step 2: Create AWS credentials secret
echo ""
echo "⏳ Step 2: Creating AWS credentials secret..."
cat > aws-credentials.ini <<'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

kubectl create secret generic aws-secret \
  --namespace=crossplane-system \
  --from-file=creds=./aws-credentials.ini \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo "✅ AWS credentials secret created"

# Step 3: Create provider configuration
echo ""
echo "⏳ Step 3: Creating ProviderConfig..."
cat > provider-config.yaml <<'EOF'
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-secret
      key: creds
EOF

kubectl apply -f provider-config.yaml
echo "✅ ProviderConfig created"

# Step 4: Create example S3 bucket
echo ""
echo "⏳ Step 4: Creating example S3 bucket..."
cat > bucket.yaml <<'EOF'
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: crossplane-demo-bucket
spec:
  forProvider:
    region: us-east-2
  providerConfigRef:
    name: default
EOF

kubectl apply -f bucket.yaml
echo "✅ Example S3 bucket created"

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📝 What was created:"
echo "  1. Crossplane core components"
echo "  2. AWS provider for S3"
echo "  3. AWS credentials secret"
echo "  4. ProviderConfig (AWS configuration)"
echo "  5. Example S3 bucket (crossplane-demo-bucket)"
echo ""
echo "🔍 Check status:"
echo "  kubectl get buckets"
echo "  kubectl get buckets -o wide"
echo "  kubectl describe bucket crossplane-demo-bucket"
echo ""
echo "📝 Create a new S3 bucket:"
echo "  cat <<'BUCKET' | kubectl apply -f -"
echo "  apiVersion: s3.aws.upbound.io/v1beta1"
echo "  kind: Bucket"
echo "  metadata:"
echo "    name: my-custom-bucket"
echo "  spec:"
echo "    forProvider:"
echo "      region: us-west-2"
echo "  BUCKET"
echo ""
echo "🔄 Update a bucket (e.g., add tags):"
echo "  kubectl patch bucket crossplane-demo-bucket --type merge -p '{\"spec\":{\"forProvider\":{\"tags\":{\"Environment\":\"Demo\"}}}}'"
echo ""
echo "🗑️  Delete a bucket:"
echo "  kubectl delete bucket crossplane-demo-bucket"
echo ""
