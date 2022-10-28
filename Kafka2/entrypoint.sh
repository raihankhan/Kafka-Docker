#!/bin/bash

operator_config="/opt/kafka/config/kafkaconfig/config.properties"
ssl_config="/opt/kafka/config/kafkaconfig/ssl.properties"
temp_operator_config="/opt/kafka/config/temp-config/config.properties"
temp_ssl_config="/opt/kafka/config/temp-config/ssl.properties"
temp_clientauth_config="/opt/kafka/config/temp-config/clientauth.properties"
controller_config="/opt/kafka/config/kraft/controller.properties"
broker_config="/opt/kafka/config/kraft/broker.properties"
server_config="/opt/kafka/config/kraft/server.properties"

cp $temp_operator_config $operator_config
if [[ -f $temp_ssl_config ]]; then
  cat $temp_ssl_config $operator_config > config.properties.updated
  mv config.properties.updated $operator_config
  cp $temp_ssl_config /opt/kafka/config
fi

if [[ -f $temp_clientauth_config ]]; then
  cp $temp_clientauth_config /opt/kafka/config
fi


while IFS='=' read -r key value
do
    key=$(echo $key | tr '.' '_')
    eval ${key}=\${value}
done < "$operator_config"

CLUSTER_ID=${cluster_id}
ID=${HOSTNAME##*-}
NODE=$(echo $HOSTNAME | rev | cut -d- -f1 --complement | rev )
CONTROLLER_NODE_COUNT=${controller_count}

delete_cluster_metadata() {
  NODE_ID=$1
  echo "Enter for metadata deleting node $NODE_ID"
  if [[ ! -d "$log_dirs/$NODE_ID" ]]; then
    mkdir -p "$log_dirs"/"$NODE_ID"
    echo "Created kafka data directory at "$log_dirs"/$NODE_ID"
  else
    echo "Deleting old metadata..."
    rm -rf $log_dirs/$NODE_ID/meta.properties
    if [[ -d "$metadata_log_dir/__cluster_metadata-0" ]]; then
       rm -rf $metadata_log_dir/meta.properties

    fi
  fi
}

AUTHFILE="/opt/kafka/config/kafka_server_jaas.conf"
sed -i "s/\<KAFKA_USER\>/"$KAFKA_USER"/g" $AUTHFILE
sed -i "s/\<KAFKA_PASSWORD\>/"$KAFKA_PASSWORD"/g" $AUTHFILE
cat $AUTHFILE
#export KAFKA_OPTS="-Djava.security.auth.login.config=$AUTHFILE"
export KAFKA_OPTS="$KAFKA_OPTS -Djava.security.auth.login.config=$AUTHFILE"

echo $KAFKA_OPTS

if [[ $process_roles = "controller" ]]; then

  delete_cluster_metadata $ID

  echo "node.id=$ID" >> /opt/kafka/config/kafkaconfig/config.properties

  sed -e "s+^log.dirs=.*+log.dirs=$log_dirs/$ID+" \
  /opt/kafka/config/kafkaconfig/config.properties > config.properties.updated
  mv config.properties.updated /opt/kafka/config/kafkaconfig/config.properties

  cat /opt/kafka/config/kafkaconfig/config.properties /opt/kafka/config/kraft/controller.properties | awk -F= '!seen[$1]++' > controller.properties.updated
  mv controller.properties.updated /opt/kafka/config/kraft/controller.properties

  if [[ -f "$ssl_config" ]]; then
      cat $ssl_config $controller_config | awk -F'=' '!seen[$1]++' > controller.properties.updated
      mv controller.properties.updated $controller_config
  fi

  kafka-storage.sh format -t "$CLUSTER_ID" -c /opt/kafka/config/kraft/controller.properties --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh /opt/kafka/config/kraft/controller.properties

elif [[ $process_roles = "broker" ]]; then
  ID=$(( ID + CONTROLLER_NODE_COUNT ))
  delete_cluster_metadata $ID

  echo "node.id=$ID" >> $operator_config

  sed -e "s+^log.dirs=.*+log.dirs=$log_dirs/$ID+" \
  $operator_config > $operator_config.updated
  mv $operator_config.updated $operator_config

  cat $operator_config $broker_config | awk -F'=' '!seen[$1]++' > $broker_config.updated
  mv $broker_config.updated $broker_config

  if [[ -f "$ssl_config" ]]; then
      cat $ssl_config $broker_config | awk -F'=' '!seen[$1]++' > $broker_config.updated
      mv $broker_config.updated $broker_config
  fi

  echo "Formatting broker properties"

  kafka-storage.sh format -t $CLUSTER_ID -c $broker_config --ignore-formatted

  echo "Starting Kafka Server"
  exec kafka-server-start.sh $broker_config

else [[ $process_roles = "controller,broker" ]]

  delete_cluster_metadata $ID

  echo "node.id=$ID" >> $operator_config
  sed -e "s+^log.dirs=.*+log.dirs=$log_dirs/$ID+" \
  $operator_config > $operator_config.updated
  mv $operator_config.updated $operator_config

  cat $operator_config $server_config | awk -F'=' '!seen[$1]++' > $server_config.updated
  mv $server_config.updated $server_config

  if [[ -f "$ssl_config" ]]; then
      cat $ssl_config $server_config | awk -F'=' '!seen[$1]++' > $server_config.updated
      mv $server_config.updated $server_config
  fi

  kafka-storage.sh format -t $CLUSTER_ID -c $server_config --ignore-formatted
  echo "Starting Kafka Server"
  exec kafka-server-start.sh $server_config
fi