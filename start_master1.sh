#!/bin/bash

if [ ! -d "/home/hadoop/packages/ha_do" ]; then
  sudo apt install git -y
  sudo git clone https://github.com/TmohamedashrafT/ha_do.git /home/hadoop/packages/ha_do
fi

if [ ! -d "/home/hadoop/packages/hadoop-3.3.6" ]; then  
  sudo tar --owner=hadoop -xzf /home/hadoop/hadoop-3.3.6.tar.gz -C /home/hadoop/packages
  sudo rm /home/hadoop/hadoop-3.3.6.tar.gz
	sudo cp /home/hadoop/packages/ha_do/core-site.xml /home/hadoop/packages/hadoop-3.3.6/etc/hadoop/
	sudo cp /home/hadoop/packages/ha_do/hdfs-site.xml /home/hadoop/packages/hadoop-3.3.6/etc/hadoop/
	sudo cp /home/hadoop/packages/ha_do/mapred-site.xml /home/hadoop/packages/hadoop-3.3.6/etc/hadoop/
	sudo cp /home/hadoop/packages/ha_do/yarn-site.xml /home/hadoop/packages/hadoop-3.3.6/etc/hadoop/
fi

if [ ! -d "/home/hadoop/packages/zookeeper-3.8.4" ]; then
   sudo tar --owner=hadoop -xzf /home/hadoop/apache-zookeeper-3.8.4-bin.tar.gz -C /home/hadoop/packages
   sudo mv /home/hadoop/packages/apache-zookeeper-3.8.4-bin /home/hadoop/packages/zookeeper-3.8.4
   sudo rm /home/hadoop/apache-zookeeper-3.8.4-bin.tar.gz
   cp /home/hadoop/packages/ha_do/zoo.cfg /home/hadoop/packages/zookeeper-3.8.4/conf/
fi


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
