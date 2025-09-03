local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  tempo: helm.template(
    name='tempo',
    chart='./charts/tempo-distributed',
    conf={
      namespace: 'monitoring',
      values: {

      },
    }
  ),
}
