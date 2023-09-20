# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=${ALPINE_VERSION:-3.18.0}

# STAGE 1: builder
FROM alpine:${ALPINE_VERSION} as builder

# Versions of binaries included in image
ARG AWSCLI_VER=2.10.1
ARG TF_VER=1.5.7
ARG TG_VER=0.51.0

# Working directory
WORKDIR /opt

# Getting AWS CLI v2
RUN apk add --no-cache curl make cmake gcc g++ \
    libc-dev libffi-dev openssl-dev python3 python3-dev \
 && curl https://awscli.amazonaws.com/awscli-${AWSCLI_VER}.tar.gz | tar -xz \
 && cd awscli-${AWSCLI_VER} \
 && ./configure --prefix=/opt/aws-cli/ --with-download-deps \
 && make \
 && make install

# Getting Google Cloud CLI
RUN wget -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz \
 && tar xf google-cloud-sdk.tar.gz

# Working directory
WORKDIR /usr/local/bin

# Geting Terraform
ARG TF_URI="https://releases.hashicorp.com/terraform"
RUN wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip \
 && wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_SHA256SUMS \
 && grep terraform_${TF_VER}_linux_amd64.zip terraform_${TF_VER}_SHA256SUMS | \
    sha256sum -c - \
 && unzip terraform_${TF_VER}_linux_amd64.zip && chmod +x terraform

# Getting Terragrunt
ARG TG_URI="https://github.com/gruntwork-io/terragrunt/releases/download"
RUN wget -q ${TG_URI}/v${TG_VER}/terragrunt_linux_amd64 \
 && wget -q ${TG_URI}/v${TG_VER}/SHA256SUMS \
 && grep terragrunt_linux_amd64 SHA256SUMS | sha256sum -c - \
 && mv terragrunt_linux_amd64 terragrunt && chmod +x terragrunt

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

# Install python3 for Google Cloud CLI
ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache --update python3 groff

# Copy binaries
COPY --from=builder /opt/aws-cli/ /opt/aws-cli/
COPY --from=builder /opt/google-cloud-sdk/ /opt/google-cloud-sdk/
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/bin/terragrunt /usr/local/bin/terragrunt
COPY entrypoint.sh /usr/local/bin/

# Run the container as a non-root user
ARG USER=user
RUN adduser -s /bin/bash -D ${USER}
USER ${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
