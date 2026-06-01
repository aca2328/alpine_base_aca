FROM alpine:3.22.4

LABEL maintainer="antoine.camerlo@broadcom.com"
LABEL description="Alpine Linux, ansible + aviroles + avisdk, terraform, docker cli, pandas"

# Define version environment variables
ARG TARGETARCH
ARG TARGETOS=linux

ENV GO_VERSION=1.26.3
ENV TER_VER=1.15.5
ENV DOCKERVERSION=29.5.2

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

# Install Ansible collections
RUN ansible-galaxy collection install vmware.alb

# Clean up
RUN apk del .build-deps && \
    rm -rf /var/cache/apk/*

WORKDIR /home
RUN echo 'alias ll="ls -lrt"' >> ~/.bashrc
ENV PS1="alpaca\w>"
ENTRYPOINT ["/bin/bash"]
