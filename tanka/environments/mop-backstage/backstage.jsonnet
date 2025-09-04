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
        backstage+: {
          image+: {
            registry: 'localhost:5005',
            repository: 'backstage/backstage',
            tag: 'latest',
          },
          command: ['node', 'packages/backend'],
          containerPorts+: { backend: 7007 },
          appConfig+: {
            app: {
              title: 'Managed Observability Platform',
              baseUrl: 'http://localhost:7007',
            },
            organization: {
              name: 'gudo11y',
            },
            backend: {
              baseUrl: 'http://localhost:7007',
              listen: { port: 7007 },
              csp: { connectSrc: ["'self'", 'http:', 'https:'] },
              cors: { origin: ['http://localhost:7007'], methods: ['GET', 'HEAD', 'PATCH', 'POST', 'PUT', 'DELETE'], credentials: true },
              // database: {
              //   client: 'pg',
              //   connection: {
              //     host: '${POSTGRES_HOST}',
              //     port: '${POSTGRES_PORT}',
              //     user: '${POSTGRES_USER}',
              //     password: '${POSTGRE_PASSWORD}',
              //   },
              // },
            },
            integrations: {
              github: [{ host: 'github.com', apps: [{ '$include': 'github-app-mop-backstage-credentials.yaml' }] }],
            },
            techdocs: {
              builder: 'local',
              generator: {
                runIn: 'docker',
              },
              publisher: {
                type: 'local',
              },
            },
            auth: {
              environment: 'development',
              providers: {
                github+: {
                  development: {
                    clientId: '${GITHUB_CLIENT_ID}',
                    clientSecret: '${GITHUB_CLIENT_SECRET}',
                    signIn: {
                      resolvers: [{
                        resolver: 'usernameMatchingUserEntityName',
                      }],

                    },
                  },
                },
              },
            },
            catalog+: {
              'import': {
                entityFilename: 'catalog-info.yaml',
                pullRequestBranchName: 'backstage-integration',
              },
              rules+: [{ allow: ['Component', 'System', 'API', 'Resource', 'Location'] }],
              locations+: [
                {
                  type: 'file',
                  target: '../../examples/entities.yaml',
                },
                {
                  type: 'file',
                  target: '../../examples/template/template.yaml',
                },
                {
                  type: 'file',
                  target: '../../examples/org.yaml',
                },
              ],
              providers+: {
                githubOrg: {
                  id: 'github',
                  githubUrl: 'https://github.com',
                  orgs: ['gudo11y'],
                  schedule: {
                    initialDelay: { seconds: 30 },
                    frequency: { seconds: 10 },
                    timeout: { minutes: 50 },
                  },

                },
              },
            },

            kubernetes: {
              serviceLocatorMethod: {
                type: 'multiTenant',
              },
              clusterLocatorMethods: [
                {
                  type: 'config',
                  clusters: [
                    {
                      // url: '${KUBERNETES_MASTER}',
                      url: 'http://127.0.0.1:32836',
                      name: 'minikube',
                      authProvider: 'serviceAccount',
                      skipTLSVerify: true,
                      skipMetricsLookup: true,
                      // serviceAccountToken: '${K8S_MINIKUBE_TOKEN}',
                      serviceAccountToken: 'derp',
                    },
                  ],
                },
              ],


            },
            permission: {
              enabled: 'false',
            },
          },
          extraEnvVarsSecrets: [
            'github-app-mop-backstage-credentials',
          ],
        },
        postgresql+: {
          enabled: 'true',
        },
        serviceAccount+: {
          create: true,
        },
      },
    },
  ),
}
