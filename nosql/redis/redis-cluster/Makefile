CID_FILE = /tmp/docker-nosql-redis-cluster.cid
CID =`cat $(CID_FILE)`
IMAGE_NAME = redis-cluster
CONTAINER_NAME = redis-cluster
NUMBERS = 1 2 3
#PORTS = -p 7000:7000 -p 7001:7001 -p 7002:7002 -p 7003:7003 -p 7004:7004 -p 7005:7005 -p 7006:7006 -p 7007:7007

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  build           build the docker image containing a redis cluster"
	@echo "  rebuild         rebuilds the image from scratch without using any cached layers"
	@echo "  run             run the built docker image"
	@echo "  bash            starts bash inside a running container."
	@echo "  clean           removes the tmp cid file on disk"
	@echo "  cli             run redis-cli inside the container on the server with port 7000"

build:
	@echo "Building docker image..."
	docker build -t ${IMAGE_NAME} .

rebuild:
	@echo "Rebuilding docker image..."
	docker build --no-cache=true -t ${IMAGE_NAME} .

run:
	@echo "Running docker image..."
	$(foreach nb,$(NUMBERS), rm -f $(CID_FILE)$(nb);)
	$(foreach nb,$(NUMBERS), docker run -d $(PORTS) --name $(CONTAINER_NAME)$(nb) --cidfile $(CID_FILE)$(nb) -i -t ${IMAGE_NAME};)
	$(foreach nb,$(NUMBERS), docker inspect --format '{{ .NetworkSettings.IPAddress }}' $(CONTAINER_NAME)$(nb);)

bash:
	docker exec -it redis-cluster1 /bin/bash

stop:
	docker stop redis-cluster1
	docker stop redis-cluster2
	docker stop redis-cluster3
	-make clean

clean:
	# Cleanup cidfile on disk
	$(foreach nb,$(NUMBERS), rm -f $(CID_FILE)$(nb);)
	#-rm /tmp/doker-nosql-redis-cluster.cid3
	-docker ps -a -q | xargs docker rm -f

cli:
	docker exec -it $(CID) /redis/src/redis-cli -p 7000
