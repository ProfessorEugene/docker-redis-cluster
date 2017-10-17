#!/bin/sh

if [ "$1" = 'redis-cluster' ]; then
    for port in `seq 7000 7005`; do
      mkdir -p /redis-conf/${port}
      mkdir -p /redis-data/${port}

      if [ -e /redis-data/${port}/nodes.conf ]; then
        rm /redis-data/${port}/nodes.conf
      fi
    done

    #use host networking to set up the cluster
    IP=`ifconfig | grep "inet addr" | grep -v "127.0.0.1" | grep -v "17" | cut -f2 -d ":" | cut -f1 -d " "`
    export BIND_IP=${IP}
    for port in `seq 7000 7005`; do
      PORT=${port} envsubst < /redis-conf/redis-cluster.tmpl > /redis-conf/${port}/redis.conf
    done

    supervisord -c /etc/supervisor/supervisord.conf
    sleep 3

    
    echo "yes" | ruby /redis/src/redis-trib.rb create --replicas 1 ${DOCKER_IP}:7000 ${DOCKER_IP}:7001 ${DOCKER_IP}:7002 ${DOCKER_IP}:7003 ${DOCKER_IP}:7004 ${DOCKER_IP}:7005
    tail -f /var/log/supervisor/redis*.log
else
  exec "$@"
fi
