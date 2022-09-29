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
ADVERTISED_LISTENERS=${advertised_listeners}
CONTROLLER_QUORUM_VOTERS=${controller_quorum_voters}
CLUSTER_ID=${cluster_id}
DATA_DIR=${log_dirs}

if [[ ! -d "$DATA_DIR/$ID" ]]; then
  mkdir -p $DATA_DIR/$ID
  echo "Created kafka data directory at $DATA_DIR/$ID"
else
  echo "Deleting old metadata..."
  if [[ -d "$DATA_DIR/$ID/__cluster_metadata-0" ]]; then
     rm -rf $DATA_DIR/$ID/__cluster_metadata-0
  fi
  if [[ -f "$DATA_DIR/$ID/meta.properties" ]]; then
    rm $DATA_DIR/$ID/meta.properties
  fi
fi

sed -e "s+^node.id=.*+node.id=$ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$DATA_DIR/$ID+" \
/opt/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /opt/kafka/config/kraft/server.properties

kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties

echo "Starting Kafka Server"
exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties