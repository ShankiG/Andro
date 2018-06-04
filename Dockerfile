FROM xmartlabs/jenkins-android:latest
ENV ANDROID_HOME /opt/android-sdk-linux
MAINTAINER "Andy Hui" <andyhui@maaii.com>
USER root
# Open write permission
RUN find /opt/android-sdk-linux -type d -exec chmod 777 {} \;

# Java Version and other ENV
ENV JENKINS_REMOTING_VERSION=3.10 \
    HOME=/home/jenkins

RUN which java

# Install jenkins dependencies
RUN apt-get update -y \
    && apt-get install -y openssh-client doxygen git sudo curl \
    && mkdir /home/jenkins \
    #&& useradd -m -p jenkins -s /bin/bash jenkins \
    && echo "export TZ=Asia/Hong_Kong" >> /home/jenkins/.bashrc \
    && echo "jenkins soft nofile 50000" >> /etc/security/limits.conf \
    && echo "jenkins hard nofile 50000" >> /etc/security/limits.conf \
    && echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo 'Defaults !requiretty' >> /etc/sudoers

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils

# --- Install required tools

RUN apt-get update -qq

# Base (non android specific) tools
# -> should be added to bitriseio/docker-bitrise-base

# shared gradle properties
RUN mkdir /home/jenkins/.gradle \
    && echo "artifactory_user=jenkins" >> /home/jenkins/.gradle/gradle.properties \
    && echo "artifactory_password=jenkins" >> /home/jenkins/.gradle/gradle.properties \
    && echo "artifactory_contextUrl=http://artifactory.dev.maaii.com:8081/artifactory" >> /home/jenkins/.gradle/gradle.properties \
    && chown -R jenkins:jenkins /home/jenkins/.gradle


# jnlp
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_REMOTING_VERSION}/remoting-${JENKINS_REMOTING_VERSION}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave.sh /usr/local/bin/jenkins-slave.sh

RUN apt-get clean

RUN cd /opt \
    && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O android-sdk-tools.zip \
    RUN echo y \
	&& unzip -q android-sdk-tools.zip -d ${ANDROID_HOME} \
    && rm android-sdk-tools.zip

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

RUN sdkmanager --list

# Accept licenses before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file

#RUN yes | sdkmanager --licenses

# Platform tools
#RUN sdkmanager "emulator" "tools" "platform-tools"

#Install NDK
RUN yes | sdkmanager \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" \
	"platforms;android-27" \
    "platforms;android-26" \
	"build-tools;27.0.3" \
    "build-tools;26.0.2" \
	"system-images;android-26;google_apis;x86" \
	"add-ons;addon-google_apis-google-24" \
	"add-ons;addon-google_apis-google-23" \
	ndk-bundle

#RUN echo y | sdkmanager "add-ons;addon-google_apis-google-24" "cmake;3.6.4111459" ndk-bundle \


#Show sdk Package
RUN sdkmanager --list


# ------------------------------------------------------
# --- Cleanup and rev num

# Cleaning
RUN apt-get clean
# Install 0.30.1 Conanls
RUN pip install -q conan==0.30.1
RUN pip install -q conan_package_tools


USER jenkins

VOLUME /home/jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave.sh"]
