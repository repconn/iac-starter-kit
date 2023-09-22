# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=${ALPINE_VERSION:-3.18.3}

# STAGE 1: builder
FROM alpine:${ALPINE_VERSION} as builder

# Versions of binaries included in image
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-latest}
ARG TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-latest}
ARG PACKER_VERSION=${PACKER_VERSION:-latest}
ARG AWSCLI_VERSION=${AWSCLI_VERSION:-latest}
ARG HELM_VERSION=${HELM_VERSION:-latest}

# URLs
ARG HASHICORP_URL="https://releases.hashicorp.com"
ARG GRUNTWORK_URL="https://github.com/gruntwork-io/terragrunt/releases/download"
ARG HASHICORP_API="https://api.github.com/repos/hashicorp"
ARG GRUNTWORK_API="https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest"
ARG AWSCLI_API="https://api.github.com/repos/aws/aws-cli/tags"
ARG HELM_URL="https://get.helm.sh"
ARG HELM_API="https://api.github.com/repos/helm/helm/releases/latest"


# Working directory
WORKDIR /opt

# Getting AWS CLI v2
RUN : && \
 apk add --no-cache jq make cmake gcc g++ \
 libc-dev libffi-dev openssl-dev python3 python3-dev \
 && if [ "${AWSCLI_VERSION}" = "latest" ]; then \
  AWSCLI_VERSION="$(wget -qO- ${AWSCLI_API} | jq -r .[].name | tr -d 'v' | grep ^2 | head -n1)" \
 ;  fi \
 && wget -qO- https://awscli.amazonaws.com/awscli-${AWSCLI_VERSION}.tar.gz | tar -xz \
 && cd awscli-${AWSCLI_VERSION} \
 && ./configure --prefix=/opt/aws-cli/ --with-download-deps \
 && make \
 && make install

# Getting Google Cloud CLI
RUN wget -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz \
 && tar xf google-cloud-sdk.tar.gz

# Working directory
WORKDIR /usr/local/bin

# Geting Terraform
RUN : && \
 if [ "${TERRAFORM_VERSION}" = "latest" ]; then \
  TERRAFORM_VERSION="$(wget -qO- ${HASHICORP_API}/terraform/releases/latest | jq -r .tag_name | tr -d 'v')" \
 ; fi \
 && wget -q ${HASHICORP_URL}/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && wget -q ${HASHICORP_URL}/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
 && grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | \
  sha256sum -c - && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && chmod +x terraform

# Getting Terragrunt
RUN : && \
 if [ "${TERRAGRUNT_VERSION}" = "latest" ]; then \
  TERRAGRUNT_VERSION="$(wget -qO- ${GRUNTWORK_API} | jq -r .tag_name | tr -d 'v')" \
 ; fi \
 && wget -q ${GRUNTWORK_URL}/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
 && wget -q ${GRUNTWORK_URL}/v${TERRAGRUNT_VERSION}/SHA256SUMS \
 && grep terragrunt_linux_amd64 SHA256SUMS | sha256sum -c - \
 && mv terragrunt_linux_amd64 terragrunt && chmod +x terragrunt

# Getting Packer
RUN : && \
 if [ "${PACKER_VERSION}" = "latest" ]; then \
  PACKER_VERSION="$(wget -qO- ${HASHICORP_API}/packer/releases/latest | jq -r .tag_name | tr -d 'v')" \
 ; fi \
 && wget -q ${HASHICORP_URL}/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
 && wget -q ${HASHICORP_URL}/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS \
 && grep packer_${PACKER_VERSION}_linux_amd64.zip packer_${PACKER_VERSION}_SHA256SUMS | \
  sha256sum -c - && unzip packer_${PACKER_VERSION}_linux_amd64.zip && chmod +x packer

# Getting Helm
RUN : && \
 if [ "${HELM_VERSION}" = "latest" ]; then \
  HELM_VERSION="$(wget -qO- ${HELM_API} | jq -r .tag_name | tr -d 'v')" \
 ; fi \
 && wget -q ${HELM_URL}/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
 && wget -q ${HELM_URL}/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum \
 && grep helm-v${HELM_VERSION}-linux-amd64.tar.gz \
  helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum | sha256sum -c - \
 && tar xfz helm-v${HELM_VERSION}-linux-amd64.tar.gz \
 && mv linux-amd64/helm . && chmod +x helm

# STAGE 2: final
FROM alpine:${ALPINE_VERSION}

ARG IMAGE_CREATE_DATE
ARG IMAGE_VERSION

# Metadata as defined in OCI image spec annotations
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="cloud-tools" \
      org.opencontainers.image.description="cloud-tools" \
      org.opencontainers.image.authors="github.com/exdial" \
      org.opencontainers.image.created=$IMAGE_CREATE_DATE \
      org.opencontainers.image.version=$IMAGE_VERSION

# Working directory
WORKDIR /opt

# Install python3 required for Google Cloud CLI and Ansible,
# and groff required for AWS CLI
ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache --update python3 groff ansible

# Copy binaries
COPY --from=builder /opt/aws-cli/ /opt/aws-cli/
COPY --from=builder /opt/google-cloud-sdk/ /opt/google-cloud-sdk/
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/bin/terragrunt /usr/local/bin/terragrunt
COPY --from=builder /usr/local/bin/packer /usr/local/bin/packer
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY entrypoint.sh /usr/local/bin/

# Run the container as a non-root user
ARG USER=user
RUN adduser -s /bin/bash -D ${USER}
USER ${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
