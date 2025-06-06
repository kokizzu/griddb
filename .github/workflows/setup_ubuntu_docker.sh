#!/bin/sh -xe

# Pull and run image ubuntu docker
docker pull ubuntu:${UBUNTU_VERSION}
docker run --name ${DOCKER_CONTAINER_NAME_UBUNTU} -ti -d -v `pwd`:/griddb --env GS_LOG=/griddb/log --env GS_HOME=/griddb ubuntu:${UBUNTU_VERSION}

# Install dependency, support for griddb server
docker exec ${DOCKER_CONTAINER_NAME_UBUNTU} /bin/bash -xec "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y debhelper libz-dev tcl ant default-jdk python3"

# Config server
docker exec ${DOCKER_CONTAINER_NAME_UBUNTU} /bin/bash -c "cd griddb \
&& ./bootstrap.sh \
&& ./configure \
&& make \
&& bin/gs_passwd ${GRIDDB_USERNAME} -p ${GRIDDB_PASSWORD} \
&& sed -i 's/\"clusterName\":\"\"/\"clusterName\":\"${GRIDDB_CLUSTER_NAME}\"/g' conf/gs_cluster.json"

# Start server with non-root user
docker exec -u 1001:1001 ${DOCKER_CONTAINER_NAME_UBUNTU} bash -c "cd griddb \
&& bin/gs_startnode -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w \
&& bin/gs_joincluster -c ${GRIDDB_CLUSTER_NAME} -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w "

# Run sample
docker exec ${DOCKER_CONTAINER_NAME_UBUNTU} /bin/bash -c "export CLASSPATH=${CLASSPATH}:/griddb/bin/gridstore.jar \
&& mkdir gsSample \
&& cp /griddb/docs/sample/program/Sample1.java gsSample/. \
&& javac gsSample/Sample1.java && java gsSample/Sample1 ${GRIDDB_NOTIFICATION_ADDRESS} ${GRIDDB_NOTIFICATION_PORT} ${GRIDDB_CLUSTER_NAME} ${GRIDDB_USERNAME} ${GRIDDB_PASSWORD}"

# Stop server with non-root user
docker exec -u 1001:1001 ${DOCKER_CONTAINER_NAME_UBUNTU} bash -c "cd griddb \
&& bin/gs_stopcluster -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w \
&& bin/gs_stopnode -u ${GRIDDB_USERNAME}/${GRIDDB_PASSWORD} -w"
