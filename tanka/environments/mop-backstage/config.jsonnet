local common = import 'common.libsonnet';
local k = import 'k.libsonnet';

{
  config:: {
    namespaces: [
      k.core.v1.namespace.new(common.namespace),
    ],
  },
}
