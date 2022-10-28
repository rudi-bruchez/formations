from cassandra.cluster import Cluster
cluster = Cluster(
	contact_points=['172.17.0.3'],
	protocol_version=3
	#load_balancing_policy= TokenAwarePolicy(DCAwareRoundRobinPolicy(local_dc='datacenter1')),
   	#default_retry_policy = RetryPolicy()
)
session = cluster.connect()

session.execute("CREATE KEYSPACE orsys WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };")

