# Message Bus
Multiple messaging frameworks were explored for Fabric such as
- Peer to peer messaging
  - gRPC
  - AVRO
  - REST
- Message Broker
  - Apache Kafka
  - Apache Pulsar

The advantages of using message broker listed below led us to benchmark Apache Kafka and Apache Pulsar:

Advantages of using Message Broker:
- Powerful event streaming platform
- Fault tolerance and reliable solutions
- Good Scalability
- Potentially simplify recovery design
- Free community distributed product

## Kafka Vs Pulsar
Kafka
- Implemented in Scala and Java
- More mature and lot of community support
- Very rich and useful documentation
- Simpler to operate in production - less components - broker nodes provides storage
- Multi-tenancy is supported via grouping topics. No robust Multi-DC replication - (offered in Confluent Enterprise).
Pulsar
- Implemented in Java
- Fairly new. Small community - 8 stackoverflow questions currently
- Java client has little to no javadoc
- Higher operational complexity - Zookeeper + Broker nodes + BookKeeper - all clustered
- persistent/nonpersistent topics, multitenancy, ACLs, Multi-DC replication etc.

## Kafka Cluster
This section describes steps to bring up a Kafka cluster with 3 nodes and configure.
1. Install following packages
```
yum install -y java-1.8.0-openjdk
yum install -y java-1.8.0-openjdk-devel
yum install -y python-devel gcc python-pip
pip install psutil
pip install Kafka-python
```
2. Set up NVME Drives
```
./scripts/disk.sh
```
3. Install ZooKeeper
```
./scripts/setupZooKeeper.sh 3.4.12

```
4. Install Kafka
```
./scripts/setupKafka.sh
```
5. Set up myid for each Zookeeper (use different number for each instance)
```
echo {id} >> /zoo/data/myid
```
6. Create your own CA. Same trust store to be used for all the brokers.
```
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert
```
7. Generate SSL Key and Certificate for each broker and sign it with CA
   7.1 Broker 1
   ```
   keytool -keystore kafka.server0.keystore.jks -alias localhost -validity 365 -genkey
   keytool -keystore kafka.server0.keystore.jks -alias localhost -certreq -file cert-file
   openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:test1234
   keytool -keystore kafka.server0.keystore.jks -alias CARoot -import -file ca-cert
   keytool -keystore kafka.server0.keystore.jks -alias localhost -import -file cert-signed

   ```
   7.2 Broker 2
   ```
   rm -rf cert-file cert-signed

   keytool -keystore kafka.server1.keystore.jks -alias localhost -validity 365 -genkey
   keytool -keystore kafka.server1.keystore.jks -alias localhost -certreq -file cert-file
   openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:test1234
   keytool -keystore kafka.server1.keystore.jks -alias CARoot -import -file ca-cert
   keytool -keystore kafka.server1.keystore.jks -alias localhost -import -file cert-signed

   ```
   7.3 Broker 3
   ```
   rm -rf cert-file cert-signed

   keytool -keystore kafka.server2.keystore.jks -alias localhost -validity 365 -genkey
   keytool -keystore kafka.server2.keystore.jks -alias localhost -certreq -file cert-file
   openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:test1234
   keytool -keystore kafka.server2.keystore.jks -alias CARoot -import -file ca-cert
   keytool -keystore kafka.server2.keystore.jks -alias localhost -import -file cert-signed
   ```
