# this is the build image so don't worry about using stuff...
FROM centos:7

RUN mkdir /out

RUN yum install -y unzip

# helmfile
ENV HELMFILE_VERSION 0.125.2
RUN curl -LO https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 && \
  mv helmfile_linux_amd64 /out/helmfile && \
  chmod +x /out/helmfile

# kubectl
ENV KUBECTL_VERSION 1.16.0
RUN curl -LO  https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
  mv kubectl /out/kubectl && \
  chmod +x /out/kubectl

# helm 3
ENV HELM3_VERSION 3.2.4
RUN curl -f -L https://get.helm.sh/helm-v${HELM3_VERSION}-linux-386.tar.gz | tar xzv && \
    mv linux-386/helm /out/

# terraform
ENV TERRAFORM 0.12.17
RUN curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM}/terraform_${TERRAFORM}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM}_linux_amd64.zip && \
  chmod +x terraform && mv terraform /out && rm terraform_${TERRAFORM}_linux_amd64.zip

FROM golang:1.13

RUN mkdir /out
RUN mkdir -p /go/src/github.com/jenkins-x

WORKDIR /go/src/github.com/jenkins-x

RUN git clone https://github.com/jenkins-x/bdd-jx.git && \
  cd bdd-jx && \
  make testbin && \
  mv build/bddjx /out/bddjx

# Adding the package path to local
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin


# use a multi stage image so we don't include all the build tools above
FROM google/cloud-sdk:slim


# need to copy the whole git source else it doesn't clone the helm plugin repos below
COPY --from=0 /out /usr/local/bin
COPY --from=1 /out /usr/local/bin

# this is the directory used in pipelines for home dir
ENV HOME /builder/home

# lets point jx plugins and helm at /home so we can pre-load binaries
ENV JX_HOME /home/.jx

# these env vars are used to install helm plugins
ENV XDG_CACHE_HOME /home/.cache
ENV XDG_CONFIG_HOME /home/.config
ENV XDG_DATA_HOME /home/.data

ENV PATH /usr/local/bin:/usr/local/git/bin:$PATH:/usr/local/gcloud/google-cloud-sdk/bin

ENV JX_HELM3 "true"

ENV DIFF_VERSION 3.1.1

RUN curl -f -Lo kpt https://storage.googleapis.com/kpt-dev/latest/linux_amd64/kpt && \
  chmod +x kpt && \
  mv kpt /usr/local/bin

RUN gsutil cp gs://config-management-release/released/latest/linux_amd64/nomos /usr/local/bin/nomos
RUN mkdir -p /home/.jx/plugins/bin/

#COPY helm-annotate/build/helm-annotate /home/.jx/plugins/bin/helmfile-0.0.11

RUN cp /usr/local/bin/helm /home/.jx/plugins/bin/helm-3.2.1 && \
    cp /usr/local/bin/helmfile /home/.jx/plugins/bin/helmfile-0.115.0 && \
    rm /usr/local/bin/helm /usr/local/bin/helmfile && \
    ln -s /home/.jx/plugins/bin/helm-3.2.1 /usr/local/bin/helm && \
    ln -s /home/.jx/plugins/bin/helm-annotate-0.0.11 /usr/local/bin/helm-annotate && \
    ln -s /home/.jx/plugins/bin/helmfile-0.115.0 /usr/local/bin/helmfile


RUN helm plugin install https://github.com/databus23/helm-diff --version ${DIFF_VERSION} && \
    helm plugin install https://github.com/aslafy-z/helm-git.git && \
    helm plugin install https://github.com/rawlingsj/helm-gcs
