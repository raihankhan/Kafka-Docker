# Kafka-Docker

[Kafka raft mode](https://github.com/apache/kafka/tree/trunk/raft)

Docker Image for Kafka 3.1.0 : [raihankhanraka/kafka-kraft:2.8.1](https://hub.docker.com/layers/258396924/raihankhanraka/kafka-kraft/2.8.1/images/sha256-9c93d111ce139f7840802342f03e8b1d177db1f9c80a38ea2520ec2d4628c725?context=repo)

Docker Image for Kafka 3.1.0 : [raihankhanraka/kafka-kraft:3.0.1](https://hub.docker.com/layers/kafka-kraft/raihankhanraka/kafka-kraft/3.0.1/images/sha256-0c7cb9e152743a4be9289f1426756aa14728fa724b40cbee785e0ebac789a22e?context=repo)

Docker Image for Kafka 3.2.0 : [raihankhanraka/kafka-kraft:3.2.0](https://hub.docker.com/layers/kafka-kraft/raihankhanraka/kafka-kraft/3.2.0/images/sha256-8a42f2447d38fc63d286563046726b8aee9c201f4dc8851abdff1814dd10fa5a?context=repo)

Build Your own Image:

```bash
export DOCKER_USERNAME=<your docker username>
export VERSION=<desired kafka version>
cd Kafka \
&& docker build --build-arg KAFKA_VERSION=$VERSION -t $DOCKER_USERNAME/kafka-kraft:$VERSION . \
&& docker push $DOCKER_USERNAME/kafka-kraft:$VERSION
```

Make sure to set these environment variables while deploying `kafka.yaml` in kubernetes:

- REPLICAS: should be equal to number of replicas, this will set node roles `controller,broker` in all the kafka nodes. Each node will be acting as both controller and broker.
- SERVICE: Kubernetes service which will be used to connect to the kafka nodes (pods).
- NAMESPACE: kubernetes namespace where the pods will be deployed.
- SHARE_DIR : directory where kafka data will be stored (log directory). example - `/var/log/kafka`. Do not set `/mnt/kafka` as SHARE_DIR. 
