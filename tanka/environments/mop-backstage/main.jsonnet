local alloy = import 'alloy.jsonnet';
local backstage = import 'backstage.jsonnet';
local common = import 'common.libsonnet';
local config = import 'config.jsonnet';
local kps = import 'kps.jsonnet';
local loki = import 'loki.jsonnet';
local mimir = import 'mimir.jsonnet';
local tempo = import 'tempo.jsonnet';

{
  config: config.config,
  backstage: backstage.backstage,
  // kps: kps.kps,
  // loki: loki.loki,
  // mimir: mimir.mimir,
  // alloy: alloy.alloy,
  // tempo: tempo.tempo,
}
