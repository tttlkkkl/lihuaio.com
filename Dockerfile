FROM nginx:1.17.10-alpine
COPY public /www/html
COPY nginx.conf /etc/nginx/conf.d