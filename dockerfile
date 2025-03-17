FROM alpine:3.21.3

LABEL maintainer="antoine.camerlo@broadcom.com"
LABEL description="Alpine Linux, ansible + aviroles + avisdk, terraform, docker cli, pandas"

# Define version environment variables
ENV GO_VERSION=1.21.3
ENV TER_VER=1.11.2
ENV DOCKERVERSION=20.10.10

# Install necessary packages and build dependencies
RUN apk update && apk upgrade && \
    apk add --no-cache bash curl tar openssh-client openssh openssh-sftp-server sshpass git python3 py3-pip ca-certificates unzip make && \
    apk add --no-cache --virtual .build-deps gcc musl-dev libffi-dev openssl-dev python3-dev

# Create a virtual environment and install Python libraries
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install ansible avisdk pandas

# Install Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip && \
    unzip -d /usr/local/bin terraform_${TER_VER}_linux_amd64.zip && \
    rm terraform_${TER_VER}_linux_amd64.zip

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz | tar --strip-components=1 -xz -C /usr/local/bin docker/docker

# Install Go
RUN wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

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