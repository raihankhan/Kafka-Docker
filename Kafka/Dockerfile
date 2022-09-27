FROM openjdk:11

ARG KAFKA_VERSION=3.2.3
ENV KAFKA_VERSION=${KAFKA_VERSION}
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka
ENV PATH=${PATH}:${KAFKA_HOME}/bin

LABEL name="kafka" version=${KAFKA_VERSION}

RUN apt-get update \
 && wget -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
 && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
 && rm -rf /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

COPY ./entrypoint.sh /opt/kafka/config
RUN ["chmod", "+x", "/opt/kafka/config/entrypoint.sh"]

EXPOSE 9092 9093

ENTRYPOINT ["/opt/kafka/config/entrypoint.sh"]