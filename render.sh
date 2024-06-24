#!/bin/bash

#####CONFIG HERE#####
N_NODES=3
SLEEP=1
#####################

> manifest/agents.yaml

for i in $(seq 1 $N_NODES); do
  echo "apiVersion: v1
kind: Pod
metadata:
  name: monlat-agent-$i
spec:
  serviceAccount: monlat
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
      sleep 5
      "nodeName_pod$i='$(kubectl get pod 'monlat-agent-$i' -o jsonpath='{.spec.nodeName}')'"
      while [ -z \"\$nodeName_pod$i\" ]; do
        sleep 1
        "nodeName_pod$i='$(kubectl get pod 'monlat-agent-$i' -o jsonpath='{.spec.nodeName}')'"
      done
      $(for j in $(seq 1 $N_NODES); do if [ $i -ne $j ]; then echo "        "IP$j='$(kubectl get pod' monlat-agent-$j '-o jsonpath='{.status.podIP}')'" && "nodeName_pod$j='$(kubectl get pod' monlat-agent-$j '-o jsonpath='{.spec.nodeName}')'"\"; "; fi; done)
      count=0
      while true; do
        $(for j in $(seq 1 $N_NODES); do if [ $i -ne $j ]; then echo "        "IP$j='$(kubectl get pod' monlat-agent-$j '-o jsonpath='{.status.podIP}')'" && "nodeName_pod$j='$(kubectl get pod' monlat-agent-$j '-o jsonpath='{.spec.nodeName}')'" && echo \"latency_between_nodes{from=\\\""\$nodeName_pod$i"\\\",to=\\\""\$nodeName_pod$j"\\\"} \$(ping -c 1 "\$IP$j" | grep 'time=' | awk -F'time=' '{print \$2}' | awk '{print \$1}')\"; "; fi; done)
        count=\$((count+1))
        if [ \"\$count\" -eq 10 ]; then break; fi
        sleep $SLEEP;
      done
      while true; do
        $(for j in $(seq 1 $N_NODES); do if [ $i -ne $j ]; then echo "        echo \"latency_between_nodes{from=\\\""\$nodeName_pod$i"\\\",to=\\\""\$nodeName_pod$j"\\\"} \$(ping -c 1 "\$IP$j" | grep 'time=' | awk -F'time=' '{print \$2}' | awk '{print \$1}')\"; "; fi; done)
        sleep $SLEEP;
      done
  nodeSelector:
    monlat-node: node$i
---" >> manifest/agents.yaml
done
