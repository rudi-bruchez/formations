#!/usr/bin/python
# coding=utf-8 

#import datetime
from couchdbkit import *

class Article(Document):
        auteur = DictProperty()
	titre = StringProperty()

db = Server().get_or_create_db("passerelles")

Article.set_db(db)

art = Article(
	auteur = {'prénom': 'Rudi',
		'nom': 'Bruchez',
		'e-mail': 'coucou'},
	titre = 'coucou'
)

art.save()
