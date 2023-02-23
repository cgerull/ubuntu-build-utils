FROM ubuntu:22.04
LABEL MAINTAINER="CD-Minerva"

ENV TERM=xterm
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

# ENV SONAR_SCANNER_VERSION_ZIP=sonar-scanner-cli-4.0.0.1744-linux.zip
# ENV SONAR_SCANNER_VERSION=sonar-scanner-4.0.0.1744-linux
# ENV E2J2_SEARCHLIST=/etc,/usr/local/bin

ENV K8S_URL=https://dl.k8s.io/release
ENV KUBECTL_VERSION=1.26.1
ENV HELM_VERSION=3.11.1
ENV RANCHER_VERSION=2.7.0
ENV E2J2_VERSION=0.7.0
ENV PLUTO_VERSION=5.15.1
ENV ARGO_VERSION=3.4.5

USER root

# Update base system
RUN cat /etc/os-release && \
    apt-get update && \
    apt-get -y install apt-utils && \
    apt-get update --fix-missing && \
    apt-get -y upgrade && \
    apt-get -y install dialog locales iproute2 && \
    locale-gen en_US.UTF-8 && echo "LANG=en_US.UTF-8" > /etc/default/locale

# Install utility packages
RUN apt-get -y install ca-certificates \
     build-essential \
     git \
     jq \
     maven \
     curl \
     gnupg \
     software-properties-common \
     lsb-release \
     python3 \
     python3-pip \
 && update-ca-certificates \
 && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install docker and containerd suite
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
 && apt-get update \
 && apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

# Install kubectl
RUN curl -s -LO ${K8S_URL}/v${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# Install helm3
RUN curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz |tar xvz && \
    mv linux-$(dpkg --print-architecture)/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-$(dpkg --print-architecture) && \
    helm plugin install --version master https://github.com/sonatype-nexus-community/helm-nexus-push.git && \
    helm version
# Patch nexus plugin to prevent undeclared vars
RUN sed -ri 's/^(declare (USERNAME|PASSWORD))$/\1=""/g' $HOME/.local/share/helm/plugins/helm-nexus-push.git/push.sh

# Install trivy
RUN curl -sL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null \
 && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
 && apt-get update \
 && apt-get install trivy

# Install E2J2
RUN pip install --upgrade pip \
 && pip install e2j2==${E2J2_VERSION}

# Install ArgoWorkflows
RUN curl -sLO  https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-$(dpkg --print-architecture).gz && \
    gunzip argo-linux-$(dpkg --print-architecture).gz && \
    mv argo-linux-$(dpkg --print-architecture) /usr/bin/argo && \
    chmod a+x /usr/bin/argo && \
    argo version

# Install pluto (https://github.com/FairwindsOps/pluto/releases)
RUN curl -sL https://github.com/FairwindsOps/pluto/releases/download/v${PLUTO_VERSION}/pluto_${PLUTO_VERSION}_linux_$(dpkg --print-architecture).tar.gz | tar xvz pluto && \
    mv pluto /usr/bin/pluto && \
    chmod a+x /usr/bin/pluto && \
    rm -f LICENSE README.md && \
    pluto version

HEALTHCHECK --interval=15s --timeout=5s --retries=5 CMD echo up
ENTRYPOINT /bin/bash
