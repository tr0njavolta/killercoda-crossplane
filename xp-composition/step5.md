# Modify and Scale Applications

Crossplane features **reactive composition**: when you change an App, the composition automatically updates resources.

## Update an App's Image

Change the image of `nodejs-app`:

```bash
kubectl patch app nodejs-app --type merge -p '{"spec":{"image":"node:20"}}'
```{{exec}}

Check the Deployment image changed:

```bash
kubectl get deployment -l example.crossplane.io/app=nodejs-app -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```{{exec}}

## Edit an App Using kubectl edit

Use the interactive editor:

```bash
kubectl edit app nodejs-app
```{{exec}}

Change `spec.image: node:20` to `node:19`, save and exit (`:wq` in vim).

Verify the change:

```bash
kubectl get deployment -l example.crossplane.io/app=nodejs-app -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'
```{{exec}}

## Understand Composition Reactivity

Every time you change an App:
1. Kubernetes detects the change
2. Crossplane runs the composition again
3. KCL generates new Deployment and Service specs
4. Kubernetes updates the resources
5. App status updates automatically

All within seconds!

## Cleanup Apps

Delete the test apps:

```bash
kubectl delete app nodejs-app python-app custom-app
```{{exec}}

Verify they're gone:

```bash
kubectl get apps
```{{exec}}

Verify Deployments and Services are also deleted:

```bash
kubectl get deployments,services
```{{exec}}

Deleting an App automatically deletes all composed resources!

## Key Concepts

**Declarative APIs**: Users declare desired state, not implementation
**Automatic Composition**: Complex resources created from simple inputs
**Reactive Updates**: Changes propagate automatically
**Lifecycle Management**: Delete App → delete all related resources
**Separation of Concerns**: Platform teams define composition, app teams use it

## Next Steps

Extend the composition to:
- Accept more parameters (port, replicas, resources)
- Conditionally create resources based on input
- Add network policies or monitoring
- Compose with AWS, GCP, or Azure providers

KCL makes all of this possible and maintainable!
