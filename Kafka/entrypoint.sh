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
COMBINED_NODE_COUNT=${combined_count}
CONTROLLER_NODE_COUNT=${controller_count}
BROKER_NODE_COUNT=${broker_count}
CONTROLLER_LISTENER_NAMES=CONTROLLER

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

if [[ $process_roles = "controller" ]]; then
  ID=$(( ID + COMBINED_NODE_COUNT ))
  delete_cluster_metadata $ID

  sed -e "s+^node.id=.*+node.id=$ID+" \
  -e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
  -e "s+^listeners=.*+listeners=$LISTENERS+" \
  -e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
  -e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
  -e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
  /opt/kafka/config/kraft/server.properties > server.properties.updated \
  && mv server.properties.updated /opt/kafka/config/kraft/server.properties

  kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties
elif [[ $process_roles = "broker" ]]; then
  ID=$(( ID + COMBINED_NODE_COUNT + CONTROLLER_NODE_COUNT ))
  delete_cluster_metadata $ID

  sed -e "s+^node.id=.*+node.id=$ID+" \
  -e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
  -e "s+^listeners=.*+listeners=$LISTENERS+" \
  -e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
  -e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
  -e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
  /opt/kafka/config/kraft/broker.properties > broker.properties.updated \
  && mv broker.properties.updated /opt/kafka/config/kraft/broker.properties

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
  -e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
  /opt/kafka/config/kraft/server.properties > server.properties.updated \
  && mv server.properties.updated /opt/kafka/config/kraft/server.properties

  kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties
fi