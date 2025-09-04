local alloy = import 'alloy.jsonnet';
local backstage = import 'backstage.jsonnet';
local common = import 'common.libsonnet';
local config = import 'config.jsonnet';
local kps = import 'kps.jsonnet';
local loki = import 'loki.jsonnet';
local mimir = import 'mimir.jsonnet';
local tempo = import 'tempo.jsonnet';
local k = import 'k.libsonnet';
{
  config: config.config,
  backstage: backstage.backstage,
  secrets: [
    k.core.v1.secret.new(
      name='github-app-mop-backstage-credentials',
      data={
        GITHUB_CLIENT_ID: 'SXYyM2xpbmFTSlJaTU93bVduU04K',
        GITHUB_CLIENT_SECRET: 'OWZjYjc5ZDcwZjgwZDIyNTAxYTljNzI1MmU4YmI2MGVkOTk5MGUyOQo=',
      },
    ),
  ]
  // kps: kps.kps,
  // loki: loki.loki,
  // mimir: mimir.mimir,
  // alloy: alloy.alloy,
  // tempo: tempo.tempo,
}
