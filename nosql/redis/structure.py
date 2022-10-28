import redis

#serveur = sys.argv[1]
r = redis.StrictRedis(host="127.0.0.1", port=6379, db=2)

r.hmset('contact:ajar', dict(
		prenom='Emile', 
		nom='Ajar',
		Profession='Ecrivain'
	)
)

dic = r.hgetall('contact:ajar')
print dic
