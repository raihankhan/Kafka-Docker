if [[ ! -f "$DATA_DIR/cluster_id" && "$ID" = "0" ]]; then
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $DATA_DIR/cluster_id
else
    CLUSTER_ID=$(cat $DATA_DIR/cluster_id)
fi


else
  rm -rf $DATA_DIR/$ID/__cluster_metadata-0
fi


---------------
LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093"
ADVERTISED_LISTENERS="PLAINTEXT://$SERVICE.$NAMESPACE.svc.cluster.local:9092"

CONTROLLER_QUORUM_VOTERS=""
for i in $( seq 0 $REPLICAS); do
if [[ $i != $REPLICAS ]]; then
CONTROLLER_QUORUM_VOTERS="$CONTROLLER_QUORUM_VOTERS$i@$NODE-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9093,"
else
CONTROLLER_QUORUM_VOTERS=${CONTROLLER_QUORUM_VOTERS::-1}
fi
done