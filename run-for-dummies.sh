#!/bin/bash

function checkDocker() {
    if [ "x$(which docker)" == "x" ]; then
        echo "UNKNOWN - Missing docker binary (Solve: docs/docker.md#Instalar-docker)"
        exit 3
    fi
    
    docker info > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "UNKNOWN - Unable to talk to the docker daemon (Solve: service docker start)"
        exit 3
    fi
}

function downloadAwait() {
    echo "Download $2"
    until $(curl $2 -o $1); do
       sleep 1
    done
}

echo -e "\n\e[5mRUN FOR DUMMY\e[25m"
#echo -e "\e[93mINFO: Is required before run git clone https://github.com/janusky/service-kafka-s3-db-poc.git && cd service-kafka-s3-db-poc\e[0m"

echo -e "\e[93mCopy the apps involved if it doesn't exist\e[0m"
[ ! -f producers/send_app/http-source-kafka-3.0.0-SNAPSHOT.jar ] && downloadAwait producers/send_app/http-source-kafka-3.0.0-SNAPSHOT.jar https://repo.spring.io/snapshot/org/springframework/cloud/stream/app/http-source-kafka/3.0.0-SNAPSHOT/http-source-kafka-3.0.0-SNAPSHOT.jar
[ ! -f consumers/insert_app/jdbc-sink-kafka-3.0.0-SNAPSHOT.jar ] && downloadAwait consumers/insert_app/jdbc-sink-kafka-3.0.0-SNAPSHOT.jar https://repo.spring.io/snapshot/org/springframework/cloud/stream/app/jdbc-sink-kafka/3.0.0-SNAPSHOT/jdbc-sink-kafka-3.0.0-SNAPSHOT.jar
if [ ! -f services/write_app/publisher-http-s3-0.0.1-SNAPSHOT.jar ] 
then
    downloadAwait services/write_app/publisher-http-s3-0.0.1-SNAPSHOT.jar $(curl -f -L https://github.com/janusky/publisher-http-s3/packages/528509?version=0.0.1-SNAPSHOT | grep -Eo 'href="(.*publisher-http-s3-0.*\.jar.*)"' | cut -d'"' -f2 | sed 's/\&amp;/\&/g')
fi

echo -e "\e[93mDocker Start\e[0m"
checkDocker
# Docker Up
docker-compose up -d

chmod +x s3/ceph/ceph-prometheus.sh
# Ceph correct startup check
i=0
count=20
while [ $i -le $count ]; do
    CEPH_OK=$(docker logs ceph 2>&1 | grep "Running on http://0.0.0.0:5000/")
    if [ -n "$CEPH_OK" ]; then
        break
    fi
    echo "Waiting for ceph to be ready ..$i-$count"
    sleep 5
    #((i++))
    i=$((i+1))
done
if [ -n "$CEPH_OK" ]; then
    bash s3/ceph/ceph-prometheus.sh
else
    echo -e "\e[31mThere is not Ceph started successfully\e[0m(solve: rerun)"
fi

read -p "Check  [s|y]? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[YySs]$ ]]
then
    ok=16;up=$(docker ps |grep Up |wc -l |sed -e 's/^[ \t]*//');[[ $up -eq $ok ]] && echo -e "\e[32mDocker UP=$up OK " || echo -e "\e[31mUp $up!=$ok"

    #docker logs producer-data | grep -e 'Started HttpSourceKafkaApplication'
    [[ -n "$(docker logs producer-data | grep -e 'Started HttpSourceKafkaApplication')" ]] && echo -e "App producer-data Started" || echo -e "\e[31mVerify producer-data\e[0m" 
    #docker logs consumer-insert | grep -e 'partitions assigned'
    [[ -n "$(docker logs consumer-insert | grep -e 'partitions assigned')" ]] && echo -e "App consumer-insert Started" || echo -e "\e[31mVerify consumer-insert\e[0m" 
    #docker logs write-service | grep -e 'Started Application in'
    [[ -n "$(docker logs write-service | grep -e 'Started Application in')" ]] && echo -e "App write-service Started" || echo -e "\e[31mVerify write-service\e[0m" 
    # Service Prometheus
    [[ -n "$(docker exec ceph ceph mgr services | grep -e 'prometheus')" ]] && echo -e "CEPH service prometheus OK" || echo -e "\e[31mCEPH service prometheus not found\e[0m"
    #[[ -n sudo grep "Bucket" $(docker inspect --format={{.LogPath}} ceph) ]] && echo -e "Bk exists" || echo -e "\e[31mBucket not found"
    [[ -n "$(docker exec ceph s3cmd ls)" ]] && echo -e "CEPH bucket exists" || echo -e "\e[31mCEPH bucket not found\e[0m"
fi
