# service-kafka-s3-db-poc

Apuntes relevantes y detalles de ejecución en modo desarrollo.

## Run develop mode

Descargar proyecto

```sh
git clone https://github.com/janusky/service-kafka-s3-db-poc.git
```

### Copiar aplicaciones involucradas

Producer & Consumer ([+](https://spring.io/blog/2020/08/10/case-study-build-and-run-a-streaming-application-using-an-http-source-and-a-jdbc-sink))

```sh
cd service-kafka-s3-db-poc

wget -O producers/send_app/http-source-kafka-3.0.0-SNAPSHOT.jar https://repo.spring.io/snapshot/org/springframework/cloud/stream/app/http-source-kafka/3.0.0-SNAPSHOT/http-source-kafka-3.0.0-SNAPSHOT.jar

wget -O consumers/insert_app/jdbc-sink-kafka-3.0.0-SNAPSHOT.jar wget https://repo.spring.io/snapshot/org/springframework/cloud/stream/app/jdbc-sink-kafka/3.0.0-SNAPSHOT/jdbc-sink-kafka-3.0.0-SNAPSHOT.jar
```

Service [publisher-http-s3](https://github.com/janusky/publisher-http-s3)

* <https://github.com/janusky/publisher-http-s3/packages/528509>

```sh
cd service-kafka-s3-db-poc

# Download from web: publisher-http-s3-0.0.1-20201204.132644-1.jar
curl $(curl -f -L https://github.com/janusky/publisher-http-s3/packages/528509?version=0.0.1-SNAPSHOT | grep -Eo 'href="(.*publisher-http-s3-0.*\.jar.*)"' | cut -d'"' -f2 | sed 's/\&amp;/\&/g') -o services/write_app/publisher-http-s3-0.0.1-SNAPSHOT.jar
```

### Start run

Ejecutar cuando haya descargado las [aplicaciones involucradas](#Copiar-aplicaciones-involucradas)

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
