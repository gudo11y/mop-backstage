local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  mimir: helm.template(
    name='mimir',
    chart='./charts/mimir-distributed',
    conf={
      namespace: 'monitoring',
      values: {

      },
    }
  ),
}
