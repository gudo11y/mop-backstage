local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local common = import 'common.libsonnet';

{
  kps: helm.template(
    name='kube-prometheus-stack',
    chart='./charts/kube-prometheus-stack',
    conf={
      namespace: 'monitoring',
      values: {

      },
    }
  ),
}
