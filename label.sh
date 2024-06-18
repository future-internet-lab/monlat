#!/bin/bash

########## CONFIG ##########
OPTION=$1
############################

nodes=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
node_array=($nodes)
counter=1

if [ $OPTION == "add" ]; then
    for node in "${node_array[@]}"
    do
        echo "Labeling $node with monitor-latency-node=$node"
        kubectl label nodes $node monitor-latency-node=$node --overwrite
        counter=$((counter+1))
    done
    kubectl get nodes --show-labels=true
elif [ $OPTION == "delete" ]; then
    for node in "${node_array[@]}"
    do
        echo "Deleting $node with monitor-latency-node=$node"
        kubectl label nodes $node monitor-latency-node-
        counter=$((counter+1))
    done
    kubectl get nodes --show-labels=true
fi
