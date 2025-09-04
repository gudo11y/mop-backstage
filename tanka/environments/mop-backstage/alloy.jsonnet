local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  alloy: helm.template(
    name='alloy',
    chart='./charts/alloy',
    conf={
      namespace: common.namespace,
      values+: {

      },
    }
  ),
}
