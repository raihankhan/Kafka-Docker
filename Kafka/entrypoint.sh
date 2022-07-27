#!/bin/bash

NODE_ID=${HOSTNAME:6}


LISTENERS="SASL_PLAINTEXT://:9092,CONTROLLER://:9093"
ADVERTISED_LISTENERS="SASL_PLAINTEXT://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"
ENABLED_MECHANISM="PLAIN"
INTER_BROKER_PROTOCOL="PLAIN"
INTER_BROKER_SECURITY_PROTOCOL="SASL_PLAINTEXT"
SECURITY_AUTH="kafka.security.authorizer.AclAuthorizer"

#if [[ -z "$DISABLE_SECURITY" ]]; then
#  LISTENERS="SASL_PLAIN://:9092,CONTROLLER://:9093"
#  ADVERTISED_LISTENERS="SASL_PLAIN://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"
#fi

CONTROLLER_QUORUM_VOTERS=""
for i in $( seq 0 $REPLICAS); do
    if [[ $i != $REPLICAS ]]; then
        CONTROLLER_QUORUM_VOTERS="$CONTROLLER_QUORUM_VOTERS$i@kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9093,"
    else
        CONTROLLER_QUORUM_VOTERS=${CONTROLLER_QUORUM_VOTERS::-1}
    fi
done

mkdir -p $SHARE_DIR/$NODE_ID

if [[ ! -f "$SHARE_DIR/cluster_id" && "$NODE_ID" = "0" ]]; then
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $SHARE_DIR/cluster_id
else
    CLUSTER_ID=$(cat $SHARE_DIR/cluster_id)
fi

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$SHARE_DIR/$NODE_ID+" \
-e "s+^sasl.enabled.mechanisms=.*+sasl.enabled.mechanisms=$ENABLED_MECHANISM+" \
-e "s+^inter.broker.listener.name=.*+inter.broker.listener.name=$INTER_BROKER_SECURITY_PROTOCOL+" \
-e "s+^sasl.mechanism.inter.broker.protocol=.*+sasl.mechanism.inter.broker.protocol=$INTER_BROKER_PROTOCOL+" \
-e "s+^security.inter.broker.protocol=.*+security.inter.broker.protocol=$INTER_BROKER_SECURITY_PROTOCOL+" \
-e "s+^authorizer.class.name=.*+authorizer.class.name=$SECURITY_AUTH+"
/opt/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /opt/kafka/config/kraft/server.properties

kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties

exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties

#-e "s+^listener.name.sasl_ssl.plain.sasl.jaas.config=.*+listener.name.sasl_ssl.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="admin-password";+" \
