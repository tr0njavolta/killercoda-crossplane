# Welcome to Crossplane Composition with KCL

In this scenario, you'll learn how to use **Crossplane Composition** to create custom Kubernetes APIs that automatically generate multiple resources.

## What You'll Learn

- Create a CompositeResourceDefinition (XRD) to define a custom API
- Write a Composition with KCL to implement automation logic
- Use KCL to transform user input into Kubernetes resources
- Deploy applications using your custom API
- Manage the full lifecycle of composed resources

## The Scenario

You'll build an `App` custom resource that automatically creates:
- A **Deployment** (2 replicas)
- A **Service** (exposing port 8080)

Users declare an App with just an image; Crossplane handles the rest.

## Setup

The environment is being prepared automatically:
- Installing Crossplane v2
- Installing the KCL composition function
- Creating the CompositeResourceDefinition (XRD)
- Creating the Composition with KCL logic
- Creating an example App resource

Once you see "✅ Setup Complete!" you're ready to go!
