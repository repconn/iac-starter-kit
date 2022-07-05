# Stage 1: builder
FROM alpine:3.16.0 as builder

# Versions of binaries included in image
ARG TERRAFORM_VERSION=1.2.4
ARG TERRAGRUNT_VERSION=0.38.3

# Working directory
WORKDIR /build

# Install additional packages to work with vendor archives
RUN apk add --no-cache --update bash curl wget unzip \
 && rm -rf /var/cache/apk/*

# Geting Terraform and validate it
RUN curl -sLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && curl -sLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
 && grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c - \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && chmod +x terraform \
 && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS

# Getting Terragrunt and validate it
RUN curl -sLO https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
 && curl -sLO https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS \
 && grep terragrunt_linux_amd64 SHA256SUMS | sha256sum -c - \
 && mv terragrunt_linux_amd64 terragrunt && chmod +x terragrunt \
 && rm SHA256SUMS

# Getting AWS CLI
RUN curl -sLO https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
 && unzip awscli-exe-linux-x86_64.zip \
 && ./aws/install -i /usr/local/aws-cli -b /usr/local/bin \
 && rm -rf aws awscli-exe-linux-x86_64.zip \
           /usr/local/aws-cli/v2/current/dist/aws_completer \
           /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
           /usr/local/aws-cli/v2/current/dist/awscli/examples \
 && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete


# Stage 2: runtime image
FROM alpine:3.16.0

# Adjust user/group and their id's from outside
# to prevent possible permission conflicts
ARG GID=1000
ARG UID=1000
ARG GROUP=user
ARG USER=user

# Create a regular user to run container in non-root mode
RUN addgroup -g ${GID} -S ${GROUP} \
 && adduser -h /home/${USER} \
            -s /bin/bash \
            -G ${GROUP} \
            -u ${UID} \
            -SDH ${USER}

# Copy binaries from the builder image
COPY --from=builder --chown=${USER}:${GROUP} /build/ /usr/local/bin/
COPY --from=builder --chown=${USER}:${GROUP} /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder --chown=${USER}:${GROUP} /usr/local/bin/ /usr/local/bin/
COPY --chown=${USER}:${GROUP} entrypoint.sh /usr/local/bin/entrypoint.sh

# Install glibc compatibility for Alpine
ARG GLIBC_VERSION=2.35-r0
RUN apk add --no-cache binutils curl \
 && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
 && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
 && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
 && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
 && apk add --no-cache glibc-${GLIBC_VERSION}.apk \
                       glibc-bin-${GLIBC_VERSION}.apk \
                       glibc-i18n-${GLIBC_VERSION}.apk \
 && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
 && apk --no-cache del binutils curl && rm -rf glibc-*.apk /var/cache/apk/*

# Switch current user from root to a regular
USER ${USER}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
