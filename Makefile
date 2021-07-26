build-lampeton-web-8.0:
	docker build -t ashtokalo/lampeton-web:8.0 docker/web

build-lampeton-web-7.4:
	docker build -t ashtokalo/lampeton-web:7.4 --build-arg PHP_IMAGE_VERSION=7.4 docker/web

up:
	docker-compose up

down:
	docker-compose down
