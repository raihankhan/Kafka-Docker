#!/bin/bash

ID=${HOSTNAME##*-}
NODE=$(echo $HOSTNAME | rev | cut -d- -f1 --complement | rev )

configfile="/opt/kafka/serverconfig/config.properties"

while IFS='=' read -r key value
do
    key=$(echo $key | tr '.' '_')
    eval ${key}=\${value}
done < "$configfile"

LISTENERS=${listeners}
ADVERTISED_LISTENERS=${advertised_listeners},
CONTROLLER_QUORUM_VOTERS=${controller_quorum_voters}
CLUSTER_ID=${cluster_id}
DATA_DIR=${log_dirs}
METADATA_DIR=${metadata_log_dir}
CONTROLLER_NODE_COUNT=${controller_count}
CONTROLLER_LISTENERS=${controller_listener_names}
INTER_BROKER_LISTENERS=${inter_broker_listener_name}
LISTENER_SECURITY_PROTOCOL_MAP=${listener_security_protocol_map}

delete_cluster_metadata() {
  NODE_ID=$1
  echo "Enter for metadata deleting node $NODE_ID"
  if [[ ! -d "$DATA_DIR/$NODE_ID" ]]; then
    mkdir -p $DATA_DIR/"$NODE_ID"
    echo "Created kafka data directory at $DATA_DIR/$NODE_ID"
  else
    echo "Deleting old metadata..."
    if [[ -d "$DATA_DIR/$NODE_ID/__cluster_metadata-0" ]]; then
       rm -rf $DATA_DIR/$NODE_ID/__cluster_metadata-0
    fi
  fi
}


echo ${process_roles}

AUTHFILE="/opt/kafka/config/kafka_server_jaas.conf"
sed -i "s/\<KAFKA_USER\>/"$KAFKA_USER"/g" $AUTHFILE
sed -i "s/\<KAFKA_PASSWORD\>/"$KAFKA_PASSWORD"/g" $AUTHFILE
export KAFKA_OPTS="-Djava.security.auth.login.config=$AUTHFILE"

cat $AUTHFILE

if [[ $process_roles = "controller" ]]; then

  delete_cluster_metadata $ID

  sed -e "s+^node.id=.*+node.id=$ID+" \
  -e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
  -e "s+^listeners=.*+listeners=$LISTENERS+" \
  -e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
  -e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
  -e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENERS+" \
  /opt/kafka/config/kraft/controller.properties > controller.properties.updated
cat<< EOF >>controller.properties.updated
metadata.log.dir=$METADATA_DIR
listener.security.protocol.map=$LISTENER_SECURITY_PROTOCOL_MAP
sasl.enabled.mechanisms=PLAIN
sasl.mechanism.controller.protocol=PLAIN
sasl.mechanism.inter.broker.protocol=PLAIN
listener.name.sasl_plaintext.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=$KAFKA_USER password=$KAFKA_PASSWORD;
serviceName="kafka"
EOF
  mv controller.properties.updated /opt/kafka/config/kraft/controller.properties

  kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/controller.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/controller.properties

elif [[ $process_roles = "broker" ]]; then
  ID=$(( ID + CONTROLLER_NODE_COUNT ))
  delete_cluster_metadata $ID

  sed -e "s+^node.id=.*+node.id=$ID+" \
  -e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
  -e "s+^listeners=.*+listeners=$LISTENERS+" \
  -e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
  -e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
  -e "s+^inter.broker.listener.name=.*+inter.broker.listener.name=$INTER_BROKER_LISTENERS+" \
  /opt/kafka/config/kraft/broker.properties > broker.properties.updated

cat<< EOF >>broker.properties.updated
metadata.log.dir=$METADATA_DIR
listener.security.protocol.map=$LISTENER_SECURITY_PROTOCOL_MAP
sasl.enabled.mechanisms=PLAIN
sasl.mechanism.inter.broker.protocol=PLAIN
sasl.mechanism.controller.protocol=PLAIN
listener.name.sasl_plaintext.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=$KAFKA_USER password=$KAFKA_PASSWORD;
serviceName="kafka"
EOF

  mv broker.properties.updated /opt/kafka/config/kraft/broker.properties

  echo "Formatting broker properties"

  kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/broker.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/broker.properties

else [[ $process_roles = "controller,broker" ]]

  delete_cluster_metadata $ID

  sed -e "s+^node.id=.*+node.id=$ID+" \
  -e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
  -e "s+^listeners=.*+listeners=$LISTENERS+" \
  -e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
  -e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
  -e "s+^metadata.log.dir=.*+metadata.log.dir=$METADATA_DIR+" \
  -e "s+^listener.security.protocol.map=.*+listener.security.protocol.map=$LISTENER_SECURITY_PROTOCOL_MAP+" \
  /opt/kafka/config/kraft/server.properties > server.properties.updated \
  && mv server.properties.updated /opt/kafka/config/kraft/server.properties





  kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties
fi

#  -e "s+^listener.name.CONTROLLER.plain.sasl.jaas.config=.*+listener.name.CONTROLLER.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=$KAFKA_USER password=$KAFKA_PASSWORD user_admin=$KAFKA_PASSWORD;+"  \
