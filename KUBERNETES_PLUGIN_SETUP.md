# Backstage Kubernetes Plugin Setup

## Overview

The Kubernetes plugin for Backstage has been configured to work with your local minikube cluster. This document explains the configuration and how to use it.

## Configuration Changes Made

### 1. Backend Configuration (`app-config.yaml`)

Added Kubernetes cluster configuration in `mop-backstage/mop-backstage/app-config.yaml`:

```yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://kubernetes.default.svc
          name: minikube
          authProvider: 'serviceAccount'
          skipTLSVerify: false
          skipMetricsLookup: false
          customResources:
            - group: 'argoproj.io'
              apiVersion: 'v1alpha1'
              plural: 'rollouts'
```

**Key settings:**
- **serviceLocatorMethod: 'multiTenant'** - Uses annotations on entities to find Kubernetes resources
- **authProvider: 'serviceAccount'** - Uses Kubernetes service account for authentication
- **url: https://kubernetes.default.svc** - Default in-cluster URL (change if running externally)
- **customResources** - Includes ArgoCD Rollouts support

### 2. Entity Annotations

Updated `catalog-info.yaml` files to include Kubernetes annotations:

```yaml
metadata:
  annotations:
    backstage.io/kubernetes-id: mop-cli
    backstage.io/kubernetes-namespace: default
    backstage.io/kubernetes-label-selector: 'app=mop-cli'
```

**Annotation options:**
- `backstage.io/kubernetes-id` - Matches resources with label `backstage.io/kubernetes-id=<value>`
- `backstage.io/kubernetes-namespace` - Namespace to search (or comma-separated list)
- `backstage.io/kubernetes-label-selector` - Custom label selector for resources

## How to Use

### 1. Running Backstage Inside Kubernetes (Recommended)

When Backstage runs inside the minikube cluster:

1. Ensure the Backstage pod has a ServiceAccount with proper RBAC permissions
2. The plugin will automatically use in-cluster authentication
3. The default URL `https://kubernetes.default.svc` will work

**Required RBAC permissions:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-read
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "namespaces", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["argoproj.io"]
    resources: ["rollouts"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-read
subjects:
  - kind: ServiceAccount
    name: backstage
    namespace: default
```

### 2. Running Backstage Locally (Development)

For local development outside the cluster:

1. Update the cluster URL in `app-config.yaml` to use your minikube IP:
   ```yaml
   clusters:
     - url: https://$(minikube ip):8443
       name: minikube
       authProvider: 'localKubectlProxy'
       skipTLSVerify: true
   ```

2. Or use kubectl proxy:
   ```bash
   kubectl proxy --port=8001
   ```

   Then update the config:
   ```yaml
   clusters:
     - url: http://localhost:8001
       name: minikube
       authProvider: 'localKubectlProxy'
   ```

3. Or use your kubeconfig:
   ```yaml
   clusters:
     - name: minikube
       authProvider: 'googleServiceAccount'  # or 'aws', 'oidc', etc.
       skipTLSVerify: true
   ```

### 3. Labeling Kubernetes Resources

For resources to appear in Backstage, they must be labeled to match the annotations:

**Option A: Using kubernetes-id**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mop-cli
  namespace: default
  labels:
    backstage.io/kubernetes-id: mop-cli
spec:
  # ...
```

**Option B: Using custom label selector**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mop-cli
  namespace: default
  labels:
    app: mop-cli
spec:
  # ...
```

### 4. Viewing Kubernetes Resources

1. Navigate to any component in Backstage catalog (e.g., mop-cli, mop-spill)
2. Click on the **"Kubernetes"** tab
3. You'll see:
   - Deployments
   - Pods with status
   - Services
   - ConfigMaps
   - HPA (if configured)
   - Custom resources (ArgoCD Rollouts)
   - Recent events
   - Pod logs

## Troubleshooting

### "No Kubernetes resources found"

1. **Check annotations** - Ensure your catalog entity has the correct annotations
2. **Check labels** - Verify Kubernetes resources have matching labels
3. **Check namespace** - Ensure the namespace in annotation matches where resources are deployed
4. **Check RBAC** - Verify the ServiceAccount has permission to read resources

### "Unable to connect to cluster"

1. **In-cluster**: Ensure ServiceAccount and RBAC are configured
2. **Local**: Ensure minikube is running: `minikube status`
3. **Local**: Check kubectl access: `kubectl get pods`
4. **Local**: Try kubectl proxy method if direct connection fails

### "Permission denied"

1. Check RBAC ClusterRole has necessary permissions
2. Verify ClusterRoleBinding is created
3. Check ServiceAccount is correctly referenced in deployment

### Enable Debug Logging

Add to `app-config.yaml`:
```yaml
backend:
  log:
    level: debug
```

## Alternative Authentication Methods

### AWS EKS
```yaml
authProvider: 'aws'
```
Requires AWS IAM authentication.

### Google GKE
```yaml
authProvider: 'google'
```
Requires Google Cloud authentication.

### Azure AKS
```yaml
authProvider: 'azure'
```
Requires Azure authentication.

### Service Account Token (External)
```yaml
authProvider: 'serviceAccount'
serviceAccountToken: ${K8S_TOKEN}
```
Pass token via environment variable.

## Multi-Cluster Setup

To add multiple clusters:

```yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://kubernetes.default.svc
          name: production
          authProvider: 'serviceAccount'
        - url: https://staging-cluster:6443
          name: staging
          authProvider: 'serviceAccount'
          caData: ${STAGING_CA_DATA}
          serviceAccountToken: ${STAGING_TOKEN}
```

Then specify cluster in annotations:
```yaml
annotations:
  backstage.io/kubernetes-id: mop-cli
  backstage.io/kubernetes-cluster: staging
```

## Next Steps

1. **Deploy RBAC resources** - Apply the ServiceAccount and RBAC configuration to minikube
2. **Label your deployments** - Add appropriate labels to existing Kubernetes resources
3. **Test the plugin** - Navigate to a catalog entry and check the Kubernetes tab
4. **Add more clusters** - Expand configuration to include staging/production clusters
5. **Customize display** - Adjust which resource types are shown in the UI

## References

- [Backstage Kubernetes Plugin Documentation](https://backstage.io/docs/features/kubernetes/)
- [Kubernetes Plugin Configuration](https://backstage.io/docs/features/kubernetes/configuration)
- [Kubernetes Plugin Authentication](https://backstage.io/docs/features/kubernetes/authentication)