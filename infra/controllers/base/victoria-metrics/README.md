# victoria metrics

## vmstorage

This component is the cluster’s heaviest consumer of CPU and memory.  
During every restart or Pod recreation it briefly saturates available resources; once
initialization completes, CPU drops sharply to a low baseline, while memory only falls
modestly.  
In addition, some background tasks such as deduplication periodically drive CPU usage
to near-peak levels for a few seconds and then almost instantly collapse back to baseline.
