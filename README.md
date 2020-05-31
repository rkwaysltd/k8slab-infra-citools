# Project k8slab-infra-citools

Docker image with tools for building and deploying apps in k8slab cluster.

# Description

[Alpine Linux](https://alpinelinux.org/) image with following tools added:

- [kubectl](https://kubernetes.io/)
- [qbec](https://github.com/splunk/qbec) with jsonnet-qbec
- [jsonnet bundler (jb)](https://github.com/jsonnet-bundler/jsonnet-bundler)
- [docker CLI](https://www.docker.com/)
- [helm](https://helm.sh/)
- curl
- make
- git
- jq

Supported architectures:

- amd64
- arm64

# Docker Hub image

Created image is published to [public repository on
hub.docker.com](https://hub.docker.com/r/rkwaysltd/citools) so it's widely
available to all runners and CI pipelines.

# Gitlab CI variables

Used for publishing to hub.docker.com:

- `PROJ_CI_DOCKERHUB_USER` (type: Variable, protected) - hub.docker.com username
- `PROJ_CI_DOCKERHUB_TOKEN` (type: Variable, protected, masked) - hub.docker.com user token or password
- `PROJ_CI_DOCKERHUB_REPO` - (type: Variable, protected) hub.docker.com repository name

# Gitlab note

This repository is private in Gitlab only because it's using privileged builder
in k8slab (for bootstraping). Please remember that Github mirror is public.
