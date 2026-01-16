# Welcome to Crossplane v2 with LocalStack

In this scenario, you'll learn how to use **Crossplane v2** to manage cloud infrastructure as Kubernetes resources.

## What is Crossplane?

Crossplane is an open-source Kubernetes extension that transforms your cluster into a universal control plane. It allows you to manage cloud infrastructure and services using Kubernetes-style APIs.

## What's New in Crossplane v2?

- **Composition Functions**: Write custom composition logic in any language
- **Enhanced Schema Validation**: Better type checking and validation
- **Improved Provider Framework**: More stable and efficient providers
- **Environment Configs**: Dynamic configuration from cluster state

## What You'll Learn

- Work with Crossplane v2 in a Kubernetes cluster
- Use LocalStack as a local AWS environment
- Configure the AWS Provider for Crossplane v2
- Create and manage AWS resources (S3 bucket) through Kubernetes manifests

## Why LocalStack?

LocalStack provides a local AWS cloud stack, allowing you to develop and test cloud applications without incurring AWS costs. Perfect for learning Crossplane!

## Setup

The environment is being prepared automatically. This includes:
- Installing Helm
- Installing Crossplane v2.1.3
- Deploying LocalStack (AWS simulator)
- Installing and configuring the AWS S3 Provider (v2 compatible)
- Creating all necessary credentials and configurations

**This takes about 3-5 minutes.** Once you see "✅ Setup Complete!" you're ready to go!

Let's get started!
