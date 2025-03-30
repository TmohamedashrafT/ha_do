#!/bin/bash



# Ensure the /data directory exists
sudo wget https://drive.google.com/drive/folders/1vyvDaJK2_k3eUDp8rGZqu5GwK9lyS58U?usp=drive_link
# Download and extract Hadoop if not exists
if [ ! -d "/home/hadoop/packages/hadoop-3.3.6" ]; then
    echo "Downloading Hadoop..."
    sudo wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz 
    sudo tar --owner=hadoop -xzf hadoop-3.3.6.tar.gz
    sudo rm hadoop-3.3.6.tar.gz
fi

# Download and extract Zookeeper if not exists
if [ ! -d "/home/hadoop/packages/zookeeper-3.8.4" ]; then
    echo "Downloading Zookeeper..."
    sudo wget https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz
   sudo tar --owner=hadoop  -xzf apache-zookeeper-3.8.4-bin.tar.gz
   sudo mv apache-zookeeper-3.8.4-bin zookeeper-3.8.4
    sudo rm apache-zookeeper-3.8.4-bin.tar.gz
fi

# Keep the container running
exec bash