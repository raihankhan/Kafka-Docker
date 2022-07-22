# Kafka-Docker

Docker Image for Kafka 3.1.0 : [raihankhanraka/kafka-kraft:3.0.1](https://hub.docker.com/layers/kafka-kraft/raihankhanraka/kafka-kraft/3.0.1/images/sha256-0c7cb9e152743a4be9289f1426756aa14728fa724b40cbee785e0ebac789a22e?context=repo)

Docker Image for Kafka 3.1.0 : [raihankhanraka/kafka-kraft:3.0.1](https://hub.docker.com/layers/kafka-kraft/raihankhanraka/kafka-kraft/3.0.1/images/sha256-0c7cb9e152743a4be9289f1426756aa14728fa724b40cbee785e0ebac789a22e?context=repo)

Docker Image for Kafka 3.2.0 : [raihankhanraka/kafka-kraft:3.2.0](https://hub.docker.com/layers/kafka-kraft/raihankhanraka/kafka-kraft/3.2.0/images/sha256-8a42f2447d38fc63d286563046726b8aee9c201f4dc8851abdff1814dd10fa5a?context=repo)

Build Your own Image:

```bash
export DOCKER_USERNAME=<your docker username>
export KAFKA_VERSION=<desired kafka version>
cd kafka \
&& docker build -t DOCKER_USERNAME/kafka-kraft:$KAFKA_VERSION KAFKA_VERSION=$KAFKA_VERSION . \
&& docker push <your DOCKER_USERNAME/kafka-kraft:<desired version>
```