local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  backstage: helm.template(
    name='backstage',
    chart='./charts/backstage',
    conf={
      namespace: common.namespace,
      values+: {
        global+: {
          imageRegistry: 'minikube-registry:5000',
        },
        backstage+: {
          appConfig+: {
            catalog+: {
              providers+: {
                githubOrg: {
                  id: 'gudo11y',
                  githubUrl: 'https://github.com',
                  orgs: ['gudo11y'],
                  schedule: {
                    initialDelay: { seconds: 30 },
                    frequency: { hours: 1 },
                    timeout: { minutes: 50 },
                  },

                },
              },
            },
          },
        },
        postgresql+: {
          enabled: true,
        },
      },
    },
  ),
}
