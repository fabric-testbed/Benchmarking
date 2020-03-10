#setupKafka.sh
 #!/bin/sh
 KAFKA_VERSION_PART1=2.12
 KAFKA_VERSION_PART2=2.3.0

 #Install kafka
 echo "Installing kafka"
 wget http://mirrors.gigenet.com/apache/kafka/$KAFKA_VERSION_PART2/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2.tgz /
 tar -zxvf /root/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2.tgz -C /opt

 rm -rf /root/kafka*.tgz

# cp /root/elk/config/server.properties /root/elk/config/zookeeper.properties /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/config

# LOCALIP=`/opt/aws/bin/ec2-metadata -o|cut -d' ' -f2`

# sed -i 's/172.31.17.173/'$LOCALIP'/g' /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/config/server.properties

 echo "Installation complete!"

# /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/bin/zookeeper-server-start.sh /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/config/zookeeper.properties > /var/log/zookeeper.log 2>&1 &
 sleep 5

# /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/bin/kafka-server-start.sh /opt/kafka_$KAFKA_VERSION_PART1-$KAFKA_VERSION_PART2/config/server.properties > /var/log/kafka-server.log 2>&1 &
