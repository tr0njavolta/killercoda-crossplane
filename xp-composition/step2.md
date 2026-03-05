# Apply a Composite — See What Gets Created

Apply a single `App` resource:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: example.crossplane.io/v1
kind: App
metadata:
  name: my-app
spec:
  image: nginx:latest
EOF
```{{exec}}

Wait for it to become ready:

```bash
kubectl get app my-app -w
```{{exec}}

Press `Ctrl+C` once you see `READY: True`.

## See Everything That Was Created

That 3-line resource triggered Crossplane to generate a full Deployment:

```bash
kubectl get deployment -l example.crossplane.io/app=my-app -o yaml
```{{exec}}

And a Service:

```bash
kubectl get service -l example.crossplane.io/app=my-app -o yaml
```{{exec}}

## Check the Composed Resources

Crossplane tracks every resource it manages on the App itself:

```bash
kubectl get app my-app -o jsonpath='{.spec.resourceRefs}' | jq .
```{{exec}}

## Inspect the App Status

The App surfaces information back from its composed resources:

```bash
kubectl get app my-app -o jsonpath='{.status}' | jq .
```{{exec}}

Replica count and cluster IP — pulled from the Deployment and Service, written back to the App automatically.

In the next steps, you'll see how all of this is defined: the XRD that creates the custom API, and the KCL code that generates the resources.
