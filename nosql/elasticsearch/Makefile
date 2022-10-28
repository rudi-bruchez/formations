CID_FILE = /tmp/doker-nosql-elasticsearch.cid
CID =`cat $(CID_FILE)`
IMAGE_NAME = elasticsearch
CONTAINER_NAME = elasticsearch
PORTS = -p 9200:9200 -p 9300:9300

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  build           build the docker image containing a redis cluster"
	@echo "  rebuild         rebuilds the image from scratch without using any cached layers"
	@echo "  run             run the built docker image"
	@echo "  bash            starts bash inside a running container."
	@echo "  clean           removes the tmp cid file on disk"
	@echo "  cli             run redis-cli inside the container on the server with port 7000"

pull:
	docker pull ${IMAGE_NAME}

build:
	@echo "Building docker image..."
	#docker build -t ${IMAGE_NAME} github.com/dockerfile/elasticsearch
	docker build -t ${IMAGE_NAME} github.com/3scale/docker-elasticsearch

rebuild:
	@echo "Rebuilding docker image..."
	docker build --no-cache=true -t ${IMAGE_NAME} .

run:
	@echo "Running docker image..."
	docker run -d $(PORTS) --name $(CONTAINER_NAME) --cidfile $(CID_FILE) -v /media/rudi/zenon/docker/nosql/elasticsearch:/data -i -t ${IMAGE_NAME} /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml
	sleep 3
	xdg-open http://localhost:9200/

bash:
	docker exec -it $(CID) /bin/bash

stop:
	docker stop $(CID)
	-make clean

clean:
	# Cleanup cidfile on disk
	docker ps -a -q | xargs docker rm -f
	-rm $(CID_FILE)

cli:
	docker exec -it $(CID) /redis/src/redis-cli -p 7000
