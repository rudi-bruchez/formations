from cassandra.cluster import Cluster
cluster = Cluster(
	contact_points=['172.17.0.40'],
	protocol_version=3
	#load_balancing_policy= TokenAwarePolicy(DCAwareRoundRobinPolicy(local_dc='datacenter1')),
   	#default_retry_policy = RetryPolicy()
)
session = cluster.connect('orsys')

session.execute("CREATE TABLE orsys.users ( id int PRIMARY KEY, lastname varchar, age int, city varchar, email varchar, firstname varchar);")

