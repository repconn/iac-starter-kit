# syntax=docker/dockerfile:1

# Alpine Docker image with
# terraform, terragrunt
# awscli, google-cloud-sdk
FROM alpine:3.18.0

ARG IMAGE_CREATE_DATE
ARG IMAGE_VERSION

# Metadata as defined in OCI image spec annotations
# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="cloud-tools" \
      org.opencontainers.image.description="cloud-tools" \
      org.opencontainers.image.authors="github.com/exdial" \
      org.opencontainers.image.created=$IMAGE_CREATE_DATE \
      org.opencontainers.image.version=$IMAGE_VERSION

# Versions of binaries included in image
ARG TF_VER=1.5.7
ARG TG_VER=0.51.0

# Working directory
WORKDIR /usr/local/bin

# Geting Terraform
ARG TF_URI="https://releases.hashicorp.com/terraform"
RUN wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip \
 && wget -q ${TF_URI}/${TF_VER}/terraform_${TF_VER}_SHA256SUMS \
 && grep terraform_${TF_VER}_linux_amd64.zip terraform_${TF_VER}_SHA256SUMS | \
    sha256sum -c - \
 && unzip terraform_${TF_VER}_linux_amd64.zip && chmod +x terraform \
 && rm terraform_${TF_VER}_linux_amd64.zip terraform_${TF_VER}_SHA256SUMS

# Getting Terragrunt
ARG TG_URI="https://github.com/gruntwork-io/terragrunt/releases/download"
RUN wget -q ${TG_URI}/v${TG_VER}/terragrunt_linux_amd64 \
 && wget -q ${TG_URI}/v${TG_VER}/SHA256SUMS \
 && grep terragrunt_linux_amd64 SHA256SUMS | sha256sum -c - \
 && mv terragrunt_linux_amd64 terragrunt && chmod +x terragrunt \
 && rm SHA256SUMS

# Working directory
WORKDIR /opt

# Install glibc compatibility for the AWS CLI v2
ARG GLIBC_VERSION=2.35-r1
ARG GLIBC_URI="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"
RUN wget -q https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -O \
    /etc/apk/keys/sgerrand.rsa.pub \
 && wget -q ${GLIBC_URI}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
 && wget -q ${GLIBC_URI}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
 && apk add --no-cache glibc-${GLIBC_VERSION}.apk \
                       glibc-bin-${GLIBC_VERSION}.apk \
 && rm -rf glibc-*.apk /var/cache/apk/*

# Getting AWS CLI
RUN wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
 && unzip awscli-exe-linux-x86_64.zip \
 && ./aws/install \
 && rm -rf aws /usr/local/aws-cli/v2/*/dist/aws_completer \
           /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
           /usr/local/aws-cli/v2/*/dist/awscli/examples \
           awscli-exe-linux-x86_64.zip \
 && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name \
    examples-1.json -delete

# Install python3 for Google Cloud CLI
ENV PYTHONUNBUFFERED=1
RUN apk add --no-cache --update python3

# Getting Google Cloud CLI
RUN wget -q https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz \
 && tar xf google-cloud-sdk.tar.gz \
 && rm google-cloud-sdk.tar.gz

# Run the container as a non-root user
ARG USER=user
RUN adduser -s /bin/bash -D ${USER}
USER ${USER}

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
