#!/bin/bash

#CEPH_ID=$(docker ps -aqf "ancestor=ceph/daemon")
CEPH_ID=$(docker ps -a | grep ceph/daemon | awk {'print $1'})

if [ "$( docker container inspect -f '{{.State.Running}}' $CEPH_ID )" == "true" ]; then
    # Ceph correct startup check
    i=0
    to=10
    while [ $i -le $to ]; do
        RUN_FIND=$(docker logs $CEPH_ID 2>&1 | grep "/opt/ceph-container/bin/entrypoint.sh: SUCCESS")
        if [ -n "$RUN_FIND" ]; then
            break
        fi
        echo "Waiting for a Ceph entrypoint success ..$i-$to"
        sleep 3
        #((i++))
        i=$((i+1))
        if [ $i -eq $to ]; then
            read -p "Keep waiting [s|y]? " -n 1 -r
            echo    # (optional) move to a new line
            if [[ $REPLY =~ ^[YySs]$ ]]
            then
                i=0
            else
                break
            fi
        fi
    done
    if [ ! -n "$RUN_FIND" ]; then
        echo -e "\e[31mThere is not Ceph started successfully\e[0m(solve: rerun)"
        exit 1
    fi

    if [ ! -n "$(docker exec $CEPH_ID ceph mgr services | grep -e 'prometheus')" ]; then
        echo -e "Configure Prometheus module.."
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
        echo -e "The prometheus module is enabled!"
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