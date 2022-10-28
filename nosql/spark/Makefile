CID_FILE = /tmp/doker-nosql-spark.cid
CID =`cat $(CID_FILE)`
IMAGE_NAME = sequenceiq/spark:1.4.0
CONTAINER_NAME = spark
PORTS = -p 8088:8088 -p 8042:8042

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
	docker build -t ${IMAGE_NAME} .

rebuild:
	@echo "Rebuilding docker image..."
	docker build --no-cache=true -t ${IMAGE_NAME} .

run:
	@echo "Running docker image..."
	docker run -it $(PORTS) --name $(CONTAINER_NAME) --cidfile $(CID_FILE) -h sandbox ${IMAGE_NAME} /bin/bash

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
