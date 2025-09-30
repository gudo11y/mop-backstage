# --- basics ---
allow_k8s_contexts('minikube')  # or your context


# Pick Tanka env via env var: TK_ENV=dev tilt up
tk_env = os.getenv('TK_ENV', 'mop-backstage')

# Where to write rendered manifests for Tilt to pick up
out_file = '.tilt/{tk_env}.yaml'.format(tk_env=tk_env)

# Files that should trigger re-render/apply when changed
jsonnet_deps = [
  './tanka/environments/{tk_env}/'.format(tk_env=tk_env),
  './tanka/lib/',
]

local_resource(
    name='setup',
    cmd= 'scripts/tilt_setup.sh {tk_env}'.format(tk_env=tk_env),
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


local_resource(
    name='tk-show',
    cmd='tk show ./tanka/environments/{tk_env} --dangerous-allow-redirect > {out_file}'.format(tk_env=tk_env, out_file=out_file),
    deps=jsonnet_deps,
    resource_deps=['build']
)

if os.path.exists(out_file):
    k8s_yaml(out_file)
else:
    print("File {out_file} does not exist, skipping...".format(out_file=out_file))


k8s_resource(
    workload='backstage',
    port_forwards=[
        port_forward(7007,7007, name='backstage')
    ]
)