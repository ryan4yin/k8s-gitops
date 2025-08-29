# https://docs.victoriametrics.com/operator/integrations/prometheus/
# By default, victoria-metrics operator converts all existing 
# Prometheus ServiceMonitor, PodMonitor, PrometheusRule, Probe and ScrapeConfig objects 
# into corresponding VictoriaMetrics Operator objects.
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.85.0/bundle.yaml | yq 'select(.kind == "CustomResourceDefinition")' > prometheus-operator-crds.yaml
