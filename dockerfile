FROM alpine:3.12.8
LABEL maintainer="acamerlo@vmware.com"
LABEL description="alpine 3.12.8, ansible2.9.18-r0 + aviroles + avisdk, terraform 1.1.2, docker cli 20.10.10"

ENV BUILD_PACKAGES \
  bash \
  curl \
  tar \
  openssh-client \
  openssh \
  sshpass \
  git \
  py-pip \
  ca-certificates\
  ansible=2.9.18-r0\
  go\
  make

RUN echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    apk add --no-cache ${BUILD_PACKAGES} && \
    \
    echo "==> Cleaning up..."  && \
    rm -rf /var/cache/apk/* && \
    \
    echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library

RUN pip install avisdk
RUN ansible-galaxy install avinetworks.avisdk
RUN ansible-galaxy install avinetworks.docker,master
RUN ansible-galaxy install avinetworks.avicontroller,master

ENV TER_VER="1.1.2"
RUN wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip
RUN unzip terraform_${TER_VER}_linux_amd64.zip
RUN mv terraform /usr/local/bin/
RUN rm terraform_${TER_VER}*

ENV DOCKERVERSION=20.10.10
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

ENV GOPATH /root/go
ENV PATH ${GOPATH}/bin:/usr/local/go/bin:$PATH
ENV GOBIN $GOROOT/bin
ENV GO111MODULE on
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin


WORKDIR /home
RUN echo 'alias ll="ls -lrt"' >> ~/.bashrc
ENV PS1="alpaca\w>"
ENTRYPOINT ["/bin/bash"]