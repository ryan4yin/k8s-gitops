ls **/** | get name | each {|d|
    let resources = ls -s $d 
    | get name 
    | where (str contains ".yaml") 
    | where $it != "kustomization.yaml"

    if ($resources | is-empty) {
        return null
    }

    {
        apiVersion: "kustomize.config.k8s.io/v1beta1",
        kind: "Kustomization",
        resources: $resources,
    }
    | to yaml
    | save $"($d)/kustomization.yaml"
}

