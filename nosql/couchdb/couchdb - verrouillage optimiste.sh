# si besoin
sudo apt-get install curl

# on crée la base de données
curl -X PUT http://localhost:5984/passerelles

# on y insère qqch
curl -X PUT http://localhost:5984/passerelles/1 -d '
{ 
	"auteur": 
	{ 
		"prénom":"Annie", 
		"nom":"Brizard", 
		"e-mail":"annie.brizard@cocomail.com" 
	}, 
	"titre":"pourquoi les éléphants ont-ils de grandes oreilles ?"
}'

# on le retrouve
curl -X GET http://localhost:5984/passerelles/1

# les deux clés système sont
# _id
# _rev

#
# le UUID a été généré par le serveur. C'est ok mais le risque est d'envoyer deux fois le
# même document en cas de problème à l'insertion.

# pour obtenir des UUID :
curl -X GET http://localhost:5984/_uuids 
curl -X GET http://localhost:5984/_uuids?count=10

# si on modifie, il faut indiquer la dernière révision :
curl -X PUT http://localhost:5984/passerelles/1 -d '
{
	"_rev": "1-dc5def75ffe9db45c5c3de4d21ebabb8",
	"auteur": 
	{ 
		"prénom":"Annie", 
		"nom":"Brizard", 
		"e-mail":"annie.brizard@cocomail.com" 
	}, 
	"titre":"je change mon titre, il était trop bizarre"
}'

# jouons avec les révisions
curl -X PUT http://localhost:5984/passerelles/2 -d '{}' 
curl -X PUT http://localhost:5984/passerelles/2 -d '{}' 
curl -X PUT http://localhost:5984/passerelles/2 -d '{"_rev":"1-967a00dff5e02add41819138abb3284d"}' 
curl -X PUT http://localhost:5984/passerelles/2 -d '{"_rev":"1-967a00dff5e02add41819138abb3284d"}' 

# quelles sont les révisions de notre document ?
curl -X GET http://localhost:5984/passerelles/1?revs_info=true

# seulement la liste des révisions
curl -X GET http://localhost:5984/passerelles/1?revs=true

# on requête une révision particulière
curl -X GET http://localhost:5984/passerelles/1?rev=1-dc5def75ffe9db45c5c3de4d21ebabb8

# quelles révisions ?
# toutes les révisions
curl -X GET http://localhost:5984/passerelles/1?open_revs=all
curl --globoff -X GET http://localhost:5984/passerelles/1?open_revs=["1-dc5def75ffe9db45c5c3de4d21ebabb8","2-1a97e3eb387fd93cf6e1abb2a1aed56b"]


