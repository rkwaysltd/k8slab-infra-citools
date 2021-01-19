FROM golang:1.15.6-alpine3.12@sha256:49b4eac11640066bc72c74b70202478b7d431c7d8918e0973d6e4aeb8b3129d2 AS qbec-builder
ARG QBEC_VERSION=v0.13.4
ARG QBEC_SHA256=33a61c83ef14e1275c47660bb0f57d26b48d7432fcf2364383db0cad9c370bec
RUN apk add --no-cache \
        curl make git gcc libc-dev \
 && ( \
        curl -o /tmp/qbec.tar.gz -Lf "https://github.com/splunk/qbec/archive/${QBEC_VERSION}.tar.gz"; \
        c=$(cat /tmp/qbec.tar.gz | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${QBEC_SHA256}" ] || { echo >&2 "QBEC_SHA256 checksum mismatch"; exit 1; }; \
        tar -xf /tmp/qbec.tar.gz -C /tmp; \
        cd /tmp/qbec-${QBEC_VERSION#v}; \
        make get build; \
    )
FROM alpine:3.13.0@sha256:d9a7354e3845ea8466bb00b22224d9116b183e594527fb5b6c3d30bc01a20378
ARG BUILD_ARCH=amd64
ARG KUBECTL_VERSION=v1.20.2
ARG KUBECTL_SHA265=2583b1c9fbfc5443a722fb04cf0cc83df18e45880a2cf1f6b52d9f595c5beb88
ARG HELM_VERSION=v3.5.0
ARG HELM_SHA256=3fff0354d5fba4c73ebd5db59a59db72f8a5bbe1117a0b355b0c2983e98db95b
ARG JB_VERSION=v0.4.0
ARG JB_SHA256=433edab5554a88a0371e11e93080408b225d41c31decf321c02b50d2e44993ce
# Rarely changed labels
LABEL maintainer="RKways LTD <rkwaysltd@gmail.com>" \
    org.opencontainers.image.title="citools" \
    org.opencontainers.image.description="CI tools for rkwaysltd/k8slab cluster" \
    org.opencontainers.image.url="https://github.com/rkwaysltd/k8slab-infra-citools" \
    org.opencontainers.image.source="git@github.com:rkwaysltd/k8slab-infra-citools.git" \
    org.opencontainers.image.vendor="RKways LTD"
COPY --from=qbec-builder /go/bin/qbec /usr/local/bin/qbec
COPY --from=qbec-builder /go/bin/jsonnet-qbec /usr/local/bin/jsonnet-qbec
RUN apk add --no-cache \
        docker-cli \
        jq curl git make \
 && ( \
        curl -o /tmp/kubectl -Lf "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${BUILD_ARCH}/kubectl"; \
        c=$(cat /tmp/kubectl | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${KUBECTL_SHA265}" ] || { echo >&2 "KUBECTL_SHA265 checksum mismatch"; exit 1; }; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/kubectl; \
        rm -rf /tmp/kubectl; \
    ) \
 && ( \
        curl -o /tmp/helm.tar.gz -Lf "https://get.helm.sh/helm-${HELM_VERSION}-linux-${BUILD_ARCH}.tar.gz"; \
        c=$(cat /tmp/helm.tar.gz | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${HELM_SHA256}" ] || { echo >&2 "HELM_SHA256 checksum mismatch"; exit 1; }; \
        tar -xf /tmp/helm.tar.gz -C /tmp; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/linux-${BUILD_ARCH}/helm; \
        rm -rf /tmp/helm.tar.gz /tmp/linux-${BUILD_ARCH}; \
    ) \
 && ( \
        curl -o /tmp/jb -Lf "https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/${JB_VERSION}/jb-linux-${BUILD_ARCH}"; \
        c=$(cat /tmp/jb | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${JB_SHA256}" ] || { echo >&2 "JB_SHA256 checksum mismatch"; exit 1; }; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/jb; \
        rm -rf /tmp/jb; \
    ) \
 && touch /usr/local/bin/citools-show-versions.sh \
 && chmod 0755 /usr/local/bin/citools-show-versions.sh \
 && ( \
        echo "#!/bin/sh"; \
        echo "set -eu"; \
        echo "kubectl version --client | sed 's/^/kubectl: /'"; \
        echo "qbec version | sed 's/^/qbec: /'"; \
        echo "jb --version 2>&1 | sed 's/^/jb: /'"; \
        echo "docker --version | sed 's/^/docker: /'"; \
        echo "helm version | sed 's/^/helm: /'"; \
        echo "jq --version | sed 's/^/jq: /'"; \
        echo "curl --version | sed 's/^/curl: /'"; \
        echo "git --version | sed 's/^/git: /'"; \
        echo "make --version | sed 's/^/make: /'"; \
    ) >> /usr/local/bin/citools-show-versions.sh \
 && echo "Tools versions:" \
 && /usr/local/bin/citools-show-versions.sh | tee .motd
RUN addgroup -g 59999 -S nonroot && \
    adduser -u 59999 -S nonroot -G nonroot
WORKDIR /home/nonroot
USER 59999:59999
ARG BUILD_DATE
ARG REVISION
LABEL org.opencontainers.image.revision="$REVISION" \
    org.opencontainers.image.created="$BUILD_DATE"
