import random
from cassandra.cluster import Cluster

cluster = Cluster(
	contact_points=['172.17.0.40'],
	protocol_version=3
	#load_balancing_policy= TokenAwarePolicy(DCAwareRoundRobinPolicy(local_dc='datacenter1')),
   	#default_retry_policy = RetryPolicy()
)
session = cluster.connect('orsys')

r = session.execute("SELECT * FROM users;")
for x in r: print x.id, x.lastname
