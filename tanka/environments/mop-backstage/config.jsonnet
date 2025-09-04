local common = import 'common.libsonnet';
local k = import 'k.libsonnet';


{
  config:: {
    local clusterRoleBinding = k.rbac.v1.clusterRoleBinding,
    local bindRole(x) = k.rbac.v1.clusterRoleBinding.bindRole(x),
    local withSubjects = clusterRoleBinding.withSubjects,

    namespaces: [
      k.core.v1.namespace.new(common.namespace),
    ],

    service_accounts: [
      k.core.v1.serviceAccount.new('backstage-sa'),
    ],

    cluster_role_bindings: [
      clusterRoleBinding.new('backstage-sa-binding')
      + withSubjects([
        {
          kind: 'ServiceAccount',
          name: 'backstage-sa',
          namespace: 'kube-system',
        },
      ])
      + clusterRoleBinding.metadata.withNamespace('kube-system')
        { roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' } },
    ],

  },
}
