#!/bin/bash
echo "Starting JournalNode on $(hostname)...";
hdfs --daemon start journalnode;

echo "1" > /home/hadoop/zookeeper/data/myid;
zkServer.sh start;

echo "Waiting for JournalNode on $(hostname) to be ready...";
while ! curl -s "http://localhost:8480/jmx" | grep -q "JournalNode"; do
  echo "Waiting for JournalNode on $(hostname)...";
  sleep 5;
done;

echo "JournalNode on $(hostname) is running.";

for node in master1 master2 master3; do
  echo "Checking JournalNode on $node...";
  while ! curl -s "http://$node:8480/jmx" | grep -q "JournalNode"; do
    echo "Waiting for JournalNode on $node...";
    sleep 5;
  done;
  echo "JournalNode is active on $node.";
done;


if [ ! -d "/tmp/hadoop-hadoop/dfs/name/current" ]; then 
  echo "Formatting NameNode on $(hostname)..."; 
  hdfs namenode -format; 
else 
  echo "NameNode already formatted, skipping..."; 
fi; 

if echo "ls /hadoop-ha" | zkCli.sh -server master1:2181 | grep -q ashrafcluster; then
  echo "ZKFC already formatted, skipping...";
else
  echo "Formatting ZKFC...";
  hdfs zkfc -formatZK;
fi;

echo "All JournalNodes are active. Starting NameNode on $(hostname)...";
hdfs --daemon start namenode;

echo "Starting ZKFC...";
hdfs --daemon start zkfc;

echo "Starting ResourceManager...";
yarn --daemon start resourcemanager;

echo "All services started.";
tail -f /dev/null;
