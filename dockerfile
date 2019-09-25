LABEL maintainer="acamerlo@vmware.com"
LABEL description="python+ansible+terraform+aviroles image"
FROM alpine:3.7

ENV ANSIBLE_VERSION 2.6.6

ENV BUILD_PACKAGES \
  bash \
  curl \
  tar \
  openssh-client \
  sshpass \
  git \
  python \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-yaml \
  ca-certificates


RUN set -x && \
    \
    echo "==> Adding build-dependencies..."  && \
    apk --update add --virtual build-dependencies \
      gcc \
      musl-dev \
      libffi-dev \
      openssl-dev \
      python-dev && \
    \
    echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    echo "==> Adding Python runtime..."  && \
    apk add --no-cache ${BUILD_PACKAGES} && \
    pip install --upgrade pip && \
    pip install python-keyczar docker-py && \
    \
    echo "==> Installing Ansible..."  && \
    pip install ansible==${ANSIBLE_VERSION} && \
    \
    echo "==> Cleaning up..."  && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/* && \
    \
    echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

ENV PS1="ubaca\w>"
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library
RUN echo 'alias ll="ls -lrt"' >> ~/.bashrc


RUN pip install avisdk
RUN ansible-galaxy install avinetworks.avisdk
RUN ansible-galaxy install avinetworks.docker,master
RUN ansible-galaxy install avinetworks.avicontroller,master

ENV TER_VER="0.12.9"
RUN wget https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip
RUN unzip terraform_${TER_VER}_linux_amd64.zip
RUN mv terraform /usr/local/bin/
RUN rm terraform_${TER_VER}*
#WORKDIR /ansible/playbooks


ENTRYPOINT ["/bin/bash"]

