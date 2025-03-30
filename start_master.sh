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

hdfs --daemon start journalnode;

case "$(hostname)" in
    master1)
        echo "1" > /home/hadoop/zookeeper/data/myid
        ;;
    master2)
        echo "2" > /home/hadoop/zookeeper/data/myid
        ;;
    master3)
        echo "3" > /home/hadoop/zookeeper/data/myid
        ;;
    *)
        echo "Unknown hostname: $(hostname)"
        ;;
esac

zkServer.sh start;

for node in master1 master2 master3; do
  echo "Checking JournalNode on $node...";
  while ! curl -s "http://$node:8480/jmx" | grep -q "JournalNode"; do
    echo "Waiting for JournalNode on $node...";
    sleep 5;
  done;
  echo "JournalNode is active on $node.";
done;

if [[ "$(hostname)" == "master1" ]]; then
    if [ ! -d "/tmp/hadoop-hadoop/dfs/name/current" ]; then 
        echo "Formatting NameNode on master1..."; 
        hdfs namenode -format; 
    else 
        echo "NameNode already formatted, skipping..."; 
    fi
	if echo "ls /hadoop-ha" | zkCli.sh -server master1:2181 | grep -q ashrafcluster; then
		echo "ZKFC already formatted, skipping...";
	else
		echo "Formatting ZKFC...";
		hdfs zkfc -formatZK;
	fi;
else
    echo "This is not master1, skipping NameNode formatting."
fi

if [[ "$(hostname)" != "master1" ]]; then
    while true; do
        if curl -s "http://master1:9870/jmx" | grep -q "NameNode"; then
            echo "NameNode is active on master1. Proceeding...";
            break;
        else
            echo "Waiting for NameNode on master1...";
            sleep 5;
        fi;
    done;
else
    echo "This is master1, skipping NameNode check."
fi

if [[ "$(hostname)" != "master1" ]]; then
if [ ! -d "/tmp/hadoop-hadoop/dfs/name/current" ]; then 
  echo "Formatting NameNode on $(hostname)..."; 
  hdfs namenode -bootstrapStandby;
else 
  echo "NameNode already formatted, skipping..."; 
fi; 
fi;


echo "All JournalNodes are active. Starting NameNode on $(hostname)...";
hdfs --daemon start namenode;

echo "Starting ZKFC...";
hdfs --daemon start zkfc;

echo "Starting ResourceManager...";
yarn --daemon start resourcemanager;

echo "All services started.";
tail -f /dev/null;