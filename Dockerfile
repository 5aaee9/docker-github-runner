FROM ubuntu:22.04 as env

ARG GITHUB_RUNNER_VERSION=2.317.0
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /root
RUN apt-get update && apt install wget -y
RUN wget https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && rm -f actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && sed -i '3,9d' ./config.sh \
    && sed -i '3,8d' ./run.sh

FROM ubuntu:22.04 as runner

ARG DEBIAN_FRONTEND=noninteractive
ENV KMS_SERVER_ADDR ""
ENV RUNNER_REGISTER_TO ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""
ENV ADDITIONAL_PACKAGES ""
ENV ADDITIONAL_FLAGS ""
ENV GOPROXY ""

# Install deps from https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2204-Readme.md

RUN apt-get update \
    && apt-get install -y \
      libcurl4-gnutls-dev gettext build-essential python3-pip cmake clang psmisc software-properties-common git \
      acl aria2 autoconf automake binutils bison brotli bzip2 coreutils curl dbus dnsutils dpkg dpkg-dev fakeroot \
      file findutils flex fonts-noto-color-emoji ftp g++ gcc gnupg2 haveged imagemagick iproute2 iputils-ping \
      jq lib32z1 libc++-dev libc++abi-dev libc6-dev libcurl4 libgbm-dev libgconf-2-4 libgsl-dev libgtk-3-0 \
      libmagic-dev libmagickcore-dev libmagickwand-dev libsecret-1-dev libsqlite3-dev libssl-dev libtool libunwind8 \
      libxkbfile-dev libxss1 libyaml-dev locales lz4 m4 wget mediainfo mercurial net-tools netcat openssh-client \
      p7zip-full p7zip-rar parallel pass patchelf pigz pkg-config pollinate python-is-python3 rpm rsync shellcheck \
      sphinxsearch sqlite3 ssh sshpass subversion sudo swig tar telnet texinfo time tk tzdata unzip upx wget xorriso \
      xvfb xz-utils zip zsync \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER root
WORKDIR /root/

COPY --from=env /root/ /root/
RUN  /root/bin/installdependencies.sh

# Allow custom cache server
# https://gha-cache-server.falcondev.io/getting-started
RUN sed -i 's/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x43\x00\x41\x00\x43\x00\x48\x00\x45\x00\x5F\x00\x55\x00\x52\x00\x4C\x00/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x43\x00\x41\x00\x43\x00\x48\x00\x45\x00\x5F\x00\x4F\x00\x52\x00\x4C\x00/g' /root/bin/Runner.Worker.dll

COPY entrypoint.sh runsvc.sh ./
RUN sudo chmod u+x ./entrypoint.sh ./runsvc.sh

ENTRYPOINT ["./entrypoint.sh"]
