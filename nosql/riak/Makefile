CID_FILE = /tmp/doker-nosql-riak.cid
CID =`cat $(CID_FILE)`
IMAGE_NAME = babaluga/riak
CONTAINER_NAME = riak
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
	docker run -d $(PORTS) --name $(CONTAINER_NAME)1 --cidfile $(CID_FILE) -i -t ${IMAGE_NAME}
	docker run -d $(PORTS) --name $(CONTAINER_NAME)2 -i -t ${IMAGE_NAME}
	docker run -d $(PORTS) --name $(CONTAINER_NAME)3 -i -t ${IMAGE_NAME}
	sleep 3
	@. ./Makefile.run

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
