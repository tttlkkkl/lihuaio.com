run:
	rm -rf public && hugo -D && docker build -t tttlkkkl/lihuaio.com . && docker run --rm -it -p 80:80 tttlkkkl/lihuaio.com
push:
	docker build -t tttlkkkl/lihuaio.com . && docker push tttlkkkl/lihuaio.com