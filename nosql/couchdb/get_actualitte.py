#!/usr/bin/python
# coding=utf-8 

import json
import requests
import customserializer
from feedparser import parse

url = 'http://127.0.0.1:5984/actualitte'
i = 1

from feedparser import parse
myfeed = parse("https://www.actualitte.com/flux/rss/actualites.xml")

print(myfeed.feed.title)

# on supprime la base au cas où
print(requests.delete(url))
# on la crée
print(requests.put(url))


for item in myfeed.entries:
	#print item # ok
	#print json.dumps(item, default=customserializer.to_json)
	j = json.dumps(item, default=customserializer.to_json)
	cle = "%05d" % i
	print(requests.put(url+'/'+cle, data=j))
	i += 1
