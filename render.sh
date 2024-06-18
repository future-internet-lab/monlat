#!/bin/bash

#####CONFIG HERE#####
N_NODES=3
SLEEP=2
#####################

> manifest/monitor-latency-agents.yaml

for i in $(seq 1 $N_NODES); do
  echo "apiVersion: v1
kind: Pod
metadata:
  name: monitor-latency-agent-$i
spec:
  serviceAccount: monitor-latency
  containers:
  - name: ping-container
    image: portainer/kubectl-shell:latest
    securityContext:
      runAsUser: 0
      runAsGroup: 0
    command:
    - /bin/sh
    - -c
    - |
      sleep 3
      while true; do
        $(for j in $(seq 1 $N_NODES); do if [ $i -ne $j ]; then echo "        "IP$j='$(kubectl get pod' monitor-latency-agent-$j '-o jsonpath='{.status.podIP}')'" && echo \"latency_between_nodes{from=\\\"node$i\\\",to=\\\"node$j\\\"} \$(ping -c 1 "\$IP$j" | grep 'time=' | awk -F'time=' '{print \$2}' | awk '{print \$1}')\"; "; fi; done)
        sleep $SLEEP;
      done
  nodeSelector:
    monitor-latency-node: node$i
---" >> manifest/monitor-latency-agents.yaml
done
