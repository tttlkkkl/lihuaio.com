FROM alpine:3.12

ADD http://gosspublic.alicdn.com/ossutil/1.6.19/ossutil64 /usr/bin/
# ADD https://github.com/gohugoio/hugo/releases/download/v0.75.0/hugo_extended_0.75.0_Linux-64bit.tar.gz /usr/bin
COPY hugo /usr/bin/
COPY run.sh /usr/bin/run.sh
RUN chmod 755 /usr/bin/ossutil64 && chmod +x /usr/bin/run.sh \
&& echo 'https://mirrors.aliyun.com/alpine/v3.12/main/' > /etc/apk/repositories \
&& echo 'https://mirrors.aliyun.com/alpine/v3.12/community/' >> /etc/apk/repositories \
&& apk add --no-cache git
ENTRYPOINT [ "/usr/bin/run.sh" ]