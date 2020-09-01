#!/bin/bash

echo "promoting the new version ${VERSION} to downstream repositories"

jx step create pr regex --regex "(?m)^FROM gcr.io/jenkinsxio/jx-cli-base:(?P<version>.*)$" --version ${VERSION} --files Dockerfile --repo https://github.com/jenkins-x/jx-cli.git

jx step create pr regex --regex "(?m)^FROM gcr.io/jenkinsxio/jx-cli-base:(?P<version>.*)$" --version ${VERSION} --files Dockerfile --repo https://github.com/jenkins-x/jx-git-operator.git

jx step create pr regex --regex "(?m)^FROM gcr.io/jenkinsxio/jx-cli-base:(?P<version>.*)$" --version ${VERSION} --files Dockerfile --repo https://github.com/jenkins-x/jx-promote.git
