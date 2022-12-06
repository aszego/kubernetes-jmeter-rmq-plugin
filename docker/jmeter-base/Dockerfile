FROM alpine
LABEL maintainer="kaarol@it-flow.pl"

ENV JMETER_VERSION "5.5"

RUN apk update && \
    apk upgrade && \
    apk add --update openjdk8-jre wget tar bash && \
    wget https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    mkdir -p /opt/jmeter && \
    tar -zxf apache-jmeter-${JMETER_VERSION}.tgz -C /opt/jmeter/  --strip-components=1 && \
    rm -rf apache-jmeter-${JMETER_VERSION}.tgz && \
    rm -rf /var/cache/apk/* && \
    wget -O /usr/bin/tpl https://github.com/schneidexe/tpl/releases/download/v0.4.4/tpl-linux-amd64 && \
    chmod +x /usr/bin/tpl

RUN cd /opt/jmeter/lib/ext && \
    wget https://github.com/aliesbelik/jmeter-amqp-plugin/releases/download/v0.1.0/jmeter-amqp-plugin-0.1.0-jar-with-dependencies.jar

ENV JMETER_HOME /opt/jmeter
ENV PATH $PATH:$JMETER_HOME/bin
