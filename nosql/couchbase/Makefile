CID_FILE = /tmp/doker-nosql-couchbase.cid
CID =`cat $(CID_FILE)`
IMAGE_NAME = couchbase/server
CONTAINER_NAME = couchbase
PORTS = -p 8091:8091

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  build           build the docker image containing a redis cluster"
	@echo "  rebuild         rebuilds the image from scratch without using any cached layers"
	@echo "  run             run the built docker image"
	@echo "  bash            starts bash inside a running container."
	@echo "  clean           removes the tmp cid file on disk"
	@echo "  cli             run redis-cli inside the container on the server with port 7000"

pull:
	docker pull couchbase/server

build:
	@echo "Building docker image..."
	docker build -t ${IMAGE_NAME} .

rebuild:
	@echo "Rebuilding docker image..."
	docker build --no-cache=true -t ${IMAGE_NAME} .

run:
	@echo "Running docker image..."
	docker run -d $(PORTS) --name $(CONTAINER_NAME) -i -t ${IMAGE_NAME}
	sleep 3
	#xdg-open http://localhost:8091/
	start http://localhost:8091/

bash:
	#docker exec -it $(CID) /bin/bash
	docker exec -it $(CONTAINER_NAME) /bin/bash

stop:
	docker stop $(CONTAINER_NAME)
	-make clean

clean:
	# Cleanup cidfile on disk
	docker ps -a -q | xargs docker rm -f
	-rm $(CID_FILE)

cli:
	docker exec -it $(CID) /redis/src/redis-cli -p 7000
