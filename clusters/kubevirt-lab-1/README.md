```bash
 flux bootstrap git \
 --components-extra image-reflector-controller,image-automation-controller \
 --url=ssh://git@github.com/ryan4yin/k8s-gitops \
 --branch=main \
 --path=clusters/kubevirt-lab-1
```
