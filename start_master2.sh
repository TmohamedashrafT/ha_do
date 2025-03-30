#!/bin/bash

hdfs --daemon start journalnode;
echo "2" >  /home/hadoop/zookeeper/data/myid;
zkServer.sh start;
while true; do
    if curl -s "http://master1:9870/jmx" | grep -q "NameNode"; then
            echo "NameNode is active on master1. Proceeding...";
            break;
    else
            echo "Waiting for NameNode on master1...";
            sleep 5;
        fi;
    done;
	
if [ ! -d "/tmp/hadoop-hadoop/dfs/name/current" ]; then 
  echo "Formatting NameNode on $(hostname)..."; 
  hdfs namenode -bootstrapStandby;
else 
  echo "NameNode already formatted, skipping..."; 
fi; 


echo "All JournalNodes are active. Starting NameNode on $(hostname)...";
hdfs --daemon start namenode;

echo "Starting ZKFC...";
hdfs --daemon start zkfc;

echo "Starting ResourceManager...";
yarn --daemon start resourcemanager;

echo "All services started.";
tail -f /dev/null;
