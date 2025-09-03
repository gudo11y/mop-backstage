local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  loki: helm.template(
    name='loki',
    chart='./charts/loki',
    conf={
      namespace: 'monitoring',
      values: {

      },
    }
  ),
}
