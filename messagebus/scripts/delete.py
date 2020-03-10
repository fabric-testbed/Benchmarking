
from kafka import * 


def delete_kafka_topic(topics):
     print ("List of topics to be deleted " + str(topics))
     a = KafkaAdminClient(bootstrap_servers=['localhost:9092'])
     # Call delete_topics to asynchronously delete topics, a future is returned.
     # By default this operation on the broker returns immediately while
     # topics are deleted in the background. But here we give it some time (30s)
     # to propagate in the cluster before returning.
     #
     # Returns a dict of <topic,future>.
     a.delete_topics(topics, timeout_ms=30)

topics = ['fabric']
delete_kafka_topic(topics)
