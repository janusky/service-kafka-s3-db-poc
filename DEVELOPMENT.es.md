# service-kafka-s3-db-poc

Apuntes relevantes y detalles de ejecución en modo desarrollo.

## Run develop mode

```sh
# Run dev
docker-compose -f development.yml up -d

# Wait moment Up ok ..
ok=13;up=$(docker ps |grep Up |wc -l |sed -e 's/^[ \t]*//');[[ $up -eq $ok ]] && echo -e "\e[32mUp $up OK " || echo -e "\e[31mUp $up!=$ok"

# If bucket exists then Run Ceph config
sudo grep "Bucket" $(docker inspect --format={{.LogPath}} ceph)
[[ -n "$(docker exec ceph s3cmd ls)" ]] && bash ./s3/ceph/ceph-prometheus.sh || echo -e "\e[31mWait for Ceph to finish"

# Check Prometheus services
docker exec ceph ceph mgr services
```

## Send data

```sh
# Post to write_app
for i in {1..20}; do \
    curl -v --noproxy '*' -F transaction=$i \
    -F files=@./services/write_app/files/file-one.pdf \
    http://localhost:9000/api/v1/post; \
done
```

Grafana -> http://localhost:3000/ (default: admin/admin)

## Tips

Recommendation use memory **confluentic kafka**

* <https://docs.confluent.io/current/kafka/deployment.html#jvm>

## Ref

* <https://docs.confluent.io/current/getting-started.html>
