#!/bin/bash




hdfs --daemon start datanode;
yarn --daemon start nodemanager;

tail -f /dev/null
