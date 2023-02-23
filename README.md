# ubuntu-build-utils

Create an Ubuntu jammy based image for GitLab pipelines.
The follwing tools are included:
- kubectl
- helm3
- pluto
- e2j2
- trivy
- argoworklows

## Configuration

Update the following variables if necessary.

```bash
ENV KUBECTL_VERSION=1.26.1
ENV HELM_VERSION=3.11.1
ENV E2J2_VERSION=0.7.0
ENV PLUTO_VERSION=5.15.1
ENV ARGO_VERSION=3.4.5
```
