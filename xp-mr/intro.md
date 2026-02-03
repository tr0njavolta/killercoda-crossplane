# Welcome to Crossplane Managed Resources

In this scenario, you'll learn how to use **Crossplane** to manage cloud infrastructure directly through Kubernetes. Instead of manually creating cloud resources in AWS, you'll declare them as Kubernetes resources.

## What are Managed Resources?

Managed Resources are Kubernetes resources that represent cloud infrastructure. When you create a managed resource, Crossplane automatically provisions the actual cloud resource. When you delete the resource, Crossplane cleans it up.

## What You'll Learn

- Install and use a Crossplane Provider (AWS)
- Configure provider credentials securely
- Create cloud resources (S3 buckets) as Kubernetes manifests
- Monitor and manage the lifecycle of cloud resources
- Understand how Crossplane bridges Kubernetes and cloud APIs

## The Example Scenario

You'll:
- Install the AWS provider
- Configure AWS credentials
- Create an S3 bucket using a Crossplane managed resource
- Verify it was created in AWS
- Update and delete the resource

This demonstrates infrastructure-as-code: define your cloud resources in YAML, apply them to Kubernetes, and Crossplane handles the rest.

## Setup

The environment is being prepared automatically. This includes:
- Installing Crossplane v2
- Installing the AWS provider
- Creating AWS credentials secret
- Creating a provider configuration
- Creating an example S3 bucket

**This takes about 2-3 minutes.** Once you see "✅ Setup Complete!" you're ready to go!

Let's get started!
