# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.13

LABEL name="Nextlinux Engine Operator" \
      vendor="Nextlinux Inc." \
      maintainer="dev@nextlinux.com" \
      version="v1.0.1" \
      release="0" \
      summary="Nextlinux Engine Helm based operator." \
      description="Nextlinux Engine - container image scanning service for policy-based security, best-practice and compliance enforcement."

ENV HOME=/opt/helm
COPY licenses /licenses
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
USER root
RUN microdnf install yum \
  && yum -y update \
  && yum clean all \
  && microdnf remove yum \
  && microdnf clean all
WORKDIR ${HOME}
USER ${USER_UID}
