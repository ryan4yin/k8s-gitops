from kubernetes import client, config

config.load_incluster_config()
core_v1 = client.CoreV1Api()

namespace = "staging"
label_selector = "app=failed"

res = core_v1.list_namespaced_pod(
    namespace, label_selector=label_selector, timeout_seconds=10
)

for pod in res.items:
    print(pod)

    restart_count = pod.status.container_statuses[0].restart_count
    ready = pod.status.container_statuses[0].ready
    node_name = pod.spec.node_name
    pod_name = pod.metadata.name
    print(f"Pod: {pod_name} on node: {node_name} has restart count: {restart_count} and is ready: {ready}")
