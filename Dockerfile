FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="Alex Manroe <lanxic[at]gmail.com>"

# Command line tools only
# https://developer.android.com/studio/index.html
ENV ANDROID_SDK_TOOLS_VERSION 10406996
ENV ANDROID_SDK_TOOLS_CHECKSUM 8919e8752979db73d8321e9babe2caedcc393750817c1a5f56c128ec442fb540

ENV GRADLE_VERSION 7.5.1

ENV ANDROID_HOME "/opt/android-sdk-linux"
ENV ANDROID_SDK_ROOT $ANDROID_HOME
ENV PATH $PATH:$ANDROID_HOME/cmdline-tools:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/platform-tools

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.UTF-8

# Add base environment
RUN apt-get -qq update \
    && apt-get -qqy --no-install-recommends install \
    apt-utils \
    build-essential \
    openjdk-18-jdk \
    openjdk-18-jre-headless \
    software-properties-common \
    libssl-dev \
    libffi-dev \
    python3-dev \
    cargo \
    pkg-config\  
    libstdc++6 \
    libpulse0 \
    libglu1-mesa \
    openssh-server \
    zip \
    unzip \
    curl \
    lldb \
    git > /dev/null \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
   
# Download and unzip Android SDK Tools
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip > /tools.zip \
    && echo "$ANDROID_SDK_TOOLS_CHECKSUM ./tools.zip" | sha256sum -c \
    && unzip -qq /tools.zip -d $ANDROID_HOME \
    && rm -v /tools.zip

# Accept licenses
RUN mkdir -p $ANDROID_HOME/licenses/ \
    && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license --licenses \
    && yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --licenses --sdk_root=${ANDROID_SDK_ROOT}

# Add non-root user 
RUN groupadd -r builderApps \
    && useradd --no-log-init -r -g builderApps builderApps \
    && mkdir -p /home/builderApps/.android \
    && mkdir -p /home/builderApps/app \
    && touch /home/builderApps/.android/repositories.cfg \
    && chown --recursive builderApps:builderApps /home/builderApps \
    && chown --recursive builderApps:builderApps /home/builderApps/app \
    && chown --recursive builderApps:builderApps $ANDROID_HOME

# Set non-root user as default      
ENV HOME /home/builderApps
USER builderApps
WORKDIR $HOME/app

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
SHELL ["/bin/bash", "-c"]   

# Install Android packages
ADD packages.txt $HOME

# Update sdkmanager
RUN $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --update \
    && while read -r pkg; do PKGS="${PKGS}${pkg} "; done < $HOME/packages.txt \
    && $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} $PKGS \
    && rm $HOME/packages.txt

# Install Gradle
RUN source "${HOME}/.sdkman/bin/sdkman-init.sh" \
    && sdk install gradle ${GRADLE_VERSION}
