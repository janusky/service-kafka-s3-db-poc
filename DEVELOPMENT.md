# service-kafka-s3-db-poc

Relevant notes and execution details in development mode.

## Run develop mode

Download project

```sh
git clone https://github.com/janusky/service-kafka-s3-db-poc.git
```

### Copy involved apps

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

# publisher-http-s3-0.0.1-20201204.132644-1.jar
# wget -O services/write_app/publisher-http-s3-0.0.1-SNAPSHOT.jar https://github-production-registry-package-file-4f11e5.s3.amazonaws.com/317548766/a333d780-361c-11eb-880e-424cc1058ebc?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20201204%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20201204T134442Z&X-Amz-Expires=300&X-Amz-Signature=da0f1db6015a43f573cbd4be6238c34b6f5bf004f911045d76897a7cef15a236&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=0&response-content-disposition=filename%3Dpublisher-http-s3-0.0.1-20201204.132644-1.jar&response-content-type=application%2Foctet-stream
curl -o services/write_app/publisher-http-s3-0.0.1-SNAPSHOT.jar https://github-production-registry-package-file-4f11e5.s3.amazonaws.com/317548766/a333d780-361c-11eb-880e-424cc1058ebc?filename%3Dpublisher-http-s3-0.0.1-20201204.132644-1.jar
```

### Start run

Run when you have downloaded the [applications involved](#Copy-involved-apps)

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
