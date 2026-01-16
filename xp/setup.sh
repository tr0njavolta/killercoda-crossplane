#!/bin/bash

# Wait for Kubernetes to be ready
echo "Waiting for Kubernetes cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Install Helm if not present
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Create all manifest files
echo "Creating manifest files..."

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

# AWS credentials
cat > /root/aws-credentials.txt <<'EOF'
[default]
aws_access_key_id = test
aws_secret_access_key = test
EOF

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
EOF

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

echo "Setup complete! All files created in /root/"
ls -la /root/*.yaml /root/*.txt
