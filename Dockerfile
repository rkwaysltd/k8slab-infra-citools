FROM golang:1.14.3-alpine3.11@sha256:d3a08e6a81ef8f25c7b9f4b8f2990fe76790f057ef7f8053e8884511ddd81756 AS qbec-builder
ARG QBEC_VERSION=v0.11.0
ARG QBEC_SHA256=fddf7fae84ba0bbdef343a86486a9bea406d644c5dc22e9724b0dd564534625d
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
FROM alpine:3.11.6@sha256:9a839e63dad54c3a6d1834e29692c8492d93f90c59c978c1ed79109ea4fb9a54
ARG BUILD_ARCH=amd64
ARG KUBECTL_VERSION=v1.18.3
ARG KUBECTL_SHA265=6fcf70aae5bc64870c358fac153cdfdc93f55d8bae010741ecce06bb14c083ea
ARG HELM_VERSION=v3.2.1
ARG HELM_SHA256=018f9908cb950701a5d59e757653a790c66d8eda288625dbb185354ca6f41f6b
COPY --from=qbec-builder /go/bin/qbec /usr/local/bin/qbec
COPY --from=qbec-builder /go/bin/jsonnet-qbec /usr/local/bin/jsonnet-qbec
RUN apk add --no-cache \
        docker-cli \
        jq curl git make \
 && ( \
        curl -o /tmp/kubectl -Lf "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${BUILD_ARCH}/kubectl"; \
        c=$(cat /tmp/kubectl | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${KUBECTL_SHA265}" ] || { echo >&2 "KUBECTL_SHA265 checksum mismatch"; exit 1; }; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/kubectl \
        rm -rf /tmp/kubectl \
    ) \
 && ( \
        curl -o /tmp/helm.tar.gz -Lf "https://get.helm.sh/helm-${HELM_VERSION}-linux-${BUILD_ARCH}.tar.gz"; \
        c=$(cat /tmp/helm.tar.gz | sha256sum | cut -d ' ' -f1); \
        [ "$c" = "${HELM_SHA256}" ] || { echo >&2 "HELM_SHA256 checksum mismatch"; exit 1; }; \
        tar -xf /tmp/helm.tar.gz -C /tmp; \
        install -o root -g root -m 0755 -t /usr/local/bin /tmp/linux-${BUILD_ARCH}/helm \
        rm -rf /tmp/helm.tar.gz /tmp/linux-${BUILD_ARCH} \
    ) \
 && touch /usr/local/bin/citools-show-versions.sh \
 && chmod 0755 /usr/local/bin/citools-show-versions.sh \
 && ( \
        echo "#!/bin/sh"; \
        echo "set -eu"; \
        echo "kubectl version --client | sed 's/^/kubectl: /'"; \
        echo "qbec version | sed 's/^/qbec: /'"; \
        echo "docker --version | sed 's/^/docker: /'"; \
        echo "helm version | sed 's/^/helm: /'"; \
        echo "jq --version | sed 's/^/jq: /'"; \
        echo "curl --version | sed 's/^/curl: /'"; \
        echo "git --version | sed 's/^/git: /'"; \
        echo "make --version | sed 's/^/make: /'"; \
    ) >> /usr/local/bin/citools-show-versions.sh \
 && echo "Tools versions:" \
 && /usr/local/bin/citools-show-versions.sh | tee .motd