8. Create ssl directory on each broker
```
mkdir -p /var/private/ssl
```
9. Copy CA trust store(kafka.server.truststore.jks) and respective key store(kafka.server{id}.keystore.jks) for the broker in /var/private/ssl directory
10. Configure following parameters in server.properties leaving everything else to default values (uncomment ssl.endpoint.identification.algorithm) to disable hostname validation.
```
broker.id=0 (each broker should have a unique number)
listeners=PLAINTEXT://:9092,SSL://:9093

security.inter.broker.protocol=SSL
ssl.client.auth=required
ssl.keystore.location=/var/private/ssl/kafka.server0.keystore.jks
ssl.keystore.password=test1234
ssl.key.password=test1234
ssl.truststore.location=/var/private/ssl/kafka.server.truststore.jks
ssl.truststore.password=test1234
ssl.endpoint.identification.algorithm=
log.dirs=/kafka/log/kafka-logs
zookeeper.connect=zoo1:2181,zoo2:2181,zoo3:2181

message.max.bytes=15728640
replica.fetch.max.bytes=15728640
fetch.message.max.bytes=15728640
#max.inflight.requests.per.connection=1
#min.insync.replicas=2
```
11. Start Zookeeper
```
/opt/zookeeper/bin/zkServer.sh start
```
12. Start Kafka
```
/opt/kafka_2.12-2.3.0/bin/kafka-server-start.sh /opt/kafka_2.12-2.3.0/config/server.properties > /var/log/kafka-server.log 2>&1 &
```
13. Create a topic
```
/opt/kafka_2.12-2.3.0/bin/kafka-topics.sh --zookeeper zoo1:2181 --create --topic fabric-cf --replication-factor 3 --partitions 2
```
14. Configure ssl properties for client in client-ssl.properties
```
security.protocol = SSL
ssl.truststore.location = "/var/private/ssl/kafka.client.truststore.jks"
ssl.truststore.password = "test1234"
```
15. Trigger the traffic
```
cd /opt/kafka_2.12-2.3.0
bin/kafka-run-class.sh org.apache.kafka.tools.ProducerPerformance --print-metrics --topic fabric-cf --num-records 1000 --throughput 10000 --record-size 1000000 --producer-props bootstrap.servers=zoo1:9092 acks=-1 buffer.memory=67108864 batch.size=64000 --producer.config client-ssl.properties
```
## Refrences
https://www.confluent.io/blog/apache-kafka-security-authorization-authentication-encryption/
https://blog.softwaremill.com/does-kafka-really-guarantee-the-order-of-messages-3ca849fd19d2
https://docs.confluent.io/2.0.0/kafka/ssl.html
https://docs.confluent.io/current/security/security_tutorial.html#generating-keys-certs
https://blog.newrelic.com/engineering/new-relic-kafkapocalypse/
https://engineering.linkedin.com/kafka/benchmarking-apache-kafka-2-million-writes-second-three-cheap-machines
https://gist.github.com/jkreps/c7ddb4041ef62a900e6c
https://gist.github.com/zodvik/b86757d45a95ed194fc9d87e507c1bcc
https://www.confluent.io/blog/build-services-backbone-events/
https://medium.com/@sunilvb/spring-boot-kafka-schema-registry-c6e32485a7c8
https://docs.confluent.io/current/clients/python.html#python-client
https://github.com/confluentinc/confluent-kafka-python
https://www.confluent.io/blog/apache-kafka-security-authorization-authentication-encryption/
https://blog.softwaremill.com/does-kafka-really-guarantee-the-order-of-messages-3ca849fd19d2

## TCP Tuning (Used only for Inter Site Cluster Tests)
```
cat << EOF >> /etc/sysctl.conf
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216

net.core.netdev_max_backlog=250000

net.core.rmem_max = 536870912
net.core.wmem_max = 536870912
net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.all.arp_filter=1
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.default.arp_filter=1
net.ipv4.tcp_congestion_control = htcp
net.ipv4.tcp_no_metrics_save = 1

net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456

net.ipv4.tcp_mtu_probing=1
net.core.netdev_budget = 600

net.core.default_qdisc = fq
EOF

sysctl -p

ip link set <IF> mtu 9000
ip link set <IF>.<VLAN_TAG> mtu 9000

ip link set <IF> txqueuelen 10000
ip link set <IF>.<VLAN_TAG> txqueuelen 10000
```
## AWS Cloud Formation
- Intra Site Cluster; same Availability Zone
- Intra Site Cluster; different Availability Zone
- Inter Site Cluster
