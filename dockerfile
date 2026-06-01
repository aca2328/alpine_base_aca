FROM alpine:3.22.4

LABEL maintainer="antoine.camerlo@broadcom.com"
LABEL description="Alpine Linux, ansible + aviroles + avisdk, terraform, docker cli, pandas"

# Define version environment variables
ARG TARGETARCH
ARG TARGETOS=linux

ENV GO_VERSION=1.26.3
ENV TER_VER=1.15.5
ENV DOCKERVERSION=29.5.2
ENV AVI_VERSIONS="32.1.1 31.2.2 30.2.7"

# Install necessary packages and build dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache bash curl tar openssh-client openssh openssh-sftp-server sshpass git python3 py3-pip ca-certificates unzip make && \
    apk add --no-cache --virtual .build-deps gcc musl-dev libffi-dev openssl-dev python3-dev

# Create a virtual environment and install Python libraries
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install ansible==13.7.0 avisdk==32.1.1 pandas==3.0.3

# Install Terraform
RUN case "${TARGETARCH}" in \
      amd64) TF_ARCH="amd64" ;; \
      arm64) TF_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    wget -q https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_${TF_ARCH}.zip && \
    unzip -d /usr/local/bin terraform_${TER_VER}_linux_${TF_ARCH}.zip && \
    rm terraform_${TER_VER}_linux_${TF_ARCH}.zip

# Install Docker CLI
RUN case "${TARGETARCH}" in \
      amd64) DOCKER_ARCH="x86_64" ;; \
      arm64) DOCKER_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKERVERSION}.tgz | tar --strip-components=1 -xz -C /usr/local/bin docker/docker

# Install Go
RUN case "${TARGETARCH}" in \
      amd64) GO_ARCH="amd64" ;; \
      arm64) GO_ARCH="arm64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    wget -q https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz && \
    rm go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=${GOPATH}/bin:${GOROOT}/bin:$PATH
ENV GOBIN=${GOROOT}/bin
ENV GO111MODULE=on
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# Configure Ansible
RUN mkdir -p /etc/ansible /ansible && \
    echo "[local]\nlocalhost" > /etc/ansible/hosts

ENV ANSIBLE_GATHERING=smart
ENV ANSIBLE_RETRY_FILES_ENABLED=false
ENV ANSIBLE_SSH_PIPELINING=True
ENV PYTHONPATH=/ansible/lib
ENV PATH=/ansible/bin:$PATH
ENV ANSIBLE_LIBRARY=/ansible/library

# Install vmware.alb Ansible collection for each supported AVI version
# Switch versions at runtime via: ANSIBLE_COLLECTIONS_PATH=/opt/avi-collections/<version>
RUN for AVI_VER in ${AVI_VERSIONS}; do \
      ansible-galaxy collection install "vmware.alb:${AVI_VER}" -p "/opt/avi-collections/${AVI_VER}"; \
    done

# Pre-seed Terraform AVI provider cache for each supported AVI version
# Terraform auto-selects the correct version based on required_providers constraints
ENV TF_PLUGIN_CACHE_DIR=/root/.terraform.d/plugin-cache
RUN case "${TARGETARCH}" in \
      amd64) TF_ARCH="amd64" ;; \
      arm64) TF_ARCH="arm64" ;; \
    esac && \
    for AVI_VER in ${AVI_VERSIONS}; do \
      DOWNLOAD_URL=$(curl -s "https://registry.terraform.io/v1/providers/vmware/avi/${AVI_VER}/download/linux/${TF_ARCH}" | python3 -c "import sys,json; print(json.load(sys.stdin)['download_url'])") && \
      PROVIDER_DIR="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/vmware/avi/${AVI_VER}/linux_${TF_ARCH}" && \
      mkdir -p "${PROVIDER_DIR}" && \
      curl -fsSL "${DOWNLOAD_URL}" -o /tmp/tf-avi.zip && \
      unzip -o /tmp/tf-avi.zip "terraform-provider-avi*" -d "${PROVIDER_DIR}" && \
      chmod +x "${PROVIDER_DIR}"/terraform-provider-avi* && \
      rm /tmp/tf-avi.zip; \
    done

# Clean up
RUN apk del .build-deps && \
    rm -rf /var/cache/apk/*

WORKDIR /home
RUN echo 'alias ll="ls -lrt"' >> ~/.bashrc
ENV PS1="alpaca\w>"
ENTRYPOINT ["/bin/bash"]
