if [[ ! -f "$DATA_DIR/cluster_id" && "$ID" = "0" ]]; then
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $DATA_DIR/cluster_id
else
    CLUSTER_ID=$(cat $DATA_DIR/cluster_id)
fi


else
  rm -rf $DATA_DIR/$ID/__cluster_metadata-0
fi
