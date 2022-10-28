import random
from cassandra.cluster import Cluster
from cassandra.policies import (TokenAwarePolicy, DCAwareRoundRobinPolicy, RetryPolicy)
from cassandra.query import (PreparedStatement, BoundStatement)

cluster = Cluster(
	contact_points=['172.17.0.3'],
	protocol_version=3
	#load_balancing_policy= TokenAwarePolicy(DCAwareRoundRobinPolicy(local_dc='datacenter1')),
   	#default_retry_policy = RetryPolicy()
)
session = cluster.connect('Test Cluster')

prepared_stmt = session.prepare ( "INSERT INTO users (id, lastname, age, city, email, firstname) VALUES (?, ?, ?, ?, ?, ?)")

var = 1
while var == 1:
	nb = random.randrange(0, 2000000000)
	bound_stmt = prepared_stmt.bind([nb, 'Jones', 35, 'Austin', 'bob@example.com', 'Bob'])
	stmt = session.execute(bound_stmt)
