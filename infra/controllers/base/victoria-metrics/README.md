# victoria metrics

## vmstorage

This component is the cluster’s heaviest consumer of CPU and memory.  
During every restart or Pod recreation it briefly saturates available resources; once
initialization completes, CPU drops sharply to a low baseline, while memory only falls
modestly.  
In addition, some background tasks such as deduplication periodically drive CPU usage to
near-peak levels for a few seconds and then almost instantly collapse back to baseline.

## Capacity planning

> https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#capacity-planning

- It is recommended to run a cluster with big number of small vmstorage nodes instead of a
  cluster with small number of big vmstorage nodes.
- Query latency can be reduced by increasing CPU resources per each vmselect node, since
  each incoming query is processed by a single vmselect node.

## Resource usage limits

> https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#resource-usage-limits

- vmstorage
  - retentionPeriod: 30d
  - search.maxUniqueTimeseries: "1000000"  # default = 30000
  - memory.allowedPercent: 60
- vmselect
  - search.maxQueryDuration: 60s    # default = 30s
  - search.maxConcurrentRequests: 4 # default = 2 \* vcpu cores
  - search.maxMemoryPerQuery: 2Gi   # default = no limit
  - memory.allowedPercent: 60       # default = 60
- vminsert
  - maxInsertRequestSize: 32MB      # default = 32MB
