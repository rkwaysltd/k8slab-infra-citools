FROM alpine:3.14.0@sha256:234cb88d3020898631af0ccbbcca9a66ae7306ecd30c9720690858c1b007d2a0
ARG BUILD_ARCH=amd64
ARG QBEC_VERSION=v0.14.3
ARG QBEC_SHA256=ec625cd9897456e871ab03e33eed857f23648603c17a94f917ea052bb6665efa
ARG KUBECTL_VERSION=v1.21.2
ARG KUBECTL_SHA265=55b982527d76934c2f119e70bf0d69831d3af4985f72bb87cd4924b1c7d528da
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
RUN apk add --no-cache \
        docker-cli \
        jq curl git make \
 && ( \
        curl -o /tmp/qbec.tar.gz -Lf "https://github.com/splunk/qbec/releases/download/${QBEC_VERSION}/qbec-linux-${BUILD_ARCH}.tar.gz"; \
        c=$(cat /tmp/qbec.tar.gz | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${QBEC_SHA256}" ] || { echo >&2 "QBEC_SHA256 checksum mismatch"; exit 1; }; \
        mkdir /tmp/qbec-linux-${BUILD_ARCH}; \
        tar -xf /tmp/qbec.tar.gz -C /tmp/qbec-linux-${BUILD_ARCH}; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/qbec-linux-${BUILD_ARCH}/qbec; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/qbec-linux-${BUILD_ARCH}/jsonnet-qbec; \
        rm -rf /tmp/qbec.tar.gz /tmp/qbec-linux-${BUILD_ARCH}; \
    ) \
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
