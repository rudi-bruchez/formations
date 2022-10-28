import sys
import uuid
import redis
from datetime import datetime, time

#serveur = sys.argv[1]
r = redis.StrictRedis(host="127.0.0.1", port=6379)

cle = datetime.now().strftime("%Y-%m-%dT%H:%M")
user = str(uuid.uuid4())

pipe = r.pipeline(transaction=False)
pipe.sadd(cle, user)

for i in range(20000):
	id = str(uuid.uuid4())
	if i % 100 == 0:
		pipe.sadd(user, id)
	pipe.sadd(cle, id)

pipe.execute()
