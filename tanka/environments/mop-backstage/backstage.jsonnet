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
          extraEnvVars: [
            {
              name: 'POSTGRES_PASSWORD',
              valueFrom: {
                secretKeyRef: {
                  name: 'backstage-postgresql',
                  key: 'postgres-password',
                },
              },
            },
          ],
          appConfig+: {
            app: {
              title: 'Managed Observability Platform',
              baseUrl: 'http://localhost:3000',
            },
            organization: {
              name: 'gudo11y',
            },
            backend: {
              baseUrl: 'http://localhost:7007',
              listen: { port: 7007 },
              csp: { connectSrc: ["'self'", 'http:', 'https:'] },
              cors: { origin: ['http://localhost:3000'], methods: ['GET', 'HEAD', 'PATCH', 'POST', 'PUT', 'DELETE'], credentials: true },
              database: {
                client: 'pg',
                connection: {
                  host: '${POSTGRES_HOST}',
                  port: '${POSTGRES_PORT}',
                  user: 'postgres',
                  password: '${POSTGRES_PASSWORD}',
                },
              },
            },
            // events: {
            //   modules: {
            //     github: {
            //       webhookSecret: '${GITHUB_WEBHOOK_SECRET}',
            //     },
            //   },
            // },
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
              providers: {
                githubOrg: {
                  id: 'githubOrg',
                  githubUrl: 'https://github.com',
                  orgs: ['gudo11y'],
                  schedule: {
                    initialDelay: { seconds: 30 },
                    frequency: { seconds: 60 },
                    timeout: { minutes: 50 },
                  },
                },
                  github: {
                    providerId: {
                      organization: 'gudo11y',
                      catalogPath: './catalog-info.yaml',
                      filters: {
                        branch: 'main',
                        repository: '.*',
                      },
                      schedule: {
                        frequency: { minutes: 1 },
                        timeout: { seconds: 45 },
                      },
                    },
                  },

              },
            },

            kubernetes: {
              serviceLocatorMethod: {
                type: 'singleTenant',
              },
              clusterLocatorMethods: [
                {
                  type: 'config',
                  clusters: [
                    {
                      // url: '${KUBERNETES_MASTER}',
                      url: 'http://127.0.0.1:32846',
                      name: 'minikube',
                      authProvider: 'serviceAccount',
                      skipTLSVerify: true,
                      skipMetricsLookup: true,
                      // serviceAccountToken: 'eyJhbGciOiJSUzI1NiIsImtpZCI6IkM1cWV1bGRqU1RtclpGMkg3bU90cVc5eGo3WGxuMVVrRWcyZkJoU0ZUb3MifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtb3AiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiYmFja3N0YWdlLXNhLXRva2VuIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImJhY2tzdGFnZS1zYSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImQwYTMzZjM1LThlZjItNDllYi04ZTM5LWE1YmYyYjBhYTM1OCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDptb3A6YmFja3N0YWdlLXNhIn0.KgiO4tJbf8htnRE1gFaxKUVJTrm3212cXqpQSXN_1jwWsFllczdh_aVmL78XDD1zq2MbpbfrTLkMfbN002eJeYcJ6if-TN-eDgMkJ9yYVEFg9v6sNbFJGiGVB-IjGOGF6FQeq9uc-PRw0NfGUC9YBBueRgoQk2tJZCfOu0p-XM3iuKrn5L-2h2qbng9nMsQGJL-ykLMmOPiUAkCNiK8VAKe9wztovhcqwcwDVa84p0alQYOjUQfpPUBuN901PYYUGaaQWRzVidM_ykRoZvNCkleMyGGEFBYgCFnK0dXCHsWgYSHsWkO-uBzAMSePN18K7PzAZQABnZyMP_-IgFfKuw',
                      // serviceAccountToken: '${K8S_MINIKUBE_TOKEN}',
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
            // 'backstage-sa-token',
          ],
        },
        postgresql+: {
          enabled: 'true',
          image+: {
            registry: 'docker.io',
            repository: 'postgres',
            tag: '15-alpine',
          },
          auth+: {
            username: 'postgres',
            database: 'backstage',
            postgresPassword: '${POSTGRES_ADMIN_PASSWORD}',
          },
          primary+: {
            extraEnvVars: [
              {
                name: 'POSTGRES_USER',
                value: 'postgres',
              },
              {
                name: 'POSTGRES_DB',
                value: 'backstage',
              },
              {
                name: 'PGDATA',
                value: '/var/lib/postgresql/data/pgdata',
              },
            ],
          },
        },
        serviceAccount+: {
          create: true,
        },
      },
    },
  ),
}
