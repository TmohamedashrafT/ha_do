#!/bin/bash


sudo rm /home/hadoop/apache-zookeeper-3.8.4-bin.tar.gz
sudo rm /home/hadoop/hadoop-3.3.6.tar.gz

hdfs --daemon start datanode
yarn --daemon start nodemanager

tail -f /dev/null
