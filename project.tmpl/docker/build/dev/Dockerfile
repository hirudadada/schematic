ARG base_image_repo=quay.io/hirudadada/schematic_base
ARG base_image_tag
FROM ${base_image_repo}:${base_image_tag}

ARG schematic_home=/home/schematic
ENV SCHEMATIC_HOME=${schematic_home}

ARG env_home=/home/env
ENV ENV_HOME=${env_home}

ARG app_home=/home/app
ENV APP_HOME=${app_home}
ENV HISTFILE=${APP_HOME}/.bash_history

# RUN apk -U upgrade && \
RUN mkdir -p ${APP_HOME}

WORKDIR ${APP_HOME}

COPY . .

# RUN apk add --no-cache \
#     freetds-dev mariadb-dev libpq-dev \
#     gcompat curl make  

ARG project
ARG app
ARG version
ARG release_tag
ARG build_number
ARG app_source
ARG authors
ARG image_repo
ARG image_tag
ARG base_image_repo
ARG base_image_tag
ARG created_at

ENV PROJECT_NAME=#{projecct}
ENV APP_NAME=#{app}
ENV APP_VERSION=${version}-${release_tag}.${build_number}

LABEL org.opencontainers.image.title=${project}-${app} \
    org.opencontainers.image.version=${version}-${release_tag}.${build_number} \
    org.opencontainers.image.authors=${authors} \
    org.opencontainers.image.source=${app_source} \
    org.opencontainers.image.created=${created_at} \
    \
    org.hirudadada.project=${project} \
    org.hirudadada.app=${app} \
    org.hirudadada.app.release=${version}-${release_tag}.${build_number} \
    org.hirudadada.app.version=${version} \
    org.hirudadada.app.release_tag=${release_tag} \
    org.hirudadada.app.build_number=${build_number} \
    org.hirudadada.maintainer=${authors} \
    \
    org.hirudadada.image.repo=${image_repo} \
    org.hirudadada.image.tag=${image_tag} \
    org.hirudadada.image.name=${image_repo}:${image_tag} \
    \
    org.hirudadada.base_image.repo=${base_image_repo} \
    org.hirudadada.base_image.tag=${base_image_tag} \
    org.hirudadada.base_image.name=${base_image_repo}:${base_image_tag}

