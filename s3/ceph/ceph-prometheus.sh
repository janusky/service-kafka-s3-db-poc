#!/bin/bash

#CEPH_ID=$(docker ps -aqf "ancestor=ceph/daemon")
CEPH_ID=$(docker ps -a | grep ceph/daemon | awk {'print $1'})

if [ "$( docker container inspect -f '{{.State.Running}}' $CEPH_ID )" == "true" ]; then
    echo -e "Configure Prometheus module.."

    # Ceph correct startup check
    i=0
    while [ $i -le 22 ]; do
        BK_FIND=$(docker exec $CEPH_ID s3cmd ls)
        if [ -n "$BK_FIND" ]; then
            break
        fi
        echo "Waiting for a bucket exist .."
        sleep 1
        #((i++))
        i=$((i+1))
    done

    if [ -n "$BK_FIND" ]; then
        until docker exec $CEPH_ID sh -c "sed -i '/\[global\]/a \
            auth_cluster_required = none\nauth_service_required = none\nauth_client_required = none\n
            ' /etc/ceph/ceph.conf" &> /dev/null
        do
            echo "Waiting for the cehp auth config.."
            sleep 1
        done

        echo -e "Container stop & start + config & restart.."
        docker stop $CEPH_ID \
        && docker start $CEPH_ID \
        && docker exec $CEPH_ID sh -c '
        ceph config set mgr mgr/prometheus/server_addr 0.0.0.0;
        ceph config set mgr mgr/prometheus/server_port 9283;
        ceph config set mgr mgr/prometheus/scrape_interval 20;
        ceph mgr module enable prometheus' \
        && docker restart $CEPH_ID
        # exit 0
    else
        echo -e "There is not bucker that inicates that Ceph started successfully"
        exit 1
    fi
else 
    echo -e "Ceph container is not running"
    exit 1
fi

# Chequeo de servicios activo
# docker exec $CEPH_ID ceph mgr services

# Otros comandos útiles para chequeos
# docker exec $CEPH_ID sh -c 'cat /etc/ceph/ceph.conf' 
# ceph mgr module ls | jq .enabled_modules
# ceph-mgr -d