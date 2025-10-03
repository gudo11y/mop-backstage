# --- basics ---
allow_k8s_contexts(['minikube', 'k3d-prod'])  # or your context

# Pick Tanka env via env var: TK_ENV=dev tilt up
tk_env = os.getenv('TK_ENV', 'mop-backstage')

# Where to write rendered manifests for Tilt to pick up
out_file = '.tilt/{tk_env}.yaml'.format(tk_env=tk_env)

# Files that should trigger re-render/apply when changed
jsonnet_deps = [
  './tanka/environments/{tk_env}/'.format(tk_env=tk_env),
  './tanka/lib/',
]

# Check if k3d cluster exists and create if needed
local_resource(
    name='k3d-cluster-check',
    cmd='''
#!/bin/bash
set -e

# Check if k3d cluster 'prod' exists and all nodes are running
if ! k3d cluster list -o json | jq -e '.[] | select(.name == "prod") | select(.serversRunning == .serversCount and .agentsRunning == .agentsCount)' > /dev/null 2>&1; then
    echo "k3d cluster 'prod' not found or not fully running. Setting up cluster..."

    # Create registry if it doesn't exist
    if ! k3d registry list | grep -q "k3d-registry.localhost"; then
        echo "Creating k3d registry..."
        k3d registry create registry.localhost --port 5005
    else
        echo "Registry k3d-registry.localhost already exists"
    fi

    # Delete cluster if it exists but not healthy
    if k3d cluster list | grep -q "^prod"; then
        echo "Deleting existing unhealthy cluster..."
        k3d cluster delete prod 2>/dev/null || true
    fi

    # Create cluster
    echo "Creating k3d cluster 'prod'..."
    k3d cluster create prod \
      --servers 1 --agents 2 \
      --api-port 6445 \
      --port "80:80@loadbalancer" \
      --port "443:443@loadbalancer" \
      --registry-use k3d-registry.localhost:5005

    # Wait for cluster to be ready
    echo "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s

    echo "k3d cluster 'prod' created and ready!"
else
    echo "k3d cluster 'prod' is already running with all nodes healthy"
fi
''',
    labels=['infrastructure'],
)

local_resource(
    name='setup',
    cmd= 'scripts/tilt_setup.sh {tk_env}'.format(tk_env=tk_env),
    resource_deps=['k3d-cluster-check']
)

local_resource(
    name='vendor-charts',
    cmd='cd tanka/environments/{tk_env} && tk tool charts vendor'.format(tk_env=tk_env),
    resource_deps=['setup']
)

local_resource(
    name='build',
    cmd='scripts/tilt_build.sh',
    resource_deps=['vendor-charts']
)

# docker_build(
#     name='backstage',
#     context='.',
#     dockerfile='mop-backstage/packages/backend/Dockerfile',
#     push=True,
#     resource_deps=['build']
# )
# watch_file('scripts/tilt_setup.sh')


# Use local_resource to dynamically apply the Tanka-generated manifests
local_resource(
    name='tk-apply',
    cmd='mkdir -p .tilt && tk show ./tanka/environments/{tk_env} --dangerous-allow-redirect > {out_file} && kubectl apply -f {out_file}'.format(tk_env=tk_env, out_file=out_file),
    deps=jsonnet_deps,
    resource_deps=['build'],
    auto_init=True,
    trigger_mode=TRIGGER_MODE_AUTO,
    labels=['kubernetes'],
)

# Watch for changes in the generated YAML file to trigger reapplication
watch_file(out_file)

# If the file already exists with valid content, load it into Tilt for resource discovery
if os.path.exists(out_file):
    content = str(local('cat {out_file}'.format(out_file=out_file), quiet=True))
    has_valid_yaml = 'kind:' in content or 'apiVersion:' in content

    if has_valid_yaml:
        k8s_yaml(out_file)

        # Configure the backstage workload with port forwarding
        # Use new_name to avoid conflicts since we're applying via kubectl
        k8s_resource(
            new_name='backstage-app',
            workload='backstage',
            port_forwards=[
                port_forward(7007,7007, name='backstage')
            ],
            resource_deps=['tk-apply']
        )