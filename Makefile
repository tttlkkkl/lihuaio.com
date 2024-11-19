run:
	rm -rf public && hugo --environment=production && docker build -t tttlkkkl/lihuaio.com . && docker run --rm -it -p 80:80 tttlkkkl/lihuaio.com
push:
	docker build -t tttlkkkl/lihuaio.com . && docker push tttlkkkl/lihuaio.com
d: 
	hugo server -D --environment=production
oss:
	hugo --environment=production && ossutil cp -r public oss://lihuaio/ -u